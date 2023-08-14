#!/usr/bin/env bash
#

set -euo pipefail

PLATFORM_TYPE=$(uname -m)

GVM_URL=https://github.com/andrewkroh/gvm/releases/download/v0.5.1/gvm-linux-amd64
if [[ ${PLATFORM_TYPE} == "arm" || ${PLATFORM_TYPE} == "aarch64" ]]; then
  GVM_URL=GVM_URL=https://github.com/andrewkroh/gvm/releases/download/v0.5.1/gvm-linux-arm64
fi

curl -sL -o ~/bin/gvm $GVM_URL
chmod +x ~/bin/gvm
