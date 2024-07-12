package oizys

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/briandowns/spinner"
	"github.com/charmbracelet/log"
)

func LogCmd(cmd *exec.Cmd) {
	log.Debugf("CMD: %s", strings.Join(cmd.Args, " "))
}

func CmdOutputWithSpinner(cmd *exec.Cmd, msg string, stderr bool) (output []byte, err error) {
	LogCmd(cmd)
	s := startSpinner(msg)
	if stderr {
		output, err = cmd.CombinedOutput()
	} else {
		output, err = cmd.Output()
	}
	s.Stop()
	return
}

func startSpinner(msg string) *spinner.Spinner {
	s := spinner.New(
		spinner.CharSets[14],
		100*time.Millisecond,
		spinner.WithSuffix(fmt.Sprintf(" %s", msg)),
		spinner.WithColor("fgHiMagenta"),
	)
	s.Start()
	return s
}

func ExitWithCommand(cmd *exec.Cmd) {
	LogCmd(cmd)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatal("final command failed", "err", err)
	}
}
