package oizys

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/log"

	e "oizys/internal/exec"
	"oizys/internal/ui"
)

var o *Oizys

func init() {
	o = New()
}

// verbose vs debug?
type Oizys struct {
	flake         string
	host          string
	cache         string
	githubSummary string
	inCI          bool
	verbose       bool
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
	o.inCI = o.githubSummary != ""

	return o
}

func SetFlake(path string) {
	// Check path exists
	if path != "" {
		o.flake = path
	}
	// check local path exists
	if !strings.HasPrefix(o.flake, "github") && !strings.HasPrefix(o.flake, "git+") {
		if _, ok := os.LookupEnv("OIZYS_SKIP_CHECK"); !ok {
			if _, err := os.Stat(o.flake); errors.Is(err, fs.ErrNotExist) {
				log.Warnf("path to flake %s does not exist, using remote as fallback", o.flake)
				o.flake = "github:daylinmorgan/oizys"
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

func SetVerbose(v bool) {
	o.verbose = v
}

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

func git(rest ...string) *exec.Cmd {
	args := []string{"-C", o.flake}
	args = append(args, rest...)
	cmd := exec.Command("git", args...)
	e.LogCmd(cmd)
	return cmd
}

func GitPull() {
	cmdOutput, err := git("status", "--porcelain").Output()
	if err != nil {
		log.Fatal(err)
	}

	if len(cmdOutput) > 0 {
		fmt.Println("unstaged commits, cowardly exiting...")
		ui.ShowFailedOutput(cmdOutput)
		os.Exit(1)
	}

	cmdOutput, err = git("pull").CombinedOutput()
	if err != nil {
		ui.ShowFailedOutput(cmdOutput)
		log.Fatal(err)
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
func showDryRunResult(nixOutput string, verbose bool) {
	toBuild, toFetch := parseDryRun(nixOutput)
	toFetch.Show(o.debug)
	toBuild.Show(true)
}

func Dry(verbose bool, minimal bool, rest ...string) {
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
		showDryRunResult(string(result), verbose)
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
	if o.verbose {
		cmd.Args = append(cmd.Args, "--print-build-logs")
	}
	cmd.Args = append(cmd.Args, rest...)
	e.ExitWithCommand(cmd)
}

func NixBuild(nom bool, minimal bool, rest ...string) {
	var cmdName string
	if nom {
		cmdName = "nom"
	} else {
		cmdName = "nix"
	}
	cmd := exec.Command(cmdName, "build")
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

func Checks(nom bool, rest ...string) {
	checks := o.getChecks()
	for _, check := range checks {
		NixBuild(nom, false, o.checkPath(check))
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

func CI(rest ...string) {
	args := []string{"workflow", "run", "build.yml", "-F", fmt.Sprintf("hosts=%s", o.host)}
	args = append(args, rest...)
	cmd := exec.Command("gh", args...)
	e.ExitWithCommand(cmd)
}
