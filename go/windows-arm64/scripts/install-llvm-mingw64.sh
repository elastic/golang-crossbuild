#!/usr/bin/env bash
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
    src=$(echo "$line" | awk '{print $1}')
    src="$base_dir/$src"

    dest=$(echo "$line" | awk '{print $2}')
    dest="$(realpath "$base_dir/$dest")"
    ln -s "$dest" "$src"
done <symlinks.txt

echo ":: Cleanup"
cd ..
rm -rf "$src"
