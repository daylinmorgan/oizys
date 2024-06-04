package cmd

import (
	"github.com/spf13/cobra"
)

var updateCmd = &cobra.Command{
	Use:   "update",
	Short: "update and run nixos rebuild",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.GitPull()
		oizys.NixosRebuild("switch", args...)
	},
}

var boot bool

func init() {
	rootCmd.AddCommand(updateCmd)
	updateCmd.Flags().BoolVarP(&boot, "boot", "b", false, "run nixos-rebuild boot")
}
