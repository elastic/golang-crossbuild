// +build linux

package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"sort"
	"strings"

	"github.com/spf13/cobra"
	"gopkg.in/yaml.v2"
)

var rootCmd = &cobra.Command{
	Use:   "crossbuild",
	Short: "crossbuild is simple tool for cross-compiling Go binaries",
	Long: `crossbuild is a containerized tool for cross-compiling Go binaries
by mounting the project inside of a container equipped with cross-compilers.

The root of your project's repo should be mounted at the appropriate location
on the GOPATH which is set to /go.

While executing the build command the following variables will be added to the
environment: GOOS, GOARCH, GOARM, GOTOOLCHAIN=local, PLATFORM_ID, CC, and CXX.
`,
	RunE:         doBuild,
	SilenceUsage: true,
}

func init() {
	rootCmd.PersistentFlags().StringVarP(&buildCommand, "build-cmd", "c",
		"make build", "Build command to execute.")

	rootCmd.PersistentFlags().StringSliceVarP(&platforms, "platforms", "p", nil,
		"Target platform for the binary in GOOS/GOARCH format (e.g. windows/amd64).")
	rootCmd.MarkPersistentFlagRequired("platforms")
}

func main() {
	log.SetFlags(0)

	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}

var (
	buildCommand string
	platforms    []string
)

func doBuild(_ *cobra.Command, _ []string) error {
	for _, p := range platforms {
		env, err := buildEnvironment(p)
		if err != nil {
			return fmt.Errorf("failed constructing the build environment for %v: %v", p, err)
		}

		if err = execBuildCommand(env); err != nil {
			return fmt.Errorf("failed building for %v: %v", p, err)
		}
	}

	return nil
}

func isDirEmpty(name string) (bool, error) {
	f, err := os.Open(name)
	if err != nil {
		return false, err
	}
	defer f.Close()

	_, err = f.Readdirnames(1)
	if err == io.EOF {
		return true, nil
	}
	return false, err
}

func buildEnvironment(platform string) (map[string]string, error) {
	parts := strings.SplitN(platform, "/", 2)
	if len(parts) != 2 {
		return nil, fmt.Errorf("invalid platform %v", platform)
	}

	platformID := strings.Join(parts, "-")
	goos := parts[0]
	arch := parts[1]
	goarch := arch
	goarm := ""

	if strings.HasPrefix(arch, "armv") {
		goarch = "arm"
		goarm = strings.TrimPrefix(arch, "armv")
	}

	env := map[string]string{
		"GOOS":        goos,
		"GOARCH":      goarch,
		"GOARM":       goarm,
		"GOTOOLCHAIN": "local", // Disable automatic downloads of toolchains for reproducible builds.
		"PLATFORM_ID": platformID,
	}

	if err := loadCompilerSettings(goos, arch, env); err != nil {
		return nil, fmt.Errorf("failed while loading compiler settings: %v", err)
	}

	return env, nil
}

type Compilers struct {
	GOOS map[string]struct {
		Arch map[string]struct {
			Env map[string]string `yaml:",inline"`
		} `yaml:",inline"`
	} `yaml:",inline"`
}

func loadCompilerSettings(goos, arch string, env map[string]string) error {
	data, err := ioutil.ReadFile("/compilers.yaml")
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return fmt.Errorf("failed to read /compilers.yaml: %v", err)
	}

	var compilers Compilers
	if err = yaml.Unmarshal(data, &compilers); err != nil {
		return fmt.Errorf("failed to parse /compilers.yaml: %v", err)
	}

	arches, found := compilers.GOOS[goos]
	if !found {
		return fmt.Errorf("%v is not supported by this image", goos)
	}

	settings, found := arches.Arch[arch]
	if !found {
		return fmt.Errorf("%v/%v is not supported by this image", goos, arch)
	}

	for k, v := range settings.Env {
		env[k] = v
	}

	return nil
}

func execBuildCommand(env map[string]string) error {
	cmd := exec.Command("sh", "-c", buildCommand)
	cmd.Env = os.Environ()
	logEnv := make([]string, 0, len(env))
	for k, v := range env {
		kv := k + "=" + v
		cmd.Env = append(cmd.Env, kv)
		logEnv = append(logEnv, kv)
	}
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	var b strings.Builder
	sort.Strings(logEnv)
	fmt.Fprintf(&b, ">> Building using: cmd='%v', env=[%v]", buildCommand, strings.Join(logEnv, ", "))

	log.Println(b.String())
	return cmd.Run()
}
