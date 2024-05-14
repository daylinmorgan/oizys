package cmd

import (
	"github.com/spf13/cobra"
)

var bootCmd = &cobra.Command{
	Use:   "boot",
	Short: "nixos rebuild boot",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixosRebuild("boot", args...)
	},
}

func init() {
	rootCmd.AddCommand(bootCmd)
}
