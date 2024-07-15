package cmd

import (
	"oizys/internal/oizys"

	"github.com/spf13/cobra"
)

var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "nix build",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixBuild(minimal, args...)
	},
}

func init() {
	rootCmd.AddCommand(buildCmd)
	buildCmd.Flags().BoolVar(&minimal, "minimal", false, "use system dry-run to make build args")
}
