package ui

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/log"
	"golang.org/x/term"
)

func ShowFailedOutput(buf []byte) {
	arrow := lipgloss.
		NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("9")).
		Render("->")
	for _, line := range strings.Split(strings.TrimSpace(string(buf)), "\n") {
		fmt.Println(arrow, line)
	}
}

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

type Packages struct {
	desc  string
	names []string
	pad   int
}

func ParsePackages(lines []string, desc string) *Packages {
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
	sort.Strings(names)
	return &Packages{names: names, pad: maxLen + 1, desc: desc}
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

func (p *Packages) Show(verbose bool) {
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

func (p *Packages) summary() {
	fmt.Printf("%s: %s\n",
		p.desc,
		lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("6")).
			Render(fmt.Sprint(len(p.names))),
	)
}

// Confirm asks the user for confirmation.
// valid inputs are: y/yes,n/no case insensitive.
func Confirm(s string) bool {
	reader := bufio.NewReader(os.Stdin)

	for {
		fmt.Printf("%s [y/n]: ", s)

		response, err := reader.ReadString('\n')
		if err != nil {
			log.Fatal(err)
		}

		response = strings.ToLower(strings.TrimSpace(response))
		switch response {
		case "y", "yes":
			return true
		case "n", "no":
			return false
		}
	}
}
