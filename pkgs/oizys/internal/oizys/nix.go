package oizys

import (
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"strings"

	"github.com/charmbracelet/log"
)

var ignoredMap = stringSliceToMap(
	[]string{
		// nix
		"ld-library-path", "builder.pl", "profile", "system-path",
		// nixos
		"nixos-install",
		"nixos-version",
		"nixos-manual-html",
		"nixos-configuration-reference-manpage",
		"nixos-rebuild",
		"nixos-help",
		"nixos-generate-config",
		"nixos-enter",
		"nixos-container",
		"nixos-build-vms",
		"nixos-wsl-version", "nixos-wsl-welcome-message", "nixos-wsl-welcome",
		// trivial packages
		"restic-gdrive", "gitea", "lock", "code",
	},
)

type Derivation struct {
	InputDrvs map[string]interface{}
	Name      string
}

func findSystemPath(nixosDrv Derivation) (string, error) {
	for drv := range nixosDrv.InputDrvs {
		if strings.HasSuffix(drv, "system-path.drv") {
			return drv, nil
		}
	}
	return "", errors.New("failed to find path for system-path.drv")
}

func findSystemPaths(drv map[string]Derivation) ([]string, error) {
	hosts := strings.Split(o.host, " ")
	systemDrvs := make([]string, 0, len(hosts))
	for _, p := range Keys(drv) {
		if strings.HasPrefix(strings.SplitN(p, "-", 2)[1], "nixos-system-") {
			systemDrvs = append(systemDrvs, p)
		}
	}
	if len(hosts) != len(systemDrvs) {
		return nil, errors.New("didn't find appropriate number of nixos-system derivations")
	}
	systemPaths := make([]string, 0, len(hosts))
	for _, name := range systemDrvs {
		systemPath, err := findSystemPath(drv[name])
		if err != nil {
			return nil, fmt.Errorf("error finding system-path for %s: %w", name, err)
		}
		systemPaths = append(systemPaths, systemPath)
	}

	return systemPaths, nil
}

func drvNotIgnored(drv string) bool {
	s := strings.SplitN(strings.Replace(drv, ".drv", "", 1), "-", 2)
	_, ok := ignoredMap[s[len(s)-1]]
	return !ok
}

func stringSliceToMap(slice []string) map[string]struct{} {
	hashMap := make(map[string]struct{}, len(slice))
	for _, s := range slice {
		hashMap[s] = struct{}{}
	}
	return hashMap
}

func drvsToInputs(derivation map[string]Derivation) []string {
	var drvs []string
	for _, drv := range derivation {
		for name := range drv.InputDrvs {
			drvs = append(drvs, name)
		}
	}
	return drvs
}

// compute the overlap between two slices of strings
func overlapStrings(a []string, b []string) []string {
	var overlap []string
	set := stringSliceToMap(a)
	for _, s := range b {
		_, ok := set[s]
		if ok {
			overlap = append(overlap, s)
		}
	}
	return overlap
}

func nixDerivationShowToInputs(output []byte) []string {
	var derivation map[string]Derivation
	if err := json.Unmarshal(output, &derivation); err != nil {
		log.Fatal(err)
	}
	return drvsToInputs(derivation)
}

func filter[T any](ss []T, test func(T) bool) (ret []T) {
	for _, s := range ss {
		if test(s) {
			ret = append(ret, s)
		}
	}
	return
}

func toBuildNixosConfiguration() []string {
	systemCmd := exec.Command("nix", "build", "--dry-run")
	systemCmd.Args = append(systemCmd.Args, NixosConfigAttrs()...)
	if o.resetCache {
		systemCmd.Args = append(systemCmd.Args, "--narinfo-cache-negative-ttl", "0")
	}
	result, err := cmdOutputWithSpinner(
		systemCmd,
		fmt.Sprintf("running dry build for: %s", strings.Join(NixosConfigAttrs(), " ")),
		true,
	)
	if err != nil {
		log.Fatal("failed to dry-run build system", "err", err)
	}
	toBuild, _ := parseDryRun2(string(result))
	return toBuild
}

func evaluateDerivations(drvs ...string) map[string]Derivation {
	cmd := exec.Command("nix", "derivation", "show", "-r")
	cmd.Args = append(cmd.Args, drvs...)
	out, err := cmdOutputWithSpinner(cmd,
		fmt.Sprintf("evaluating derivations %s", strings.Join(drvs, " ")),
		false)
	if err != nil {
		log.Fatal("failed to evalute derivation for", "drvs", drvs, "err", err)
	}

	var derivation map[string]Derivation
	if err := json.Unmarshal(out, &derivation); err != nil {
		log.Fatal("failed to decode json", "err", err)
	}
	return derivation
}

// Keys returns the keys of the map m.
// The keys will be an indeterminate order.
func Keys[M ~map[K]V, K comparable, V any](m M) []K {
	r := make([]K, 0, len(m))
	for k := range m {
		r = append(r, k)
	}
	return r
}

func systemPathDrvsToBuild() []string {
	toBuild := toBuildNixosConfiguration()
	drv := evaluateDerivations(NixosConfigAttrs()...)
	systemPaths, err := findSystemPaths(drv)
	// systemPath, err := findSystemPath(drv)
	if err != nil {
		log.Fatal("error collecting system paths", "err", err)
	}
	var inputDrvs []string
	for _, path := range systemPaths {
		inputDrvs = append(inputDrvs, Keys(drv[path].InputDrvs)...)
	}

	toActuallyBuild := filter(
		overlapStrings(inputDrvs, toBuild),
		drvNotIgnored,
	)

	drvs := make([]string, 0, len(toActuallyBuild))
	for _, pkg := range toActuallyBuild {
		fmt.Println(pkg)
		drvs = append(drvs, fmt.Sprintf("%s^*", strings.TrimSpace(pkg)))
	}
	return drvs
}
