#!/bin/bash

export DOCKER_USER=${DOCKER_USER:?-"Missing environment variable"}
export DOCKER_PASSWORD=${DOCKER_PASSWORD:?-"Missing environment variable"}
export DOCKER_REGISTRY=${DOCKER_REGISTRY:-"docker.elastic.co"}

docker run --rm -t \
    -e DOCKER_USER -e DOCKER_PASSWORD -e DOCKER_REGISTRY \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(pwd):/app -w /app \
    docker.elastic.co/observability-ci/dind-buildx:20.10.14 """
docker buildx ls
echo 'Create builder'
docker buildx create --name multibuilder
docker buildx use multibuilder
docker buildx inspect --bootstrap
echo 'Build Docker image'
docker login ${DOCKER_REGISTRY}
docker buildx build --platform linux/amd64,linux/arm64 --push $*
"""
