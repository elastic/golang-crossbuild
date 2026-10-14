# NPCAP

If you'd like to bump the npcap version please follow the below steps:

1) Update `NPCAP_VERSION` value in the `Makefile`.
  * **NOTE**: Make sure the PR adding this is back-ported to the Go versions required by the Packetbeat CrossBuild target in [the mage file](https://github.com/elastic/beats/blob/main/x-pack/packetbeat/magefile.go). This is specified in the beats `.go-version` file.
2) Download the new artifact.
3) Upload the artifact to `gs://golang-crossbuild-ci-internal/private`.
  * **NOTE**: This particular Google Bucket can be accessible only by Elasticians who have got access to the Google project called `elastic-observability-ci`. It's managed thorugh some Terraform code.

Credentials to the artifact service can be found in the `APM-Shared` folder in the password management tool.

4) After you've updated the npcap version in golang-crossbuild, make sure to change the npcap version specified in the [packetbeat magefile](https://github.com/elastic/beats/blob/main/x-pack/packetbeat/magefile.go)

## Automated backports

The `golang-crossbuild-bump-npcap` Buildkite pipeline ([bump-npcap-pipeline.yml](.buildkite/bump-npcap-pipeline.yml))
runs daily and:

1. Uploads the latest npcap OEM installer to `gs://golang-crossbuild-ci-internal/private`.
2. Opens a PR bumping `NPCAP_VERSION` on `main`. This PR needs a human review.
3. Once that PR has been merged, opens PRs bumping `NPCAP_VERSION` on the branches that build the Go
   versions used by the [active elastic/beats branches](https://storage.googleapis.com/artifacts-api/snapshots/branches.json)
   (see [bump-npcap-backports.sh](.buildkite/scripts/bump-npcap-backports.sh)):
   * `1.X` if it builds the exact Go version (`.go-version`) used by beats,
   * otherwise `1.X.Y.x`, created from the `v1.X.Y` tag if it does not exist yet.

   These PRs are labelled `automation` and `backport`, and need a review. Once merged, the
   `golang-crossbuild:1.X.Y-npcap-<version>-*` images are published, and the elastic/beats `bump-npcap`
   workflow can bump the npcap version in beats.

Bumping the npcap version on a `1.X.Y.x` branch only publishes new `-npcap-<version>` images; images built
for previous npcap versions remain available, so consumers still pinned to an older npcap version are not
affected.

## Manual backports

If you'd like to backport any NCAP_VERSION to any existing golang-crosbuild version, then you need to:

* Create a branch called `major.minor.patch.x` for the `vmajor.minor.patch` tag (where `x` is a literal "x" character, not a number placeholder)
* Cherry-pick your PR, you can use `Mergifyio`, with `@mergifyio backport major.minor.path.x`
* Then the new PR that has been created can be merged when all the GitHub checks have passed.

For instance, if ncap version needs to be updated in `1.20.8` then:

```bash
git checkout v1.20.8
git checkout -b 1.20.8.x
git push upstream 1.20.8.x
```

Afterwards you can then backport your PR with ncap changes with the GitHub command `@Mergifyio backport 1.20.8.x`,
see https://github.com/elastic/golang-crossbuild/pull/315 that illustrates this example.

https://github.com/elastic/golang-crossbuild/pull/320 is the one that has been created with the backport targeting
`1.20.8.x`. Automatically when it gets merged, the golang-crossbuild:1.20.8 will be regenerated and contain the
new ncap changes.
