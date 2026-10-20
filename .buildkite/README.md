# Buildkite pipelines

These pages describe checked-in pipeline YAML and local scripts. The YAML
does not establish all Buildkite-side pipeline settings or event triggers.

| Pipeline/configuration | Documentation |
| --- | --- |
| Main `golang-crossbuild` pipeline | [golang-crossbuild](docs/golang-crossbuild.md) |
| FPM image pipeline | [fpm](docs/fpm.md) |
| LLVM Apple image pipeline | [llvm-apple](docs/llvm-apple.md) |
| NPCAP version bump pipeline | [bump-npcap-pipeline](docs/bump-npcap-pipeline.md) |

The main pipeline uploads the FPM and LLVM Apple YAML files for applicable
builds. The NPCAP pipeline has a checked-in definition, but the repository
does not identify its Buildkite-side trigger configuration.
