package cmd

import (
	"github.com/spf13/cobra"
	"oizys/pkg/oizys"
)

var cacheCmd = &cobra.Command{
	Use:   "cache",
	Short: "build and push to cachix",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.CacheBuild(oizys.Output(flake, host), cacheName, args...)
	},
}

func init() {
	cacheCmd.Flags().StringVarP(
		&cacheName,
    "cache",
    "c",
    "daylin", 
    "name of cachix binary cache",
	)
	rootCmd.AddCommand(cacheCmd)
}
