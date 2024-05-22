package oizys

import (
	"errors"
	"fmt"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"strings"

	"github.com/muesli/termenv"
	"golang.org/x/term"

	"time"

	"github.com/briandowns/spinner"
)

type Oizys struct {
	flake   string
	host    string
	cache   string
	verbose bool
}

var output = termenv.NewOutput(os.Stdout)

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

func (o *Oizys) Output() string {
	return fmt.Sprintf(
		"%s#nixosConfigurations.%s.config.system.build.toplevel",
		o.flake,
		o.host,
	)
}

func (o *Oizys) Update(
	flake, host, cache string,
	verbose bool,
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
	names []string
	pad   int
	desc  string
}

func parsePackages(lines []string, desc string) *packages {
	w, _ := terminalSize()
	maxAcceptable := (w / 4) - 1
	maxLen := 0
	names := make([]string, len(lines))
	for i, pkg := range lines {
		s := strings.SplitN(pkg, "-", 2)
		if len(s) != 2 {
			log.Fatalln("failed to trim hash path from this line: ", pkg)
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
		output.String(fmt.Sprint(len(p.names))).Bold().Foreground(output.Color("6")),
	)
}

func (o *Oizys) git(rest ...string) *exec.Cmd {
	args := []string{"-C", o.flake}
	args = append(args, rest...)
	if o.verbose {
		fmt.Println("CMD:", "git", strings.Join(args, " "))
	}
	return exec.Command("git", args...)
}

func showFailedOutput(buf []byte) {
	arrow := output.String("->").Bold().Foreground(output.Color("9"))
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

	if cmdOutput, err := o.git("pull").CombinedOutput(); err != nil {
		showFailedOutput(cmdOutput)
		log.Fatal(err)
	}
}

func parseDryRun(buf string) (*packages, *packages) {
	lines := strings.Split(strings.TrimSpace(buf), "\n")
	var parts [2][]string
	i := 0
	for _, line := range lines {
		if strings.Contains(line, "fetch") {
			i++
		}
		if strings.HasPrefix(line, "  ") {
			parts[i] = append(parts[i], line)
		}
	}

	if len(parts[0])+len(parts[1]) == 0 {
		log.Println("no changes...")
		log.Println("or I failed to parse it into the expected number of parts")
		log.Fatalln("failed to parse nix build --dry-run output")
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
		"build", o.Output(), "--dry-run",
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

func (o *Oizys) NixosRebuild(subcmd string, rest ...string) {
	args := []string{
		"nixos-rebuild",
		subcmd,
		"--flake",
		o.flake,
	}
	args = append(args, rest...)
	cmd := exec.Command("sudo", args...)
	runCommand(cmd)
}

func runCommand(cmd *exec.Cmd) {
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatal(err)
	}
}

func (o *Oizys) NixBuild(rest ...string) {
	args := []string{"build", o.Output()}
	args = append(args, rest...)
	cmd := exec.Command("nix", args...)
	runCommand(cmd)
}

func (o *Oizys) CacheBuild(rest ...string) {
	args := []string{
		"watch-exec", o.cache, "--", "nix",
		"build", o.Output(), "--print-build-logs",
		"--accept-flake-config",
	}
	args = append(args, rest...)
	cmd := exec.Command("cachix", args...)
	runCommand(cmd)
}

func (o *Oizys) CheckFlake() {
	if _, err := os.Stat(o.flake); errors.Is(err, fs.ErrNotExist) {
		log.Fatalln("path to flake:", o.flake, "does not exist")
	}
}

func Output(flake string, host string) string {
	return fmt.Sprintf(
		"%s#nixosConfigurations.%s.config.system.build.toplevel",
		flake,
		host,
	)
}

func nixSpinner(host string) *spinner.Spinner {
	msg := fmt.Sprintf("%s %s", " evaluating derivation for:",
		output.String(host).Bold().Foreground(output.Color("6")),
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
