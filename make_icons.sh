#!/usr/bin/env bash
# make_icons.sh — generate a macOS AppIcon.appiconset from a 1024×1024 PNG
#
# Usage:
#   chmod +x make_icons.sh
#   ./make_icons.sh path/to/icon-1024.png
#
# Output:
#   AppIcon.appiconset/ — drop this folder into your Xcode Assets.xcassets
#                         replacing the existing AppIcon.appiconset

set -e

SOURCE="$1"

if [[ -z "$SOURCE" || ! -f "$SOURCE" ]]; then
    echo "Usage: $0 path/to/icon-1024.png"
    exit 1
fi

# Verify source is at least 1024×1024
W=$(sips -g pixelWidth  "$SOURCE" | awk '/pixelWidth/  {print $2}')
H=$(sips -g pixelHeight "$SOURCE" | awk '/pixelHeight/ {print $2}')
if [[ "$W" -lt 1024 || "$H" -lt 1024 ]]; then
    echo "Error: source image must be at least 1024×1024 (got ${W}×${H})"
    exit 1
fi

OUT="AppIcon.appiconset"
rm -rf "$OUT" && mkdir "$OUT"

# macOS required sizes: name → pixels
declare -a SIZES=(
    "icon_16x16.png:16"
    "icon_16x16@2x.png:32"
    "icon_32x32.png:32"
    "icon_32x32@2x.png:64"
    "icon_128x128.png:128"
    "icon_128x128@2x.png:256"
    "icon_256x256.png:256"
    "icon_256x256@2x.png:512"
    "icon_512x512.png:512"
    "icon_512x512@2x.png:1024"
)

for ENTRY in "${SIZES[@]}"; do
    FILENAME="${ENTRY%%:*}"
    PX="${ENTRY##*:}"
    echo "  generating ${FILENAME} (${PX}×${PX})"
    sips -z "$PX" "$PX" "$SOURCE" --out "$OUT/$FILENAME" > /dev/null
done

# Write Contents.json so Xcode recognises the set
cat > "$OUT/Contents.json" <<'JSON'
{
  "images": [
    { "filename": "icon_16x16.png",      "idiom": "mac", "scale": "1x", "size": "16x16"   },
    { "filename": "icon_16x16@2x.png",   "idiom": "mac", "scale": "2x", "size": "16x16"   },
    { "filename": "icon_32x32.png",      "idiom": "mac", "scale": "1x", "size": "32x32"   },
    { "filename": "icon_32x32@2x.png",   "idiom": "mac", "scale": "2x", "size": "32x32"   },
    { "filename": "icon_128x128.png",    "idiom": "mac", "scale": "1x", "size": "128x128" },
    { "filename": "icon_128x128@2x.png", "idiom": "mac", "scale": "2x", "size": "128x128" },
    { "filename": "icon_256x256.png",    "idiom": "mac", "scale": "1x", "size": "256x256" },
    { "filename": "icon_256x256@2x.png", "idiom": "mac", "scale": "2x", "size": "256x256" },
    { "filename": "icon_512x512.png",    "idiom": "mac", "scale": "1x", "size": "512x512" },
    { "filename": "icon_512x512@2x.png", "idiom": "mac", "scale": "2x", "size": "512x512" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
JSON

echo ""
echo "Done — AppIcon.appiconset/ is ready."
echo ""
echo "Next steps:"
echo "  1. In Finder, open your Xcode project folder"
echo "  2. Navigate to PressureMonitor/Assets.xcassets/"
echo "  3. Replace the existing AppIcon.appiconset with the new one"
echo "  4. Rebuild in Xcode (⌘R)"
