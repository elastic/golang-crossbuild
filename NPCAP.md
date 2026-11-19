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
3. Once that PR has been merged, opens PRs bumping `NPCAP_VERSION` for the Go versions used by the
   [active elastic/beats branches](https://storage.googleapis.com/artifacts-api/snapshots/branches.json)
   (see [bump-npcap-backports.sh](.buildkite/scripts/bump-npcap-backports.sh)):
   * the `1.X` branch, if it exists. The script bumps it even when it builds another patch version than beats uses,
     because beats reads the npcap version from this branch.
   * the `1.X.Y.x` branch, created from the `v1.X.Y` tag if it does not exist yet. The script bumps it only when
     the image `golang-crossbuild:1.X.Y-npcap-<version>-debian9` is not published and no `1.X` branch builds the
     exact Go version (`.go-version`) used by beats.

   These PRs are labelled `automation` and `backport`, and Mergify merges them once CI passes. Once merged,
   the `golang-crossbuild:1.X.Y-npcap-<version>-*` images are published, and the elastic/beats `bump-npcap`
   workflow can bump the npcap version in beats.

Bumping the npcap version on a `1.X.Y.x` branch only publishes new `-npcap-<version>` images; images built
for previous npcap versions remain available, so consumers still pinned to an older npcap version are not
affected.

### How beats picks the npcap version

The elastic/beats `bump-npcap` workflow reads `NPCAP_VERSION` from the golang-crossbuild branch named after the
`1.X` of the Go version in the beats `.go-version`. If that branch does not exist, it reads `main`. It never
reads a `1.X.Y.x` branch. Before it opens a PR, it requires the image
`golang-crossbuild:1.X.Y-npcap-<version>-debian9` to exist, with the full Go version `1.X.Y`.

This is why the script bumps two things. The `1.X` branch sets the version that beats reads. The `1.X.Y.x`
branch publishes the image for the exact Go version that beats uses, when `1.X` builds another patch version.
A bump on `1.X.Y.x` alone does not change what beats reads.

The script needs a `docker.elastic.co` login to check images, and the `gh` CLI with `GITHUB_TOKEN`.

### Testing the helpers

Start a build of the `golang-crossbuild-bump-npcap` pipeline with `TEST_IMAGE_CHECK=1` (add `DRY_RUN=1` to
be safe). The `Test npcap image check` step runs
[test-npcap-lib.sh](.buildkite/scripts/test-npcap-lib.sh) against the real GitHub API and registry. Set
`TEST_IMAGE_GO` and `TEST_IMAGE_NPCAP` to check a different published tag.

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
