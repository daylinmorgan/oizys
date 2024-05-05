package cmd

import (

  "github.com/spf13/cobra"
  "oizys/pkg/oizys"
)

var dryCmd = &cobra.Command{
	Use:   "dry",
	Short: "poor man's nix flake check",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixDryRun(oizys.Output(flake, host))
	},
}

func init() {
  rootCmd.AddCommand(dryCmd)
}
