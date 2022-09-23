# NPCAP

If you'd like to bump the npcap version please follow the below steps:

1) Update `NPCAP_VERSION` value in the `Makefile`.
2) Download the new artifact.
3) Upload the artifact to `gs://obs-ci-cache/private`.
  * **NOTE**: This particular Google Bucket can be accessible only by Elasticians who have got access to the Google project called `elastic-observability`.

Credentials to the artifact service can be found in the `APM-Shared` folder in the password management tool.
