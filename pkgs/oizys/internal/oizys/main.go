package oizys

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"oizys/internal/git"

	// "oizys/internal/github"
	"oizys/internal/ui"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/log"

	e "oizys/internal/exec"
)

var o *Oizys

func init() {
	o = New()
}

// verbose vs debug?
type Oizys struct {
	repo          *git.GitRepo
	flake         string
	host          string
	cache         string
	githubSummary string
	githubToken   string
	local         bool
	inCI          bool
	systemPath    bool
	resetCache    bool
	debug         bool
}

func New() *Oizys {
	o := new(Oizys)
	o.cache = "daylin"
	hostname, err := os.Hostname()
	if err != nil {
		log.Fatal("failed to determine hostname", "err", err)
	}
	o.host = hostname
	oizysDir, ok := os.LookupEnv("OIZYS_DIR")
	if !ok {
		home := os.Getenv("HOME")
		o.flake = fmt.Sprintf("%s/%s", home, "oizys")
	} else {
		o.flake = oizysDir
	}
	o.githubSummary = os.Getenv("GITHUB_STEP_SUMMARY")
	if o.githubSummary != "" {
		o.inCI = true
		log.Debug("running oizys in CI mode")
	}
	o.githubToken = os.Getenv("GITHUB_TOKEN")
	o.repo = git.NewRepo(o.flake)
	return o
}

func GithubToken() string {
	return o.githubToken
}

func SetFlake(path string) {
	// Check path exists
	if path != "" {
		o.flake = path
	}

	// check if path is local and exists
	if !strings.HasPrefix(o.flake, "github") && !strings.HasPrefix(o.flake, "git+") {
		if _, ok := os.LookupEnv("OIZYS_SKIP_CHECK"); !ok {
			if _, err := os.Stat(o.flake); errors.Is(err, fs.ErrNotExist) {
				log.Warnf("path to flake %s does not exist, using remote as fallback", o.flake)
				o.flake = "github:daylinmorgan/oizys"
			} else {
				o.local = true
			}
		}
	}
}

func SetDebug(debug bool) { o.debug = debug }

func SetCache(name string) {
	if name != "" {
		o.cache = name
	}
}

func SetHost(name string) {
	if name != "" {
		o.host = name
	}
}

func GetHost() string { return o.host }

func SetResetCache(reset bool) {
	o.resetCache = reset
}

func NixosConfigAttrs() (attrs []string) {
	for _, host := range strings.Split(o.host, " ") {
		attrs = append(attrs, o.nixosConfigAttr(host))
	}
	return attrs
}

func (o *Oizys) nixosConfigAttr(host string) string {
	return fmt.Sprintf(
		"%s#nixosConfigurations.%s.config.system.build.toplevel",
		o.flake,
		host,
	)
}

func Output() {
	if o.systemPath {
		drv := evaluateDerivations(NixosConfigAttrs()...)
		systemPaths, err := findSystemPaths(drv)
		// systemPath, err := findSystemPath(drv)
		if err != nil {
			log.Fatal("error collecting system paths", "err", err)
		}
		for _, drv := range systemPaths {
			fmt.Println(drv)
		}
	} else {
		for _, drv := range NixosConfigAttrs() {
			fmt.Println(drv)
		}
	}
}

func parseDryRun(buf string) (*ui.Packages, *ui.Packages) {
	lines := strings.Split(strings.TrimSpace(buf), "\n")
	var parts [2][]string
	i := 0
	for _, line := range lines {
		if strings.Contains(line, "fetch") && strings.HasSuffix(line, ":") {
			i++
		}
		if i == 2 {
			log.Fatal("failed to parse output", "output", buf)
		}
		if strings.HasPrefix(line, "  ") {
			parts[i] = append(parts[i], line)
		}
	}

	if len(parts[0])+len(parts[1]) == 0 {
		log.Info("no changes...")
		os.Exit(0)
	}

	return ui.ParsePackages(parts[0], "packages to build"),
		ui.ParsePackages(parts[1], "packages to fetch")
}

// TODO: Refactor this and above
func parseDryRun2(buf string) ([]string, []string) {
	lines := strings.Split(strings.TrimSpace(buf), "\n")
	var parts [2][]string
	i := 0
	for _, line := range lines {
		if strings.Contains(line, "fetch") && strings.HasSuffix(line, ":") {
			i++
		}
		if i == 2 {
			log.Fatal("failed to parse output", "output", buf)
		}
		if strings.HasPrefix(line, "  ") {
			parts[i] = append(parts[i], strings.TrimSpace(line))
		}
	}
	if len(parts[0])+len(parts[1]) == 0 {
		log.Info("no changes...")
		os.Exit(0)
	}
	return parts[0], parts[1]
}

// TODO: refactor to account for --debug and not --verbose?
func showDryRunResult(nixOutput string) {
	toBuild, toFetch := parseDryRun(nixOutput)
	toFetch.Show(o.debug)
	toBuild.Show(true)
}

