package oizys

import (
	"errors"
	"fmt"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/table"
	"github.com/muesli/termenv"
	"golang.org/x/term"

	"github.com/briandowns/spinner"
	"time"
)

func TerminalSize() (int, int) {
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

func ParseDryRunOutput(nixOutput string) {
	output := termenv.NewOutput(os.Stdout)
	parts := strings.Split(nixOutput, "\nthese")
	if len(parts) != 3 {
		log.Println("no changes...")
		return
	}
	built := strings.Split(strings.TrimSpace(parts[1]), "\n")[1:]
	fetched := strings.Split(strings.TrimSpace(parts[2]), "\n")[1:]

	fmt.Println("Packages to build:",
		output.String(fmt.Sprint(len(built))).Bold().Foreground(output.Color("6")),
	)
	var rows []table.Row
	for _, pkg := range built {
		s := strings.SplitN(pkg, "-", 2)
		hash, name := strings.Replace(s[0], "/nix/store/", "", 1), s[1]
		rows = append(rows, table.Row{hash, name})
	}

	fmt.Println("Packages to fetch:",
		output.String(fmt.Sprint(len(fetched))).Bold().Foreground(output.Color("6")),
	)
	for _, pkg := range fetched {
		s := strings.SplitN(pkg, "-", 2)
		hash, name := strings.Replace(s[0], "/nix/store/", "", 1), s[1]
		rows = append(rows, table.Row{hash, name})
	}

	w, _ := TerminalSize()
	columns := []table.Column{
		{Title: "hash", Width: 34},
		{Title: "pkg", Width: int(w / 4)},
	}
	ShowTable(columns, rows)
}

func NixDryRun(path string) {
	cmd := exec.Command("nix", "build", path, "--dry-run")
	s := spinner.New(
		spinner.CharSets[14],
		100*time.Millisecond,
		spinner.WithSuffix(" evaluating derivation for: "+path),
		spinner.WithColor("fgHiMagenta"))
	s.Start()
	output, err := cmd.CombinedOutput()
	s.Stop()
	if err != nil {
		log.Fatal(err)
	}
	ParseDryRunOutput(string(output))
}

func NixosRebuild(subcmd string, flake string, rest ...string) {
	args := []string{
		"nixos-rebuild",
		subcmd,
		"--flake",
		flake,
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

func NixBuild(path string, rest ...string) {
	args := []string{"build", path}
	args = append(args, rest...)
	cmd := exec.Command("nix", args...)
	runCommand(cmd)
}

func CacheBuild(path string, cache string, rest ...string) {
	args := []string{
		"watch-exec", cache, "--", "nix",
		"build", path, "--print-build-logs",
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

func Output(flake string, host string) string {
	return fmt.Sprintf(
		"%s#nixosConfigurations.%s.config.system.build.toplevel",
		flake,
		host,
	)
}
