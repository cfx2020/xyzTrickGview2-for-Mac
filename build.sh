#!/bin/bash

# Build script for XYZ Monitor macOS application
# Usage: ./build.sh [debug|release]

set -e

BUILD_TYPE=${1:-release}
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BUILD_DIR="$PROJECT_DIR/build"
DIST_DIR="$PROJECT_DIR/dist"

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
    
    # The executable will be in .build/release/
    if [ -f ".build/release/XYZMonitor" ]; then
        cp ".build/release/XYZMonitor" "$DIST_DIR/"
        echo "✓ Executable copied to dist/"
    fi
fi

echo ""
echo "=========================================="
echo "Build complete!"
echo "=========================================="
