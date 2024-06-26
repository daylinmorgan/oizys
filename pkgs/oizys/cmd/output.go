package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"oizys/internal/oizys"
)

var outputCmd = &cobra.Command{
	Use:   "output",
	Short: "show nixosConfiguration attr",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(oizys.Output())
	},
}

func init() {
	rootCmd.AddCommand(outputCmd)
	outputCmd.Flags().BoolVar(&systemPath, "system-path", false, "show system-path drv")
}
