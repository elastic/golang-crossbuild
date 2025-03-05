#!/usr/bin/env bash
set -e
set +x

BUILDPLATFORM=${BUILDPLATFORM:-"linux/amd64,linux/arm64"}

BUILDER_NAME="multibuilder${RANDOM}"
echo "Add support for multiarch"
# See https://docs.docker.com/build/building/multi-platform/#install-qemu-manually
# We use QEMU for non arm platforms using the golang-crossbuild
docker run --privileged --rm tonistiigi/binfmt:v9.2.2 --install all

docker buildx ls
echo 'Create builder'
docker buildx create --name "${BUILDER_NAME}"
docker buildx use "${BUILDER_NAME}"
docker buildx inspect --bootstrap
echo 'Build Docker image'
docker buildx build --progress=plain --platform "${BUILDPLATFORM}" --push $*
