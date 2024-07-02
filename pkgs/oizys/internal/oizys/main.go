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

type Derivation struct {
	InputDrvs map[string]interface{}
}

func parseSystemPath(derivation map[string]Derivation) (string, error) {
	for _, nixosDrv := range derivation {
		for drv := range nixosDrv.InputDrvs {
			if strings.HasSuffix(drv, "system-path.drv") {
				return drv, nil
			}
		}
	}
	return "", errors.New("failed to find path for system-path.drv")
}

// recreating this command
// nix derivation show `oizys output` | jq -r '.[].inputDrvs | with_entries(select(.key|match("system-path";"i"))) | keys | .[]'
func getSystemPath() string {
	cmd := exec.Command("nix", "derivation", "show", o.nixosConfigAttr())
	out, err := cmdOutputWithSpinner(cmd, "running nix derivation show for full system", false)
	if err != nil {
		log.Fatal("failed to evalute nixosConfiguration for system-path.drv", "err", err)
	}

	var derivation map[string]Derivation
	if err := json.Unmarshal(out, &derivation); err != nil {
		log.Fatal(err)
	}
	systemPath, err := parseSystemPath(derivation)
	if err != nil {
		log.Fatal(err)
	}
	return systemPath
}

func (o *Oizys) nixosConfigAttr() string {
	return fmt.Sprintf(
		"%s#nixosConfigurations.%s.config.system.build.toplevel",
		o.flake,
		o.host,
	)
}

func Output() string {
	if o.systemPath {
		return getSystemPath()
	} else {
		return o.nixosConfigAttr()
	}
}

func git(rest ...string) *exec.Cmd {
	args := []string{"-C", o.flake}
	args = append(args, rest...)
	cmd := exec.Command("git", args...)
	logCmd(cmd)
	return cmd
}

func GitPull() {
	cmdOutput, err := git("status", "--porcelain").Output()
	if err != nil {
		log.Fatal(err)
	}

	if len(cmdOutput) > 0 {
		fmt.Println("unstaged commits, cowardly exiting...")
		showFailedOutput(cmdOutput)
		os.Exit(1)
	}

	cmdOutput, err = git("pull").CombinedOutput()
	if err != nil {
		showFailedOutput(cmdOutput)
		log.Fatal(err)
	}
}

func parseDryRun(buf string) (*packages, *packages) {
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

	return parsePackages(parts[0], "packages to build"),
		parsePackages(parts[1], "packages to fetch")
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
	toFetch.show(o.debug)
	toBuild.show(true)
}

func Dry(verbose bool, minimal bool, rest ...string) {
	cmd := exec.Command("nix", "build", "--dry-run")
	cmd.Args = append(cmd.Args, rest...)
	var spinnerMsg string
	if minimal {
		drvs := systemPathDrvsToBuild()
		if len(drvs) == 0 {
			log.Info("no packages in minimal set to build")
			os.Exit(0)
		}
		spinnerMsg = "evaluting for minimal build needs"
	} else {
		log.Debug("evalutating full nixosConfiguration")
		cmd.Args = append(cmd.Args, o.nixosConfigAttr())
		spinnerMsg = fmt.Sprintf("%s %s", "evaluating derivation for:",
			lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("6")).Render(o.host),
		)
	}
	result, err := cmdOutputWithSpinner(cmd, spinnerMsg, true)
	if err != nil {
		log.Fatal("failed to dry-run nix build", "err", err, "output", string(result))
	}
	if minimal {
		fmt.Println(string(result))
	} else {
		showDryRunResult(string(result), verbose)
	}
}

// / Setup command completely differently here
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
	exitWithCommand(cmd)
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
		cmd.Args = append(cmd.Args, "--narinfo-cache-positive-ttl", "0")
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
	exitWithCommand(cmd)
}

var ignoredMap = stringSliceToMap(
	[]string{
		"builder.pl",
		"profile",
		"system-path",

		"nixos-install",
		"nixos-version",
		"nixos-manual-html",
		"nixos-configuration-reference-manpage",
		"nixos-rebuild",
		"nixos-help",
		"nixos-generate-config",
		"nixos-enter",
		"nixos-container",
		"nixos-build-vms",
		"ld-library-path",

		"nixos-wsl-version",
		"nixos-wsl-welcome-message",
		"nixos-wsl-welcome",

		// trivial packages
		"restic-gdrive",
		"gitea",
		"lock",
	},
)