func Dry(minimal bool, rest ...string) {
	cmd := exec.Command("nix", "build", "--dry-run")
	cmd.Args = append(cmd.Args, rest...)
	if o.resetCache {
		cmd.Args = append(cmd.Args, "--narinfo-cache-negative-ttl", "0")
	}
	var spinnerMsg string
	if minimal {
		drvs := systemPathDrvsToBuild()
		if len(drvs) == 0 {
			log.Info("no packages in minimal set to build")
			os.Exit(0)
		}
		cmd.Args = append(cmd.Args, append(drvs, "--no-link")...)
		spinnerMsg = "evaluting for minimal build needs"
	} else {
		log.Debug("evalutating full nixosConfiguration")
		cmd.Args = append(cmd.Args, NixosConfigAttrs()...)
		spinnerMsg = fmt.Sprintf("%s %s", "evaluating derivation for:",
			lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("6")).Render(o.host),
		)
	}
	result, err := e.CmdOutputWithSpinner(cmd, spinnerMsg, true)
	if err != nil {
		log.Fatal("failed to dry-run nix build", "err", err, "output", string(result))
	}
	if minimal {
		fmt.Println(string(result))
	} else {
		showDryRunResult(string(result))
	}
}

// Setup command completely differently here
func NixosRebuild(subcmd string, rest ...string) {
	cmd := exec.Command("sudo",
		"nixos-rebuild",
		subcmd,
		"--flake",
		o.flake,
	)
	if !o.inCI {
		cmd.Args = append(cmd.Args, "--log-format", "multiline")
	}
	if o.debug {
		cmd.Args = append(cmd.Args, "--print-build-logs")
	}
	cmd.Args = append(cmd.Args, rest...)
	e.ExitWithCommand(cmd)
}

func splitDrv(drv string) (string, string) {
	s := strings.SplitN(drv, "-", 2)
	ss := strings.Split(s[0], "/")
	hash := ss[len(ss)-1]
	drvName := strings.Replace(s[1], ".drv^*", "", 1)
	return drvName, hash
}

const tableTmpl = `# Building Derivations
| derivation | hash |
|---|---|
%s
`

func writeDervationsToStepSummary(drvs []string) {
	tableRows := make([]string, len(drvs))
	for i, drv := range drvs {
		name, hash := splitDrv(drv)
		tableRows[i] = fmt.Sprintf(
			"| %s | %s |",
			name, hash,
		)
	}
	o.writeToGithubStepSummary(fmt.Sprintf(tableTmpl, strings.Join(tableRows, "\n")))
}

func NixBuild(minimal bool, rest ...string) {
	cmd := exec.Command("nix", "build")
	if o.resetCache {
		cmd.Args = append(cmd.Args, "--narinfo-cache-negative-ttl", "0")
	}
	if minimal {
		log.Debug("populating args with derivations not already built")
		drvs := systemPathDrvsToBuild()
		if len(drvs) == 0 {
			log.Info("nothing to build. exiting...")
			os.Exit(0)
		}
		if o.inCI {
			writeDervationsToStepSummary(drvs)
		}
		cmd.Args = append(cmd.Args, append(drvs, "--no-link")...)
	}
	if !o.inCI {
		cmd.Args = append(cmd.Args, "--log-format", "multiline")
	}
	cmd.Args = append(cmd.Args, rest...)
	e.ExitWithCommand(cmd)
}

func (o *Oizys) writeToGithubStepSummary(txt string) {
	f, err := os.OpenFile(o.githubSummary, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	if _, err := f.Write([]byte(txt)); err != nil {
		log.Fatal(err)
	}
	if err := f.Close(); err != nil {
		log.Fatal(err)
	}
}

func (o *Oizys) getChecks() []string {
	attrName := fmt.Sprintf("%s#%s", o.flake, "checks.x86_64-linux")
	cmd := exec.Command("nix", "eval", attrName, "--apply", "builtins.attrNames", "--json")
	out, err := cmd.Output()
	if err != nil {
		log.Fatal(err)
	}
	var checks []string
	if err := json.Unmarshal(out, &checks); err != nil {
		log.Fatal(err)
	}
	return checks
}

func (o *Oizys) checkPath(name string) string {
	return fmt.Sprintf("%s#checks.x86_64-linux.%s", o.flake, name)
}

func Checks(rest ...string) {
	checks := o.getChecks()
	for _, check := range checks {
		NixBuild(false, o.checkPath(check))
	}
}

func CacheBuild(rest ...string) {
	args := []string{
		"watch-exec", o.cache, "--", "nix",
		"build", "--print-build-logs",
		"--accept-flake-config",
	}
	args = append(args, NixosConfigAttrs()...)
	args = append(args, rest...)
	cmd := exec.Command("cachix", args...)
	e.ExitWithCommand(cmd)
}

func UpdateRepo() {
	log.Info("rebasing HEAD on origin/flake-lock")
	o.repo.Fetch()
	o.repo.Rebase("origin/flake-lock")
}
