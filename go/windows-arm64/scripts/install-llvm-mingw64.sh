#!/usr/bin/env bash
#
# Copied from: https://github.com/x1unix/docker-go-mingw/tree/20dfaff6efe8fe3a4ff588a58ccb31646cd2fd60
#
set -e
set -o pipefail

trap 'echo "$0: Error on line $LINENO" >&2' ERR

src="$1"
if [ -z "$src" ]; then
    echo "Error: missing source dir"
    exit 1
fi

base_dir='/usr'

echo ":: Installing llvm-mingw64..."
echo "Source dir: $src"

cd "$src" || exit 1
find . -mindepth 1 -maxdepth 1 -type d ! -name . | while read -r subdir; do
    dst_dir="$(basename "$subdir")"

    case "$dst_dir" in
    bin)
        perm=755
        ;;
    *)
        perm=644
        ;;
    esac

    find "$subdir" -type f | while read -r file; do
        dst="$base_dir/${file/.\//}"
        mkdir -p "$(dirname "$dst")"
        install -m $perm "$file" "$dst"
    done
done

echo ":: Restoring symlinks..."
while IFS= read -r line; do
    link_src=$(echo "$line" | awk '{print $1}')
    link_src="$base_dir/$link_src"

    link_dest=$(echo "$line" | awk '{print $2}')
    link_dest="$(realpath "$base_dir/$link_dest")"
    ln -s "$link_dest" "$link_src"
done <symlinks.txt

echo ":: Creating symlink for aarch64-w64-mingw32 headers..."
if [ ! -d "$base_dir/aarch64-w64-mingw32/include" ]; then
    if [ -d "$base_dir/generic-w64-mingw32/include" ]; then
        ln -s "$base_dir/generic-w64-mingw32/include" "$base_dir/aarch64-w64-mingw32/include"
        echo "Created symlink: $base_dir/aarch64-w64-mingw32/include -> $base_dir/generic-w64-mingw32/include"
    else
        echo "Warning: $base_dir/generic-w64-mingw32/include does not exist"
    fi
else
    echo "Include directory already exists, skipping symlink creation"
fi

echo ":: Cleanup"
cd ..
rm -rf "$src"
