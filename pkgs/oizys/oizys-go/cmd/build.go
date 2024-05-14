package cmd

import (
	"github.com/spf13/cobra"
)

var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "A brief description of your command",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixBuild(args...)
	},
}

func init() {
	rootCmd.AddCommand(buildCmd)
}
