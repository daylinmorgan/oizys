package cmd

import (
	"github.com/spf13/cobra"
)

var dryCmd = &cobra.Command{
	Use:   "dry",
	Short: "poor man's nix flake check",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixDryRun(verbose, args...)
	},
}

func init() {
	rootCmd.AddCommand(dryCmd)

}
