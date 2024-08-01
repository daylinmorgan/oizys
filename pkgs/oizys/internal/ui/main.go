package ui

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/log"
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

type Packages struct {
	desc  string
	names []string
}

func ParsePackages(lines []string, desc string) *Packages {
	names := make([]string, len(lines))
	for i, pkg := range lines {
		s := strings.SplitN(pkg, "-", 2)
		if len(s) != 2 {
			log.Fatalf("failed to trim hash path from this line: %s\n ", pkg)
		}
		name := strings.Replace(s[1], ".drv", "", 1)
		names[i] = name
	}
	sort.Strings(names)
	return &Packages{names: names, desc: desc}
}

func (p *Packages) Show(verbose bool) {
	p.summary()
	if !verbose || (len(p.names) == 0) {
		return
	}

	pkgs := p.names
	for _, pkg := range pkgs {
		fmt.Printf("  %s\n", pkg)
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
