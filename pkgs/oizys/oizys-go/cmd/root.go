package cmd

import (
	"errors"
	"fmt"
	"io/fs"
	"log"
	"os"

	cc "github.com/ivanpirog/coloredcobra"
	"github.com/spf13/cobra"
	"oizys/pkg/oizys"
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

var dryCmd = &cobra.Command{
	Use:   "dry",
	Short: "poor man's nix flake check",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixDryRun(oizys.Output(flake, host))
	},
}

var outputCmd = &cobra.Command{
	Use:   "output",
	Short: "show nixosConfiguration attr",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Print(oizys.Output(flake, host))
	},
}

var bootCmd = &cobra.Command{
	Use:   "boot",
	Short: "nixos rebuild boot",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixosRebuild("boot", flake)
	},
}

var switchCmd = &cobra.Command{
	Use:   "switch",
	Short: "nixos rebuild switch",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixosRebuild("switch", flake, args...)
	},
}

var cacheCmd = &cobra.Command{
	Use:   "cache",
	Short: "build and push to cachix",
	Run: func(cmd *cobra.Command, args []string) {
    oizys.CacheBuild(oizys.Output(flake, host), cacheName, args...)
	},
}

var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "A brief description of your command",
	Run: func(cmd *cobra.Command, args []string) {
		oizys.NixBuild(oizys.Output(flake, host), args...)
	},
}



func init() {
	rootCmd.CompletionOptions.HiddenDefaultCmd = true
	rootCmd.PersistentFlags().StringVar(&flake, "flake", "", "path to flake ($OIZYS_DIR or $HOME/oizys)")
	rootCmd.PersistentFlags().StringVar(&host, "host", "", "host to build (current host)")
	rootCmd.AddCommand(dryCmd)
	rootCmd.AddCommand(outputCmd)
	rootCmd.AddCommand(bootCmd)
	rootCmd.AddCommand(buildCmd)
	rootCmd.AddCommand(switchCmd)
	rootCmd.AddCommand(cacheCmd)
	cacheCmd.Flags().StringVarP(&cacheName, "cache", "c", "daylin", "name of cachix binary cache")
}