func drvNotIgnored(drv string) bool {
	s := strings.SplitN(strings.Replace(drv, ".drv", "", 1), "-", 2)
	_, ok := ignoredMap[s[len(s)-1]]
	return !ok
}

func stringSliceToMap(slice []string) map[string]struct{} {
	hashMap := make(map[string]struct{}, len(slice))
	for _, s := range slice {
		hashMap[s] = struct{}{}
	}
	return hashMap
}

func drvsToInputs(derivation map[string]Derivation) []string {
	var drvs []string
	for _, drv := range derivation {
		for name := range drv.InputDrvs {
			drvs = append(drvs, name)
		}
	}
	return drvs
}

// compute the overlap between two slices of strings
func overlapStrings(a []string, b []string) []string {
	var overlap []string
	set := stringSliceToMap(a)
	for _, s := range b {
		_, ok := set[s]
		if ok {
			overlap = append(overlap, s)
		}
	}
	return overlap
}

func nixDerivationShowToInputs(output []byte) []string {
	var derivation map[string]Derivation
	if err := json.Unmarshal(output, &derivation); err != nil {
		log.Fatal(err)
	}
	return drvsToInputs(derivation)
}

func filter[T any](ss []T, test func(T) bool) (ret []T) {
	for _, s := range ss {
		if test(s) {
			ret = append(ret, s)
		}
	}
	return
}

func toBuildNixosConfiguration() []string {
	systemCmd := exec.Command("nix", "build", o.nixosConfigAttr(), "--dry-run")
	result, err := cmdOutputWithSpinner(
		systemCmd,
		fmt.Sprintf("running dry build for: %s", o.nixosConfigAttr()),
		true,
	)
	if err != nil {
		log.Fatal("failed to dry-run build system", "err", err)
	}
	toBuild, _ := parseDryRun2(string(result))
	return toBuild
}

func systemPathDerivationShow() []string {
	systemPathDrv := fmt.Sprintf("%s^*", getSystemPath())
	derivationCmd := exec.Command("nix", "derivation", "show", systemPathDrv)
	output, err := cmdOutputWithSpinner(
		derivationCmd,
		fmt.Sprintf("evaluating system path: %s", systemPathDrv),
		false)
	if err != nil {
		log.Fatal("failed to evaluate", "drv", systemPathDrv)
	}
	return nixDerivationShowToInputs(output)
}

func systemPathDrvsToBuild() []string {
	toBuild := toBuildNixosConfiguration()
	systemPathInputDrvs := systemPathDerivationShow()

	toActuallyBuild := filter(
		overlapStrings(systemPathInputDrvs, toBuild),
		drvNotIgnored,
	)

	drvs := make([]string, len(toActuallyBuild))
	for i, pkg := range toActuallyBuild {
		drvs[i] = fmt.Sprintf("%s^*", strings.TrimSpace(pkg))
	}
	return drvs
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

func (o *Oizys) ciPreBuild(cmd *exec.Cmd) {
	// TODO: is this exec.Command call necessary?
	ciCmd := exec.Command(cmd.Args[0], cmd.Args[1:]...)
	ciCmd.Args = append(ciCmd.Args, "--dry-run")
	logCmd(ciCmd)
	output, err := ciCmd.CombinedOutput()
	if err != nil {
		showFailedOutput(output)
		log.Fatal(err)
	}
	toBuild, _ := parseDryRun(string(output))
	o.writeToGithubStepSummary(
		fmt.Sprintf("# %s\n\n%s", o.host, strings.Join(toBuild.names, "\n")),
	)
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
		"build", o.nixosConfigAttr(), "--print-build-logs",
		"--accept-flake-config",
	}
	args = append(args, rest...)
	cmd := exec.Command("cachix", args...)
	exitWithCommand(cmd)
}

func CheckFlake() {
}

func CI(rest ...string) {
	args := []string{"workflow", "run", "build.yml", "-F", fmt.Sprintf("hosts=%s", o.host)}
	args = append(args, rest...)
	cmd := exec.Command("gh", args...)
	exitWithCommand(cmd)
}

// // TODO: deprecate
// func nixSpinner(host string) *spinner.Spinner {
// 	msg := fmt.Sprintf("%s %s", " evaluating derivation for:",
// 		lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("6")).Render(host),
// 	)
// 	return startSpinner(msg)
// }
