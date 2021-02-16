[![Build Status](https://beats-ci.elastic.co/buildStatus/icon?job=Beats%2Fgolang-crossbuild-mbp%2Fmaster)](https://beats-ci.elastic.co/job/Beats/job/golang-crossbuild-mbp/job/master/)

# golang-crossbuild

golang-crossbuild is a set of Docker images containing the requisite
cross-compilers for cross compiling Go applications. The cross-compilers are
needed when the application uses [cgo](https://golang.org/cmd/cgo/).

The base image used is Debian 9 (stretch) unless otherwise specified.

## Docker Repo

`docker.elastic.co/beats-dev/golang-crossbuild:[TAG]`

## Build Tags

- `1.10.8-main`, `1.11.13-main`, `1.12.12-main`, `1.13.12-main`, `1.14.15-main`, `1.15.8-main` - linux/{amd64,386} and windows/{amd64,386}
- `1.10.8-arm`, `1.11.13-arm`, `1.12.12-arm`, `1.13.12-arm`, `1.14.15-arm`, `1.15.8-arm` - linux/{armv5,armv6,armv7,arm64}
- `1.10.8-darwin`, `1.11.13-darwin`, `1.12.12-darwin`, `1.13.12-darwin`, `1.14.15-darwin` - darwin/{386}
- `1.10.8-darwin`, `1.11.13-darwin`, `1.12.12-darwin`, `1.13.12-darwin`, `1.14.15-darwin`, `1.15.8-darwin` - darwin/{amd64}
- `1.10.8-ppc`, `1.11.13-ppc`, `1.12.12-ppc`, `1.13.12-ppc`, `1.14.15-ppc`, `1.15.8-ppc` - linux/{ppc64,ppc64le}
- `1.10.8-mips`, `1.11.13-mips`, `1.12.12-mips`, `1.13.12-mips`, `1.14.15-mips`, `1.15.8-mips` - linux/{mips,mipsle,mips64,mips64le}
- `1.10.8-s390x`, `1.11.13-s390x`, `1.12.12-s390`, `1.13.12-s390`, `1.14.15-s390`, `1.15.8-s390` - linux/s390x
- `1.10.8-main-debian7`, `1.11.13-main-debian7`, `1.12.12-debian7`, `1.13.12-debian7`, `1.14.15-debian7`, `1.15.8-debian7` - linux/{amd64,386} and windows/{amd64,386} (Debian 7
  uses glibc 2.13 so the resulting binaries (if dynamically linked) have greater
  compatibility.)
- `1.10.8-main-debian8`, `1.11.13-main-debian8`, `1.12.12-main-debian8`, `1.13.12-debian8`, `1.14.15-debian8`, `1.15.8-debian8` - linux/{amd64,386} and windows/{amd64,386} (Debian 8
  uses glibc 2.19)
- `1.15.8-debian9` - linux/{amd64,386} and windows/{amd64,386} (Debian 9 uses glibc 2.24)
- `1.15.8-base-arm-debian9` - linux/arm64 (Debian 9 uses glibc 2.24)
- `1.15.8-debian10` - linux/{amd64,386} and windows/{amd64,386} (Debian 10 uses glibc 2.28)

## Usage Example

```sh
docker run -it --rm \
  -v $GOPATH/src/github.com/user/go-project:/go/src/github.com/user/go-project \
  -w /go/src/github.com/user/go-project \
  -e CGO_ENABLED=1 \
  docker.elastic.co/beats-dev/golang-crossbuild:1.10.8-arm \
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
