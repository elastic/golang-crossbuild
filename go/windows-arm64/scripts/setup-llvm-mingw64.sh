#!/usr/bin/env bash
set -e
set -o pipefail

trap 'echo "$0: Error on line $LINENO" >&2' ERR

if [ -z "$LLVM_MINGW64_SRC" ]; then
    echo "Error: LLVM_MINGW64_SRC is undefined"
    env
    exit 1
fi

if [ -z "$LLVM_MINGW_UBUNTU_REL" ]; then
    echo "Error: LLVM_MINGW_UBUNTU_REL is undefined"
    env
    exit 1
fi

if [ -z "$LLVM_MINGW64_VER" ]; then
    echo "Error: LLVM_MINGW64_VER is undefined"
    env
    exit 1
fi

apt update && apt install xz-utils --yes

case "$(uname -m)" in
aarch64 | arm64)
    m_arch="aarch64"
    ;;
x86_64 | amd64)
    m_arch="x86_64"
    ;;
*)
    echo "Error: unsupported architecture $(uname -m)"
    exit 1
    ;;
esac

pkg_dir="llvm-mingw-$LLVM_MINGW64_VER-ucrt-ubuntu-$LLVM_MINGW_UBUNTU_REL-$m_arch"
pkg_file="$pkg_dir.tar.xz"
src_url="$LLVM_MINGW64_SRC/$LLVM_MINGW64_VER/$pkg_file"
echo ":: Downloading $src_url ..."
wget "$src_url"
# wget -q --spider "$src_url"

if [ ! -f "$pkg_file" ]; then
    echo "Error: can't find downloaded file $pkg_file"
    ls -la
    exit 1
fi

echo ":: Extracting file..."
tar -xf "$pkg_file"
rm "$pkg_file"

echo ":: Preparing file list..."
mv "$pkg_dir" llvm-mingw64
cd llvm-mingw64

# Keep llvm-mingw64 only for arm target to avoid conflict with gcc-mingw64
rm bin/x86_64* bin/i686*
rm -rf i686-w64-mingw32 x86_64-w64-mingw32

# Backup symlinks
find . -type l | while read -r symlink; do
    src="${symlink/.\//}"
    dst="$(dirname "$src")/$(readlink "$symlink")"
    echo "$src $dst" >>symlinks.txt
    rm "$symlink"
done
