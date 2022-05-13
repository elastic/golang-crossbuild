#!/bin/bash
set -e
set +x

DOCKER_USER=${DOCKER_USER:?-"Missing environment variable"}
DOCKER_PASSWORD=${DOCKER_PASSWORD:?-"Missing environment variable"}
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"docker.elastic.co"}

docker run --privileged --rm tonistiigi/binfmt --install all
docker pull --platform=linux/arm64 --platform=linux/amd64  moby/buildkit:buildx-stable-1

# docker run --rm -t \
#     -e DOCKER_USER=${DOCKER_USER} -e DOCKER_PASSWORD=${DOCKER_PASSWORD} -e DOCKER_REGISTRY=${DOCKER_REGISTRY} \
#     -v /var/run/docker.sock:/var/run/docker.sock \
#     -v $(pwd):/app -w /app \
#     docker.elastic.co/observability-ci/dind-buildx:latest """
docker buildx ls
echo 'Create builder'
docker buildx create --name multibuilder
docker buildx use multibuilder
docker buildx inspect --bootstrap
# echo 'Docker login ${DOCKER_REGISTRY}'
# docker login ${DOCKER_REGISTRY}
echo 'Build Docker image'
docker buildx build --platform linux/amd64,linux/arm64 --push $*
# """
