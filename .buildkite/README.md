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
builds. Buildkite API configuration checked 2026-10-20 reports an enabled
weekly schedule for the NPCAP pipeline on `main` (`0 4 * * 1
America/New_York`, “Weekly check for new npcap release”). The API reports
branch, pull-request, and tag builds disabled and trigger mode `none`. The
checked-in YAML remains the authority for step behavior.
