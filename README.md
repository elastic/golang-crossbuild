[![Build Status](https://beats-ci.elastic.co/buildStatus/icon?job=Beats%2Fgolang-crossbuild-mbp%2Fmaster)](https://beats-ci.elastic.co/job/Beats/job/golang-crossbuild-mbp/job/master/)

# golang-crossbuild

golang-crossbuild is a set of Docker images containing the requisite
cross-compilers for cross compiling Go applications. The cross-compilers are
needed when the application uses [cgo](https://golang.org/cmd/cgo/).

The base image used is Debian 9 (stretch) unless otherwise specified.

## Docker Repo

`docker.elastic.co/beats-dev/golang-crossbuild:[TAG]`

## Build Tags

| Description | Tags for 1.10 | Tags for 1.11 | Tags for 1.12 | Tags for 1.13 | Tags for 1.14 | Tags for 1.15 | Tags for 1.16 | Tags for 1.17 |
| ------------- | -----| ------- | ----- |  ------ |  ------ |  ------ |  ------ |  ------ |
| linux/{amd64,386} and windows/{amd64,386} | `1.10.8-main` | `1.11.13-main` | `1.12.12-main` |  `1.13.12-main` | `1.14.15-main` | `1.15.14-main` | `1.16.7-main` | `` |
| linux/{armv5,armv6,armv7} | `1.10.8-arm` | `1.11.13-arm` | `1.12.12-arm` | `1.13.12-arm` | `1.14.15-arm` | `1.15.14-arm` | **See below** | **See below** |
| linux/arm64 | **See above** | **See above** | **See above** | **See above** | **See above** | **See above** | `1.16.7-arm` | ` ` |
| linux/{armv5,armv6} | **See above** | **See above** | **See above** | **See above** | **See above** | **See above** | `1.16.7-armel` | ` ` |
| linux/{armv7} | **See above** | **See above** | **See above** | **See above** | **See above** | **See above** | `1.16.7-armhf` | ` ` |
| darwin/{386} | `1.10.8-darwin` | `1.11.13-darwin` | `1.12.12-darwin` | `1.13.12-darwin` | `1.14.15-darwin` | `1.16.7-darwin` | ` ` |
| darwin/{amd64} | `1.10.8-darwin` | `1.11.13-darwin` | `1.12.12-darwin` | `1.13.12-darwin` | `1.14.15-darwin` | `1.16.7-darwin` | ` ` |
| linux/{ppc64,ppc64le} | `1.10.8-ppc` | `1.11.13-ppc` | `1.12.12-ppc` | `1.13.12-ppc` | `1.14.15-ppc` | `1.15.14-ppc` | `1.16.7-ppc` | ` ` |
| linux/{mips,mipsle,mips64,mips64le} | `1.10.8-mips` | `1.11.13-mips` | `1.12.12-mips` | `1.13.12-mips` | `1.14.15-mips` | `1.15.14-mips` | **See below** | **See below** |
| linux/{mips64,mips64le} | **See above** | **See above** | **See above** | **See above** | **See above** | **See above** | `1.16.7-mips` | ` ` |
| linux/{mips,mipsle} | **See above** | **See above** | **See above** | **See above** | **See above** | **See above** | `1.16.7-mips32` | ` ` |
| linux/s390x | `1.10.8-s390x` | `1.11.13-s390x` | `1.12.12-s390` | `1.13.12-s390` | `1.14.15-s390` | `1.15.14-s390` | `1.16.7-s390` | ` ` |
| linux/{amd64,386} and windows/{amd64,386} (Debian 7 (see **below**)) |`1.10.8-main-debian7` | `1.11.13-main-debian7` | `1.12.12-main-debian7` | `1.13.12-main-debian7` | `1.14.15-main-debian7` | `1.15.14-main-debian7` | `1.16.7-main-debian7` | ` ` |
| linux/{amd64,386} and windows/{amd64,386} (Debian 8 (see **below**)) | `1.10.8-main-debian8` | `1.11.13-main-debian8` | `1.12.12-main-debian8` | `1.13.12-debian8` | `1.14.15-main-debian8` | `1.15.14-main-debian8` | `1.16.7-main-debian8` | ` ` |
| linux/{amd64,386} and windows/{amd64,386} (Debian 9 (see **below**)) | NA | NA | NA | NA | NA | `1.15.14-main-debian9` | `1.16.7-main-debian9` | ` ` |
| linux/{amd64,386} and windows/{amd64,386} (Debian 10 (see **below**)) | NA | NA | NA | NA | NA | `1.15.14-main-debian10` | `1.16.7-main-debian10` | ` ` |
| linux/arm64 (Debian 9 (see **below**)) | NA | NA | NA | NA | NA | `1.15.14-base-arm-debian9` | `1.16.7-base-arm-debian9` | ` ` |

**Debian7** uses `glibc 2.13` so the resulting binaries (if dynamically linked) have greater compatibility.
**Debian8** uses `glibc 2.19`.
**Debian9** uses `glibc 2.24`.
**Debian10** uses `glibc 2.28`.

## Usage Example

```sh
docker run -it --rm \
  -v $GOPATH/src/github.com/user/go-project:/go/src/github.com/user/go-project \
  -w /go/src/github.com/user/go-project \
  -e CGO_ENABLED=1 \
  docker.elastic.co/beats-dev/golang-crossbuild:1.16.7-armhf \
  --build-cmd "make build" \
  -p "linux/armv7"
```

This will execute your projects `make build` target. While executing the build
command the following variables with be added to the environment: GOOS, GOARCH,
GOARM, PLATFORM_ID, CC, and CXX.

## Releasing images for a new Go version

1. Update the Docker tag in
   [Makefile.common](https://github.com/elastic/golang-crossbuild/blob/master/go1.10/Makefile.common#L5) and/or
   [Makefile.common](https://github.com/elastic/golang-crossbuild/blob/master/go1.11/Makefile.common#L5) and/or
   [Makefile.common](https://github.com/elastic/golang-crossbuild/blob/master/go1.12/Makefile.common#L5).
1. Update the Go version and SHA256 in the
   [Dockerfile(s)](https://github.com/elastic/golang-crossbuild/blob/master/go1.10/base/Dockerfile#L19-L21).
   The SHA256 must be obtained from <https://golang.org/dl/.>
1. Update the versions listed in this README.md.
1. Commit the changes. `git add -u && git commit -m 'Update to Go 1.x.y'`.
1. Create a Pull Request with the description `'Update to Go 1.x.y'`.
1. When merging the PR then the automation will release those docker images.

### Manual steps

> This is not required unless the CI service is down.

1. Build the images from the project's root with `make`.
1. Get a logon token for the container registry by visiting <https://docker.elastic.co:7000>.
1. Publish the images with `make push`.

## Packaging MacOS SDK

The osxcross repository used to cross compile for MacOSX has [instructions for packaging the SDK](https://github.com/tpoechtrager/osxcross#packaging-the-sdk).

The instructions for packaging the SDK on a Linux instance are:

1. Clone the [osxcross](https://github.com/tpoechtrager/osxcross) repo.
1. Install `clang` | `make` | `libssl-dev` | `lzma-dev` | `libxml2-dev` | `libbz2-dev`.
1. Download [Xcode from Apple](Download Xcode: https://developer.apple.com/download/more]).
1. Run `./tools/gen_sdk_package_pbzx.sh <xcode>.xip`.

### bzip2 issues

If the `gen_sdk_package_pbza.sh` script gives an error that reads:

```
Error while extracting archive:(Metadata): bzip2 support not compiled in. (Success)
```

A manual work-around is needed in order to create the SDK (other people have reported that installing `libbz2-dev` fixed this issue).

First edit `osxcross/tools/tools.sh` to remove the `trap` line from the `create_tmp_dir` function (currently line 264).

Then re-run  `./tools/gen_sdk_package_pbzx.sh <xcode>.xip`.

Go to the tmp dir created in the build dir: `cd osxcross/build/tmp_<X>`.

Then run:
```
../../target/SDK/tools/bin/pbzx -n Content | cpio -i
cd ../..
XCODEDIR=osxcross/build/tmp_<X> ./tools/gen_sdk_package.sh
```

The SDK should be in the working directory.
The tmp dir can be safely deleted after this.

The SDKs should be uploaded into the `gs://obs-ci-cache` bucket on GCP (Google Cloud Platform).
This is accessible to authorized users in the `elastic-observability` project [here](https://console.cloud.google.com/storage/browser/obs-ci-cache).
