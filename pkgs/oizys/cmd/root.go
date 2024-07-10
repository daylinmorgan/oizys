package cmd

import (
	"os"

	"oizys/internal/oizys"

	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/log"
	cc "github.com/ivanpirog/coloredcobra"
	"github.com/spf13/cobra"
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
	flake      string
	host       string
	debug      bool
	verbose    bool
	nom        bool
	systemPath bool
	resetCache bool
	minimal    bool
)

var rootCmd = &cobra.Command{
	Use:   "oizys",
	Short: "nix begat oizys",
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		if debug {
			log.Info("running in debug mode")
			log.SetLevel(log.DebugLevel)
		}
		oizys.SetFlake(flake)
		oizys.SetHost(host)
		oizys.SetVerbose(verbose)
		oizys.SetResetCache(resetCache)
		oizys.SetDebug(debug)
	},
}

func setupLogger() {
	log.SetReportTimestamp(false)
	styles := log.DefaultStyles()
	colors := map[log.Level]string{
		log.DebugLevel: "8",
		log.InfoLevel:  "6",
		log.WarnLevel:  "3",
		log.ErrorLevel: "1",
		log.FatalLevel: "1",
	}
	for k, v := range colors {
		styles.Levels[k] = styles.Levels[k].MaxWidth(5).Width(5).Foreground(lipgloss.Color(v))
	}
	log.SetStyles(styles)
}

func init() {
	setupLogger()

	rootCmd.CompletionOptions.HiddenDefaultCmd = true
	rootCmd.PersistentFlags().StringVar(&flake, "flake", "", "path to flake ($OIZYS_DIR or $HOME/oizys)")
	rootCmd.PersistentFlags().StringVar(&host, "host", "", "host(s) to build (current host)")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "show verbose output")
	rootCmd.PersistentFlags().BoolVar(&debug, "debug", false, "show debug output")
	rootCmd.PersistentFlags().BoolVar(&resetCache, "reset-cache", false, "set narinfo-cache-negative-ttl to 0")
}
