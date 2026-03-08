#!/bin/bash
# build_release.sh — Build Kairos.app and package as a DMG
# Usage: ./build_release.sh
# Requires: Xcode, xcodegen

set -e

# Check Xcode is selected (not just command line tools)
if ! xcode-select -p 2>/dev/null | grep -q "Xcode.app"; then
    echo "✗ Xcode not selected. Run this first:"
    echo "    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Kairos"
SCHEME="Kairos"
BUILD_DIR="$SCRIPT_DIR/build"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
VERSION=$(grep 'CFBundleShortVersionString' "$SCRIPT_DIR/project.yml" | head -1 | grep -o '"[^"]*"' | tr -d '"')

echo "========================================"
echo "  Building $APP_NAME v$VERSION"
echo "========================================"

# Step 1: Regenerate Xcode project
echo "▶ Generating Xcode project..."
xcodegen generate --quiet

# Step 2: Build Release
echo "▶ Building Release..."

# Build without code signing (for personal/local use).
# To sign for distribution: remove the CODE_SIGN_* overrides and pass -allowProvisioningUpdates.
xcodebuild \
    -project "$SCRIPT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    clean build 2>&1 \
    | grep -E "(error:|Build succeeded|BUILD FAILED)" || true

if [ ! -d "$APP_PATH" ]; then
    echo ""
    echo "✗ Build failed. Full log:"
    xcodebuild \
        -project "$SCRIPT_DIR/$APP_NAME.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration Release \
        -derivedDataPath "$BUILD_DIR" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        build 2>&1 | grep "error:" | head -20
    exit 1
fi

echo "✓ Built: $APP_PATH"

# Step 3: Package as DMG
echo "▶ Creating DMG..."
rm -f "$DMG_PATH"

# Simple DMG from the .app
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$APP_PATH" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "✓ DMG: $DMG_PATH"

# Step 4: Clear icon cache so macOS picks up the new icon
echo "▶ Refreshing icon cache..."
touch "$APP_PATH"
killall Dock 2>/dev/null || true

echo ""
echo "========================================"
echo "  Done!"
echo "  DMG: $DMG_PATH"
echo ""
echo "  To install: open $DMG_PATH"
echo "  To clear macOS icon cache fully, run:"
echo "    sudo rm -rf /Library/Caches/com.apple.iconservices.store"
echo "    sudo find /private/var/folders/ -name com.apple.iconservices -exec rm -rf {} + 2>/dev/null"
echo "    killall Dock && killall Finder"
echo "========================================"

open "$BUILD_DIR"
