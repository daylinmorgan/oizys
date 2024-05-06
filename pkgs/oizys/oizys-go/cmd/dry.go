package cmd

import (
	"oizys/pkg/oizys"

	"github.com/spf13/cobra"
)

var dryCmd = &cobra.Command{
	Use:   "dry",
	Short: "poor man's nix flake check",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.CheckFlake(flake)
		oizys.NixDryRun(flake, host)
	},
}

func init() {
	rootCmd.AddCommand(dryCmd)
}
