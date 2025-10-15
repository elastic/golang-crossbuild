# Release Process

This document outlines the process for releasing a new version of this project.

## Versioning

This project uses the Golang versioning, for each specific Golang version there will be a GitHub
Release.

## Releasing images for a new Go version

With every new version of `go` we create a new branch with the name of the previous version, `major.minor` format, to allow us to continue building the Docker images for the previous version of `go`. 

For instance, if we are in go `1.24` and go `1.25` is released, we create a new branch `1.24`, then we update the `main` branch to install go `1.25` as explained in the below steps:

1. Update the Go version in [.go-version](https://github.com/elastic/golang-crossbuild/blob/main/.go-version).
1. Update the Docker tag in
   [Makefile.common](https://github.com/elastic/golang-crossbuild/blob/main/go/Makefile.common#L5).
1. Run `.github/updatecli.d/bump-go-release-version.sh "$(cat .go-version)"`
1. Update the versions listed in this README.md.
1. Update the `go-minor` value in [bump-golang.yml](https://github.com/elastic/golang-crossbuild/blob/main/github/workflows/bump-golang.yml) with the new minor go version, i.e: `1.25`.
1. Update the `go-minor` and `branch` values in [bump-golang-previous.yml](https://github.com/elastic/golang-crossbuild/blob/main/github/workflows/bump-golang-previous.yml) with the old minor go version, i.e: `1.24`.
1. Add an entry in the `.mergify.yml` file to support the label backport for `backport-v1.x-1`, i.e: `backport-v1.24`.
1. Create the GitHub label backport for `backport-v1.x-1` in https://github.com/elastic/golang-crossbuild/labels, i.e: `backport-v1.24`.
1. Commit the changes. `git add -u && git commit -m 'Update to Go 1.x.y'`.
1. Create a Pull Request with the description `'Update to Go 1.x.y'`.
1. When merging the PR, the automation will release those docker images.

**NOTE**: Due to the changes in the Debian packages repositories, there are no guarantees that the Docker images for the previous version of `go` will continue to work after some time.

## Releasing a new version of NPCAP

See [npcap](./NPCAP.md) for more information.

## Releasing images for FPM

> [!INFORMATION]
> This is not something we have released for years.

TBC

## Releasing images for LLVM Apple

> [!INFORMATION]
> This is not something we do often maybe once every 3 years.

TBC

## Update an existing released version

> [!INFORMATION]
> This is not something we do often but in some cases we have.

* Create a branch called `major.minor.patch.x` for the `vmajor.minor.patch` tag (where `x` is a literal "x" character, not a number placeholder)
* Cherry-pick your PR, you can use `Mergifyio`, with `@mergifyio backport major.minor.path.x`
* Then the new PR that has been created can be merged when all the GitHub checks have passed.
* Otherwise, create your PR targetting the branch `major.minor.patch.x`

For instance, if the release version `1.25.1` needs to be updated then:

```bash
git checkout v1.25.1
git checkout -b 1.25.1.x
git push upstream 1.25.1.x
```

Afterwards you can then backport your PR or create a new one.
