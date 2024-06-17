package cmd

import (
	"github.com/spf13/cobra"
)

var checksCmd = &cobra.Command{
	Use:   "checks",
	Short: "nix build checks",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.Checks(nom, args...)
	},
}

func init() {
	rootCmd.AddCommand(checksCmd)
	checksCmd.Flags().BoolVar(&nom, "nom", false, "display result with nom")
}
