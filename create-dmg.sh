#!/bin/bash

# Create DMG for macOS distribution
# Usage: ./create-dmg.sh [app_bundle_path] [output_dmg_path]

set -e

APP_PATH="${1:-dist/XYZ Monitor.app}"
OUTPUT_DMG="${2:-XYZMonitor.dmg}"
APP_NAME="$(basename "$APP_PATH")"
VOLUME_NAME="XYZ Monitor"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not found at $APP_PATH"
    echo "Hint: run ./build.sh release first"
    exit 1
fi

if [[ "$APP_PATH" != *.app ]]; then
    echo "Error: $APP_PATH is not a .app bundle"
    exit 1
fi

echo "Creating DMG distribution..."

TEMP_DIR=$(mktemp -d)
cleanup() {
    hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || hdiutil detach -force "$MOUNT_DIR" >/dev/null 2>&1 || true
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

STAGING_DIR="$TEMP_DIR/staging"
MOUNT_DIR="$TEMP_DIR/mount"
RW_DMG="$TEMP_DIR/XYZMonitor-rw.dmg"

mkdir -p "$STAGING_DIR" "$MOUNT_DIR"

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

APP_ICON_SOURCE="$APP_PATH/Contents/Resources/XYZMonitor.icns"
if [ -f "$APP_ICON_SOURCE" ]; then
    cp "$APP_ICON_SOURCE" "$STAGING_DIR/.VolumeIcon.icns"
    /usr/bin/SetFile -a C "$STAGING_DIR" || true
    /usr/bin/SetFile -a V "$STAGING_DIR/.VolumeIcon.icns" || true
fi

hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDRW \
    "$RW_DMG"

hdiutil attach "$RW_DMG" -mountpoint "$MOUNT_DIR" -nobrowse -noverify >/dev/null

if [ -z "${CI:-}" ]; then
osascript <<EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        delay 1.5
        tell container window
            set current view to icon view
            set toolbar visible to false
            set statusbar visible to false
            set bounds to {120, 120, 760, 480}

            set viewOptions to the icon view options
            try
                set arrangement of viewOptions to not arranged
            end try
            try
                set icon size of viewOptions to 144
            end try
            try
                set text size of viewOptions to 16
            end try

            delay 0.5
            try
                set position of item "$APP_NAME" to {170, 220}
            end try
            try
                set position of item "Applications" to {500, 220}
            end try
        end tell

        update without registering applications
        delay 1.5
        close
        open
    end tell
end tell
EOF
else
    echo "CI environment detected, skipping Finder layout customization"
fi

sync
hdiutil detach "$MOUNT_DIR" >/dev/null

hdiutil convert "$RW_DMG" -ov -format UDZO -imagekey zlib-level=9 -o "$OUTPUT_DMG"

echo "✓ DMG created: $OUTPUT_DMG"
