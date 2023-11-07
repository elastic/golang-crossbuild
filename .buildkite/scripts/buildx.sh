#!/usr/bin/env bash
set -e
set +x

BUILDPLATFORM=${BUILDPLATFORM:-"linux/amd64,linux/arm64"}

#docker run --privileged --rm tonistiigi/binfmt --install all
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
BUILDER_NAME="multibuilder${RANDOM}"
echo "Add support for multiarch"
docker run --privileged --rm tonistiigi/binfmt --install all

docker buildx ls
echo 'Create builder'
docker buildx create --name "${BUILDER_NAME}"
docker buildx use "${BUILDER_NAME}"
docker buildx inspect --bootstrap
echo 'Build Docker image'
docker buildx build --platform "${BUILDPLATFORM}" --push $*
