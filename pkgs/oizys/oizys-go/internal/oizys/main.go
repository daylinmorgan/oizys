package oizys

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/charmbracelet/lipgloss"
	"golang.org/x/term"

	"github.com/briandowns/spinner"
	"github.com/charmbracelet/log"
)

// verbose vs debug?
type Oizys struct {
	flake      string
	host       string
	cache      string
	verbose    bool
	systemPath bool
}

func NewOizys() *Oizys {
	hostname, err := os.Hostname()
	if err != nil {
		log.Fatal(err)
	}
	flake := ""
	oizysDir, ok := os.LookupEnv("OIZYS_DIR")
	if !ok {
		home := os.Getenv("HOME")
		flake = fmt.Sprintf("%s/%s", home, "oizys")
	} else {
		flake = oizysDir
	}

	return &Oizys{flake: flake, host: hostname, cache: "daylin"}
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
func (o *Oizys) getSystemPath() string {
	cmd := exec.Command("nix", "derivation", "show", o.nixosConfigAttr())
	logCmd(cmd)
	// TODO: add spinner?
	// cmd.Stderr = os.Stderr
	s := nixSpinner(o.host)
	// result, err := cmd.CombinedOutput()
	out, err := cmd.Output()
	s.Stop()
	if err != nil {
		log.Fatal(err)
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

func (o *Oizys) Output() string {
	if o.systemPath {
		return o.getSystemPath()
	} else {
		return o.nixosConfigAttr()
	}
}

func (o *Oizys) Set(
	flake, host, cache string,
	verbose, systemPath bool,
) {
	if host != "" {
		o.host = host
	}
	if flake != "" {
		o.flake = flake
	}
	if cache != "" {
		o.cache = cache
	}
	o.verbose = verbose
	o.systemPath = systemPath
}

func terminalSize() (int, int) {
	fd := os.Stdout.Fd()
	if !term.IsTerminal(int(fd)) {
		log.Fatal("failed to get terminal size")
	}
	w, h, err := term.GetSize(int(fd))
	if err != nil {
		log.Fatal(err)
	}
	return w, h
}

type packages struct {
	desc  string
	names []string
	pad   int
}

func parsePackages(lines []string, desc string) *packages {
	w, _ := terminalSize()
	maxAcceptable := (w / 4) - 1
	maxLen := 0
	names := make([]string, len(lines))
	for i, pkg := range lines {
		s := strings.SplitN(pkg, "-", 2)
		if len(s) != 2 {
			log.Fatalf("failed to trim hash path from this line: %s\n ", pkg)
		}
		name := ellipsis(strings.Replace(s[1], ".drv", "", 1), maxAcceptable)
		if nameLen := len(name); nameLen > maxLen {
			maxLen = nameLen
		}
		names[i] = name
	}
	return &packages{names: names, pad: maxLen + 1, desc: desc}
}

func ellipsis(s string, maxLen int) string {
	runes := []rune(s)
	if len(runes) <= maxLen {
		return s
	}
	if maxLen < 3 {
		maxLen = 3
	}
	return string(runes[0:maxLen-3]) + "..."
}

func (p *packages) show(verbose bool) {
	p.summary()
	if !verbose || (len(p.names) == 0) {
		return
	}

	pkgs := p.names
	w, _ := terminalSize()
	nCols := w / p.pad
	fmt.Printf("%s\n", strings.Repeat("-", w))
	for i, pkg := range pkgs {
		fmt.Printf("%-*s", p.pad, pkg)
		if (i+1)%nCols == 0 {
			fmt.Println()
		}
	}
	fmt.Println()
}

func (p *packages) summary() {
	fmt.Printf("%s: %s\n",
		p.desc,
		lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("6")).
			Render(fmt.Sprint(len(p.names))),
	)
}

func logCmd(cmd *exec.Cmd) {
	log.Debugf("CMD: %s", strings.Join(cmd.Args, " "))
}

func (o *Oizys) git(rest ...string) *exec.Cmd {
	args := []string{"-C", o.flake}
	args = append(args, rest...)
	cmd := exec.Command("git", args...)
	logCmd(cmd)
	return cmd
}

func showFailedOutput(buf []byte) {
	arrow := lipgloss.
		NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("9")).
		Render("->")
	for _, line := range strings.Split(strings.TrimSpace(string(buf)), "\n") {
		fmt.Println(arrow, line)
	}
}

func (o *Oizys) GitPull() {
	cmdOutput, err := o.git("status", "--porcelain").Output()
	if err != nil {
		log.Fatal(err)
	}

	if len(cmdOutput) > 0 {
		fmt.Println("unstaged commits, cowardly exiting...")
		showFailedOutput(cmdOutput)
		os.Exit(1)
	}

	cmdOutput, err = o.git("pull").CombinedOutput()
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

func showDryRunResult(nixOutput string, verbose bool) {
	toBuild, toFetch := parseDryRun(nixOutput)
	toBuild.show(verbose)
	toFetch.show(verbose)
}

func (o *Oizys) NixDryRun(verbose bool, rest ...string) {
	args := []string{
		"build", o.nixosConfigAttr(), "--dry-run",
	}
	args = append(args, rest...)
	cmd := exec.Command("nix", args...)
	s := nixSpinner(o.host)
	result, err := cmd.CombinedOutput()
	s.Stop()
	if err != nil {
		fmt.Println(string(result))
		log.Fatal(err)
	}
	showDryRunResult(string(result), verbose)
}

// / Setup command completely differently here
func (o *Oizys) NixosRebuild(subcmd string, rest ...string) {
	cmd := exec.Command("sudo",
		"nixos-rebuild",
		subcmd,
		"--flake",
		o.flake,
	)
	cmd.Args = append(cmd.Args, rest...)
	if o.verbose {
		cmd.Args = append(cmd.Args, "--print-build-logs")
	}
	runCommand(cmd)
}

func runCommand(cmd *exec.Cmd) {
	logCmd(cmd)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatal(err)
	}
}

func (o *Oizys) NixBuild(nom bool, rest ...string) {
	var cmdName string
	if nom {
		cmdName = "nom"
	} else {
		cmdName = "nix"
	}
	cmd := exec.Command(cmdName, "build")
	if o.systemPath {
		cmd.Args = append(cmd.Args, fmt.Sprintf("%s^*", o.getSystemPath()))
	}
	cmd.Args = append(cmd.Args, rest...)
	runCommand(cmd)
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

func (o *Oizys) Checks(nom bool, rest ...string) {
	checks := o.getChecks()
	for _, check := range checks {
		o.NixBuild(nom, o.checkPath(check))
	}
}

func (o *Oizys) CacheBuild(rest ...string) {
	args := []string{
		"watch-exec", o.cache, "--", "nix",
		"build", o.nixosConfigAttr(), "--print-build-logs",
		"--accept-flake-config",
	}
	args = append(args, rest...)
	cmd := exec.Command("cachix", args...)
	runCommand(cmd)
}

func (o *Oizys) CheckFlake() {
	if _, ok := os.LookupEnv("OIZYS_SKIP_CHECK"); !ok {
		if _, err := os.Stat(o.flake); errors.Is(err, fs.ErrNotExist) {
			log.Fatalf("path to flake: %s does not exist", o.flake)
		}
	}
}

func (o *Oizys) CI(rest ...string) {
	args := []string{"workflow", "run", "build.yml", "-F", fmt.Sprintf("hosts=%s", o.host)}
	args = append(args, rest...)
	cmd := exec.Command("gh", args...)
	runCommand(cmd)
}

func nixSpinner(host string) *spinner.Spinner {
	msg := fmt.Sprintf("%s %s", " evaluating derivation for:",
		lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("6")).Render(host),
	)
	s := spinner.New(
		spinner.CharSets[14],
		100*time.Millisecond,
		spinner.WithSuffix(msg),
		spinner.WithColor("fgHiMagenta"),
	)
	s.Start()
	return s
}
