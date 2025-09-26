# NPCAP

If you'd like to bump the npcap version please follow the below steps:

1) Update `NPCAP_VERSION` value in the `Makefile`.
  * **NOTE**: Make sure the PR adding this is back-ported to the Go versions required by the Packetbeat CrossBuild target in [the mage file](https://github.com/elastic/beats/blob/main/x-pack/packetbeat/magefile.go). This is specified in the beats `.go-version` file.
2) Download the new artifact.
3) Upload the artifact to `gs://golang-crossbuild-ci-internal/private`.
  * **NOTE**: This particular Google Bucket can be accessible only by Elasticians who have got access to the Google project called `elastic-observability-ci`. It's managed thorugh some Terraform code.

Credentials to the artifact service can be found in the `APM-Shared` folder in the password management tool.

4) After you've updated the npcap version in golang-crossbuild, make sure to change the npcap version specified in the [packetbeat magefile](https://github.com/elastic/beats/blob/main/x-pack/packetbeat/magefile.go)

## Backports

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
