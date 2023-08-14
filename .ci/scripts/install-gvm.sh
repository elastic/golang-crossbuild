#!/usr/bin/env bash
#

set -euo pipefail

PLATFORM_TYPE=$(uname -m)

GVM_TYPE=amd64
if [[ ${PLATFORM_TYPE} == "arm" || ${PLATFORM_TYPE} == "aarch64" ]]; then
  GVM_TYPE=arm64
fi

curl -sL -o ~/bin/gvm https://github.com/andrewkroh/gvm/releases/download/v0.5.1/gvm-linux-$GVM_TYPE
chmod +x ~/bin/gvm
