package cmd

import (
	"github.com/spf13/cobra"
	"oizys/pkg/oizys"
)

var switchCmd = &cobra.Command{
	Use:   "switch",
	Short: "nixos rebuild switch",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixosRebuild("switch", flake, args...)
	},
}


func init() {
  rootCmd.AddCommand(switchCmd)
}
