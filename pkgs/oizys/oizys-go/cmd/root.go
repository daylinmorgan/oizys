package cmd

import (
	"os"

	cc "github.com/ivanpirog/coloredcobra"
	"github.com/spf13/cobra"
	o "oizys/pkg"
)

func Execute() {
	cc.Init(&cc.Config{
		RootCmd:         rootCmd,
		Headings:        cc.HiMagenta + cc.Bold,
		Commands:        cc.Bold,
		Example:         cc.Italic,
		ExecName:        cc.Bold,
		Flags:           cc.Bold,
		NoExtraNewlines: true,
		NoBottomNewline: true,
	})
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

var (
	flake     string
	host      string
	cacheName string
	verbose   bool
)

var oizys = o.NewOizys()

var rootCmd = &cobra.Command{
	Use:   "oizys",
	Short: "nix begat oizys",
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		oizys.Update(flake, host, cacheName, verbose)
		oizys.CheckFlake()
	},
}

func init() {
	rootCmd.CompletionOptions.HiddenDefaultCmd = true
	rootCmd.PersistentFlags().StringVar(&flake, "flake", "", "path to flake ($OIZYS_DIR or $HOME/oizys)")
	rootCmd.PersistentFlags().StringVar(&host, "host", "", "host to build (current host)")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "show verbose output")
}
