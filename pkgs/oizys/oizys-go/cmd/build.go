package cmd

import (
	"github.com/spf13/cobra"
)

var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "nix build",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixBuild(args...)
	},
}

func init() {
	rootCmd.AddCommand(buildCmd)
}
