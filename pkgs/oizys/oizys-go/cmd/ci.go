package cmd

import (
	"github.com/spf13/cobra"
)
// gh workflow run build.yml -F lockFile=@flake.lock

var ciCmd= &cobra.Command{
	Use:   "ci",
	Short: "offload build to GHA",
	Run: func(cmd *cobra.Command, args []string) {
    oizys.CI(args...)
	},
}


func init() {
	rootCmd.AddCommand(ciCmd)
	
}
