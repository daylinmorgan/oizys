package cmd

import (
	"fmt"
	"oizys/internal/oizys"
	"slices"
	"strings"

	"github.com/spf13/cobra"
)

var validArgs = []string{
	"switch", "boot", "test", "build", "dry-build", "dry-activate", "edit", "repl",
	"build-vm", "build-vm-with-bootloader",
	"list-generations",
}
var osCmd = &cobra.Command{
	Use:   "os [subcmd]",
	Short: "nixos-rebuild wrapper",
	Args: func(cmd *cobra.Command, args []string) error {
		if err := cobra.MinimumNArgs(1)(cmd, args); err != nil {
			return err
		}
		// Run the custom validation logic
		if slices.Contains(validArgs, args[0]) {
			return nil
		}
		return fmt.Errorf("unexpected arg: %s\nexpected one of:\n  %s", args[0], strings.Join(validArgs, ", "))
	},
	Run: func(cmd *cobra.Command, args []string) {
		subcmd := args[0]
		oizys.NixosRebuild(subcmd, args[1:]...)
	},
}

func init() {
	rootCmd.AddCommand(osCmd)
}
