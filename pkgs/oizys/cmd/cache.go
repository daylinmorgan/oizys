package cmd

import (
	"oizys/internal/oizys"

	"github.com/spf13/cobra"
)

var cacheCmd = &cobra.Command{
	Use:   "cache",
	Short: "build and push to cachix",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.SetCache(cacheName)
		oizys.CacheBuild(args...)
	},
}

var cacheName string

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
