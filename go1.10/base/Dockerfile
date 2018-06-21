ARG DEBIAN_VERSION
FROM debian:${DEBIAN_VERSION}

RUN \
    apt-get update \
        && apt-get dist-upgrade -y \
        && apt-get install -y --no-install-recommends \
            build-essential \
            ca-certificates \
            curl \
            git \
            gnupg \
            make \
            file \
            flex \
            bison \
        && rm -rf /var/lib/apt/lists/*

ARG GOLANG_VERSION=1.10.3
ARG GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ARG GOLANG_DOWNLOAD_SHA256=fa1b0e45d3b647c252f51f5e1204aba049cde4af177ef9f2181f43004f901035

RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
	&& echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

ARG MAGE_VERSION=2.1
ARG MAGE_DOWNLOAD_URL=https://github.com/magefile/mage/releases/download/${MAGE_VERSION}/mage_${MAGE_VERSION}_Linux-64bit.tar.gz
ARG MAGE_DOWNLOAD_SHA256=44f4a34fcf7bd17c11c6ed2a7b495900c771289c580fdef517a950fdccd15e02

RUN curl -fsSL "$MAGE_DOWNLOAD_URL" -o mage.tar.gz \
	&& echo "$MAGE_DOWNLOAD_SHA256  mage.tar.gz" | sha256sum -c - \
    && mkdir /usr/local/mage \
	&& tar -C /usr/local/mage -xzf mage.tar.gz \
	&& rm mage.tar.gz
ENV PATH /usr/local/mage:$PATH

COPY rootfs /

WORKDIR /
RUN go get -d . \
    && go build -o /crossbuild /entrypoint.go \
    && rm -rf /go/* /root/.cache/* /entrypoint.go

ENV GOLANG_CROSSBUILD=1
VOLUME      /app
WORKDIR     /app
ENTRYPOINT  ["/crossbuild"]
