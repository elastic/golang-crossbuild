#!/bin/bash
set -e
set +x

BUILDER_NAME="multibuilder${RANDOM}"

docker run --privileged --rm tonistiigi/binfmt --install all
#docker pull --platform=linux/arm64 --platform=linux/amd64  moby/buildkit:buildx-stable-1

docker buildx ls
echo 'Create builder'
docker buildx create --name "${BUILDER_NAME}"
docker buildx use "${BUILDER_NAME}"
docker buildx inspect --bootstrap
echo 'Build Docker image'
docker buildx build --platform linux/amd64,linux/arm64 --push $*
