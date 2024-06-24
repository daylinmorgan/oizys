package cmd

import (
	"github.com/spf13/cobra"
)

var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "nix build",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixBuild(nom, minimal, args...)
	},
}

var minimal bool

func init() {
	rootCmd.AddCommand(buildCmd)
	buildCmd.Flags().BoolVar(&nom, "nom", false, "display result with nom")
	// buildCmd.Flags().BoolVar(&systemPath, "system-path", false, "build system path derivation")
	buildCmd.Flags().BoolVar(&minimal, "minimal", false, "use system dry-run to make build args")
}
