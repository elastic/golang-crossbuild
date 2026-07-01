#!/usr/bin/env bash
# Installs updatecli (version pinned in .updatecli-version) and applies the
# given updatecli pipeline config.
#
# Usage: run-updatecli.sh <path-to-config>
#
# Required environment:
#   GITHUB_TOKEN (exported by the elastic/vault-github-token Buildkite plugin)
set -euo pipefail

source "$(dirname "$0")/common.sh"

MSG="path to an updatecli config file is required"
CONFIG=${1:?$MSG}

UPDATECLI_VERSION=$(cat "${WORKSPACE}/.updatecli-version")

check_platform_architecture
case "$arch_type" in
  amd64) updatecli_arch="x86_64" ;;
  arm64) updatecli_arch="arm64" ;;
  *) echo "Unsupported architecture for updatecli: ${arch_type}" >&2; exit 1 ;;
esac

echo "--- Installing updatecli ${UPDATECLI_VERSION}"
create_bin
retry 3 curl -sL -o "${BIN}/updatecli.tar.gz" \
  "https://github.com/updatecli/updatecli/releases/download/${UPDATECLI_VERSION}/updatecli_Linux_${updatecli_arch}.tar.gz"
tar -xzf "${BIN}/updatecli.tar.gz" -C "${BIN}" updatecli
chmod +x "${BIN}/updatecli"
export PATH="${PATH}:${BIN}"

echo "--- Running updatecli apply against ${CONFIG}"
updatecli apply --config "${CONFIG}"
