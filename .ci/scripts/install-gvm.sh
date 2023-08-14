#!/usr/bin/env bash
#

set -euo pipefail

PLATFORM_TYPE=$(uname -m)
GVM_TYPE=amd64
if [[ ${PLATFORM_TYPE} == "arm" || ${PLATFORM_TYPE} == "aarch64" ]]; then
  GVM_TYPE=arm64
fi

OS=$(uname -s)
GVM_OS=linux
if [ "${OS}" == "Darwin" ] ; then
  GVM_OS=darwin
fi

set -x
rm ~/bin/gvm || true
curl -fsSL -o ~/bin/gvm https://github.com/andrewkroh/gvm/releases/download/v0.5.1/gvm-$GVM_OS-$GVM_TYPE
chmod +x ~/bin/gvm
