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
	flake string
	host  string
	cache string
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

func (o *Oizys) Update(flake string, host string, cache string) {
	if host != "" {
		o.host = host
	}
	if flake != "" {
		o.flake = flake
	}
	if cache != "" {
		o.cache = cache
	}
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

func parsePackages(buf string, desc string) *packages {
	w, _ := terminalSize()
	maxAcceptable := (w / 4) - 1
	maxLen := 0
	lines := strings.Split(strings.TrimSpace(buf), "\n")[1:]
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
	if !verbose {
		return
	}

	pkgs := p.names
	w, _ := terminalSize()
	nCols := w / p.pad
	fmt.Printf("%s\n", strings.Repeat("-", w))
	for i, pkg := range pkgs {
		fmt.Printf("%-*s", p.pad, pkg)
		if i%nCols == 0 {
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

func ParseDryRunOutput(nixOutput string, verbose bool) {
	parts := strings.Split("\n" + nixOutput, "\nthese")

	if len(parts) != 3 {
		log.Println("no changes...")
		log.Println("or I failed to parse it into the expected number of parts")
    fmt.Println(parts)
		return
	}
	toBuild := parsePackages(parts[1], "packages to build")
	toFetch := parsePackages(parts[2], "packages to fetch")

	toBuild.show(verbose)
	toFetch.show(verbose)
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
	ParseDryRunOutput(string(result), verbose)
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

func CheckFlake(flake string) {
	if _, err := os.Stat(flake); errors.Is(err, fs.ErrNotExist) {
		log.Fatalln("path to flake:", flake, "does not exist")
	}
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
