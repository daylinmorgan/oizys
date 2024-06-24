package oizys

import (
	"fmt"
	"os"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/log"
	"golang.org/x/term"
)

// TODO: seperate parsing and displaying of packages
func terminalSize() (int, int) {
	fd := os.Stdout.Fd()
	if !term.IsTerminal(int(fd)) {
		log.Error("failed to get terminal size")
		return 80, 0
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
