package cmd

import (
	"github.com/spf13/cobra"
)

var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "nix build",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixBuild(nom, args...)
	},
}

func init() {
	rootCmd.AddCommand(buildCmd)
	buildCmd.Flags().BoolVar(&nom, "nom", false, "display result with nom")
}
