# golang-crossbuild

golang-crossbuild is a set of Docker images containing the requisite
cross-compilers for cross compiling Go applications. The cross-compilers are
needed when the application uses [cgo](https://golang.org/cmd/cgo/).

The base image used is Debian 9 (stretch) unless otherwise specified.

## Docker Repo

`docker.elastic.co/beats-dev/golang-crossbuild:[TAG]`

## Build Tags

- `1.10.3-main` - linux/{amd64,386} and windows/{amd64,386}
- `1.10.3-arm` - linux/{armv5,armv6,armv7,arm64}
- `1.10.3-darwin` - darwin/{amd64,386}
- `1.10.3-ppc` - linux/{ppc64,ppc64le}
- `1.10.3-mips` - linux/{mips,mipsle,mips64,mips64le}
- `1.10.3-s390x` - linux/s390x
- `1.10.3-main-debian7` - linux/{amd64,386} and windows/{amd64,386} (Debian 7
  uses glibc 2.13 so the resulting binaries (if dynamically linked) have greater
  compatibility.)

## Usage Example

```sh
docker run -it --rm \
  -v $GOPATH/src/github.com/user/go-project:/go/src/github.com/user/go-project \
  -w /go/src/github.com/user/go-project \
  -env CGO_ENABLED=1 \
  docker.elastic.co/beats-dev/golang-crossbuild:1.10.3-arm \
  --build-cmd "make build" \
  -p "linux/armv7"
```

This will execute your projects `make build` target. While executing the build
command the following variables with be added to the environment: GOOS, GOARCH,
GOARM, PLATFORM_ID, CC, and CXX.
