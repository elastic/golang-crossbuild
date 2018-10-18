ARG VERSION
ARG REPOSITORY
FROM ${REPOSITORY}/golang-crossbuild:${VERSION}-base

RUN \
    apt-get update \
        && apt-get dist-upgrade -y \
        && apt-get install -y --no-install-recommends \
            libsystemd-dev \
        && rm -rf /var/lib/apt/lists/*
