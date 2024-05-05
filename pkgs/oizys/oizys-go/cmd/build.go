package cmd

import (
	"github.com/spf13/cobra"
	"oizys/pkg/oizys"
)


var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "A brief description of your command",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixBuild(oizys.Output(flake, host), args...)
	},
}



func init() {
  rootCmd.AddCommand(buildCmd)
}
