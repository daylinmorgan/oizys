package cmd

import (
	"errors"
	"fmt"
	"io/fs"
	"log"
	"os"

	cc "github.com/ivanpirog/coloredcobra"
	"github.com/spf13/cobra"
)

func setFlake() {
	if flake == "" {
		oizysDir, ok := os.LookupEnv("OIZYS_DIR")
		if !ok {
			home := os.Getenv("HOME")
			flake = fmt.Sprintf("%s/%s", home, "oizys")
		} else {
			flake = oizysDir
		}
	}

	if _, err := os.Stat(flake); errors.Is(err, fs.ErrNotExist) {
		log.Fatalln("path to flake:", flake, "does not exist")
	}
}

func setHost() {
	if host == "" {
		hostname, err := os.Hostname()
		if err != nil {
			log.Fatal(err)
		}
		host = hostname
	}
}

func Execute() {
	cc.Init(&cc.Config{
		RootCmd:         rootCmd,
		Headings:        cc.HiCyan + cc.Bold,
		Commands:        cc.HiYellow + cc.Bold,
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
)

var rootCmd = &cobra.Command{
	Use:   "oizys",
	Short: "nix begat oizys",
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		setFlake()
		setHost()
	},
}


func init() {
	rootCmd.CompletionOptions.HiddenDefaultCmd = true
	rootCmd.PersistentFlags().StringVar(&flake, "flake", "", "path to flake ($OIZYS_DIR or $HOME/oizys)")
	rootCmd.PersistentFlags().StringVar(&host, "host", "", "host to build (current host)")
}
