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

ARG GOLANG_VERSION=1.11
ARG GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ARG GOLANG_DOWNLOAD_SHA256=b3fcf280ff86558e0559e185b601c9eade0fd24c900b4c63cd14d1d38613e499

RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
	&& echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

COPY rootfs /

WORKDIR /
RUN go get -d . \
    && go build -o /crossbuild /entrypoint.go \
    && rm -rf /go/* /root/.cache/* /entrypoint.go

ENV GOLANG_CROSSBUILD=1
VOLUME      /app
WORKDIR     /app
ENTRYPOINT  ["/crossbuild"]
