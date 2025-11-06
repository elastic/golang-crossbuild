#!/usr/bin/env bash

set -euo pipefail

go_version=$(cat .go-version)
if grep -q "VERSION\s*:=\s*${go_version}" go/Makefile.common ; then
    echo "Go version ${go_version} is consistent between .go-version and go/Makefile.common"
    exit 0
fi

echo "Go version mismatch detected!"
echo "  .go-version: ${go_version}"
echo "  go/Makefile.common: $(grep '^VERSION' go/Makefile.common)"
exit 1
