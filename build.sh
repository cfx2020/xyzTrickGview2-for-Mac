#!/bin/bash

# Build script for XYZ Monitor macOS application
# Usage: ./build.sh [debug|release]

set -e

BUILD_TYPE=${1:-release}
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BUILD_DIR="$PROJECT_DIR/build"
DIST_DIR="$PROJECT_DIR/dist"
APP_NAME="XYZ Monitor"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
INFO_PLIST_SOURCE="$PROJECT_DIR/XYZMonitor/Resources/Info.plist"
ICON_GENERATOR="$PROJECT_DIR/build-support/make_app_icon.swift"
APP_ICON_SOURCE="$BUILD_DIR/XYZMonitor.icns"

echo "=========================================="
echo "XYZ Monitor macOS Build Script"
echo "=========================================="
echo "Build Type: $BUILD_TYPE"
echo "Project Dir: $PROJECT_DIR"
echo ""

# Clean previous builds if release
if [ "$BUILD_TYPE" = "release" ]; then
    echo "Cleaning previous builds..."
    rm -rf "$BUILD_DIR" "$DIST_DIR"
fi

# Create directories
mkdir -p "$BUILD_DIR" "$DIST_DIR"

echo "Building with Swift..."

if [ "$BUILD_TYPE" = "debug" ]; then
    swift build -c debug -Xswiftc -suppress-warnings
else
    swift build -c release -Xswiftc -suppress-warnings
fi

echo ""
echo "Build completed successfully!"
echo ""

# Copy to dist
if [ "$BUILD_TYPE" = "release" ]; then
    echo "Preparing distribution..."

    if [ -f "$ICON_GENERATOR" ]; then
        echo "Generating app icon..."
        swift "$ICON_GENERATOR" "$APP_ICON_SOURCE"
        echo "✓ App icon created: $APP_ICON_SOURCE"
    else
        echo "Warning: icon generator not found at $ICON_GENERATOR"
    fi

    if [ ! -f ".build/release/XYZMonitor" ]; then
        echo "Error: Release executable not found at .build/release/XYZMonitor"
        exit 1
    fi

    # Keep a plain executable for advanced users.
    cp ".build/release/XYZMonitor" "$DIST_DIR/"
    chmod +x "$DIST_DIR/XYZMonitor"
    echo "✓ Executable copied to dist/XYZMonitor"

    # Create a standard macOS .app bundle for GUI distribution.
    rm -rf "$APP_BUNDLE"
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"

    cp ".build/release/XYZMonitor" "$APP_BUNDLE/Contents/MacOS/XYZMonitor"
    chmod +x "$APP_BUNDLE/Contents/MacOS/XYZMonitor"

    if [ -f "$APP_ICON_SOURCE" ]; then
        cp "$APP_ICON_SOURCE" "$APP_BUNDLE/Contents/Resources/XYZMonitor.icns"
    fi

    if [ -f "$INFO_PLIST_SOURCE" ]; then
        mkdir -p "$APP_BUNDLE/Contents"
        cp "$INFO_PLIST_SOURCE" "$APP_BUNDLE/Contents/Info.plist"
    else
        echo "Warning: Info.plist not found at $INFO_PLIST_SOURCE"
    fi

    echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"
    echo "✓ App bundle created: $APP_BUNDLE"
fi

echo ""
echo "=========================================="
echo "Build complete!"
echo "=========================================="
