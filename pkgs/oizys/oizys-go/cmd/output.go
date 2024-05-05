package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"oizys/pkg/oizys"
)


var outputCmd = &cobra.Command{
	Use:   "output",
	Short: "show nixosConfiguration attr",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(oizys.Output(flake, host))
	},
}

func init() {
  rootCmd.AddCommand(outputCmd)
}
