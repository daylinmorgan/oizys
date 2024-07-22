package cmd

import (
	"oizys/internal/github"
	"os"

	"github.com/charmbracelet/log"
	"github.com/spf13/cobra"
)

// gh workflow run build.yml -F lockFile=@flake.lock

var ciCmd = &cobra.Command{
	Use:   "ci",
	Short: "offload build to GHA",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		inputs := make(map[string]interface{})
		if includeLock {
			log.Debug("including lock file in inputs")
			inputs["lockFile"] = readLockFile()
		}
		github.CreateDispatch(args[0], ref, inputs)
	},
}

var includeLock bool
var ref string

func init() {
	rootCmd.AddCommand(ciCmd)
	ciCmd.Flags().BoolVar(&includeLock, "lockfile", false, "include lock file in inputs")
	ciCmd.Flags().StringVar(&ref, "ref", "main", "git ref to trigger workflow on")
}

func readLockFile() string {
	dat, err := os.ReadFile("flake.lock")
	if err != nil {
		log.Fatal("failed to read flake.lock", "err", err)
	}
	return string(dat)
}
