package oizys

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/charmbracelet/log"
	"oizys/internal/ui"
)

type GitRepo struct {
	path string
}

func (g *GitRepo) git(rest ...string) *exec.Cmd {
	args := []string{"-C", g.path}
	args = append(args, rest...)
	cmd := exec.Command("git", args...)
	// logCmd(cmd)
	return cmd
}

func GitPull(workDir string) {
	g := GitRepo{workDir}
	cmdOutput, err := g.git("status", "--porcelain").Output()
	if err != nil {
		log.Fatal(err)
	}

	if len(cmdOutput) > 0 {
		fmt.Println("unstaged commits, cowardly exiting...")
		ui.ShowFailedOutput(cmdOutput)
		os.Exit(1)
	}

	cmdOutput, err = g.git("pull").CombinedOutput()
	if err != nil {
		ui.ShowFailedOutput(cmdOutput)
		log.Fatal(err)
	}
}
