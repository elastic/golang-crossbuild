# NPCAP

If you'd like to bump the npcap version please follow the below steps:

1) Update `NPCAP_VERSION` value in the `Makefile`.
  * **NOTE**: Make sure the PR adding this is back-ported to the Go versions required by the Packetbeat CrossBuild target in [the mage file](https://github.com/elastic/beats/blob/main/x-pack/packetbeat/magefile.go). This is specified in the beats `.go-version` file.
2) Download the new artifact.
3) Upload the artifact to `gs://obs-ci-cache/private`.
  * **NOTE**: This particular Google Bucket can be accessible only by Elasticians who have got access to the Google project called `elastic-observability`.

Credentials to the artifact service can be found in the `APM-Shared` folder in the password management tool.
