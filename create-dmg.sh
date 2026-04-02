#!/bin/bash

# Create DMG for macOS distribution
# Usage: ./create-dmg.sh <app_path> <output_dmg_path>

set -e

APP_PATH="${1:-.build/release/XYZMonitor}"
OUTPUT_DMG="${2:-XYZMonitor.dmg}"

if [ ! -d "$APP_PATH" ] && [ ! -f "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

echo "Creating DMG distribution..."

# Use hdiutil to create DMG
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cp -R "$APP_PATH" "$TEMP_DIR/"

hdiutil create \
    -volname "XYZ Monitor" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO \
    "$OUTPUT_DMG"

echo "✓ DMG created: $OUTPUT_DMG"
