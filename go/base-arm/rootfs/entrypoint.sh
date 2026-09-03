#!/usr/bin/env sh
set -e

if [ -n "${CROSSBUILD_UID+x}" ] && [ -n "${CROSSBUILD_GID+x}" ]; then
    groupadd -f -g "$CROSSBUILD_GID" crossbuild 2>/dev/null || true
    useradd -N -m -c 'Crossbuild User' -u "$CROSSBUILD_UID" -g "$CROSSBUILD_GID" crossbuild 2>/dev/null || true
    export HOME="/home/crossbuild"
    export GOCACHE="${GOCACHE:-$HOME/.cache/go-build}"
    export GOMODCACHE="${GOMODCACHE:-$HOME/go/pkg/mod}"
    mkdir -p "$HOME/.config/go/telemetry" "$GOCACHE" "$GOMODCACHE"
    printf 'off\n' > "$HOME/.config/go/telemetry/mode"
    chown -R "$CROSSBUILD_UID:$CROSSBUILD_GID" "$HOME"
    exec su-exec crossbuild /crossbuild "$@"
fi

exec /crossbuild "$@"
