package cmd

import (
	"oizys/internal/oizys"

	"github.com/spf13/cobra"
)

var dryCmd = &cobra.Command{
	Use:   "dry",
	Short: "poor man's nix flake check",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.Dry( minimal, args...)
	},
}

func init() {
	rootCmd.AddCommand(dryCmd)
	dryCmd.Flags().BoolVarP(&minimal, "minimal", "m", false, "use system dry-run to make build args")
}
