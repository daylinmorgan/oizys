package cmd

import (
	"oizys/internal/oizys"

	"github.com/spf13/cobra"
)

var switchCmd = &cobra.Command{
	Use:   "switch",
	Short: "nixos rebuild switch",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixosRebuild("switch", args...)
	},
}

func init() {
	rootCmd.AddCommand(switchCmd)
}
