package git

import (
	"fmt"
	"oizys/internal/ui"
	"os"
	"os/exec"

	"github.com/charmbracelet/log"
)

type GitRepo struct {
	path string
}

func NewRepo(path string) *GitRepo {
	repo := new(GitRepo)
	repo.path = path
	return repo
}

func (g *GitRepo) git(rest ...string) *exec.Cmd {
	args := []string{"-C", g.path}
	args = append(args, rest...)
	cmd := exec.Command("git", args...)
	// logCmd(cmd)
	return cmd
}

func (g *GitRepo) Fetch() {
	err := g.git("fetch").Run()
	if err != nil {
		log.Fatal(err)
	}
}

func (g *GitRepo) Rebase(ref string) {
	g.Status()
	err := g.git("rebase", ref).Run()
	if err != nil {
		log.Fatal(err)
	}
}

func (g *GitRepo) Status() {
	cmdOutput, err := g.git("status", "--porcelain").Output()
	if err != nil {
		log.Fatal(err)
	}

	if len(cmdOutput) > 0 {
		fmt.Println("unstaged commits, cowardly exiting...")
		ui.ShowFailedOutput(cmdOutput)
		os.Exit(1)
	}
}

func (g *GitRepo) Pull() {
	g.Status()
	cmdOutput, err := g.git("pull").CombinedOutput()
	if err != nil {
		ui.ShowFailedOutput(cmdOutput)
		log.Fatal(err)
	}
}
