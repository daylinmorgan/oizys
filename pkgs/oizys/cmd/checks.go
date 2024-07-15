package cmd

import (
	"oizys/internal/oizys"

	"github.com/spf13/cobra"
)

var checksCmd = &cobra.Command{
	Use:   "checks",
	Short: "nix build checks",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.Checks(args...)
	},
}

func init() {
	rootCmd.AddCommand(checksCmd)
}
