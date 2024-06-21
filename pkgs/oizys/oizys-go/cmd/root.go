package cmd

import (
	"os"

	o "oizys/internal/oizys"

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
	cacheName  string
	verbose    bool
	nom        bool
	systemPath bool
)

var oizys = o.NewOizys()

var rootCmd = &cobra.Command{
	Use:   "oizys",
	Short: "nix begat oizys",
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		if verbose {
			log.Info("running with verbose mode")
			log.SetLevel(log.DebugLevel)
		}
		oizys.Set(flake, host, cacheName, verbose, systemPath)
		oizys.CheckFlake()
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
	rootCmd.PersistentFlags().StringVar(&host, "host", "", "host to build (current host)")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "show verbose output")
}
