package cmd

import (
	"fmt"
	"oizys/internal/github"
	"oizys/internal/oizys"
	"oizys/internal/ui"
	"os"

	"github.com/charmbracelet/log"
	"github.com/spf13/cobra"
)

var updateCmd = &cobra.Command{
	Use:   "update",
	Short: "update and run nixos rebuild",
	Run: func(cmd *cobra.Command, args []string) {
		run := github.GetLastUpdateRun()
		md, err := github.GetUpateSummary(run.GetID(), oizys.GetHost())
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(md)
		if preview {
			os.Exit(0)
		}
		if !yes && !ui.Confirm("proceed with system update?") {
			os.Exit(0)
		}
		oizys.UpdateRepo()
		oizys.NixosRebuild("switch")
	},
}

var (
	preview bool
	yes     bool
)

func init() {
	rootCmd.AddCommand(updateCmd)
	updateCmd.Flags().BoolVar(&preview, "preview", false, "confirm nix store diff")
	updateCmd.Flags().BoolVar(&yes, "yes", false, "reply yes to all confirm prompts")
}
