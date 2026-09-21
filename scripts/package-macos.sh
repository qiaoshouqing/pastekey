#!/bin/bash
set -euo pipefail

version="${1:?Usage: scripts/package-macos.sh VERSION (for example 0.1.0)}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Version must have the form MAJOR.MINOR.PATCH" >&2
    exit 1
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/pastekey-clang-cache"
export SWIFT_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/pastekey-swift-cache"

for architecture in arm64 x86_64; do
    swift build --disable-sandbox -c release --triple "${architecture}-apple-macosx13.0"
done

output="$root/dist"
app="$output/PasteKey.app"
iconset="$output/PasteKey.iconset"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" "$iconset"
cp Packaging/Info.plist "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $version" "$app/Contents/Info.plist"

lipo -create \
    ".build/arm64-apple-macosx/release/PasteKey" \
    ".build/x86_64-apple-macosx/release/PasteKey" \
    -output "$app/Contents/MacOS/PasteKey"
chmod 755 "$app/Contents/MacOS/PasteKey"

for size in 16 32 128 256 512; do
    sips -s format png -z "$size" "$size" assets/icon.png \
        --out "$iconset/icon_${size}x${size}.png" >/dev/null
done
for size in 16 32 128 256 512; do
    doubled=$((size * 2))
    sips -s format png -z "$doubled" "$doubled" assets/icon.png \
        --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
if ! iconutil -c icns "$iconset" -o "$app/Contents/Resources/PasteKey.icns" 2>/dev/null; then
    echo "iconutil failed; using Pillow to create the app icon" >&2
    python3 -c 'from PIL import Image; import sys; Image.open(sys.argv[1]).save(sys.argv[2], format="ICNS")' \
        assets/icon.png "$app/Contents/Resources/PasteKey.icns"
fi
rm -r "$iconset"

codesign --force --sign - "$app"
archive="$output/PasteKey-${version}-macOS-universal.zip"
rm -f "$archive"
ditto -c -k --sequesterRsrc --keepParent "$app" "$archive"
shasum -a 256 "$archive"
