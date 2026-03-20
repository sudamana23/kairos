#!/bin/bash
set -e

APP_NAME="Kairos"
VERSION=$(date +"%Y.%m.%d")
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
OUTPUT_DIR="$HOME/Desktop"

echo "🔍 Finding ${APP_NAME}.app in DerivedData..."

# Find most recently built Kairos.app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${APP_NAME}.app" \
  -not -path "*/Index.noindex/*" \
  2>/dev/null | sort -t/ -k1,1 | tail -1)

if [ -z "$APP_PATH" ]; then
  echo "❌ Could not find ${APP_NAME}.app in DerivedData."
  echo "   Build the app in Xcode first (⌘B), then re-run this script."
  exit 1
fi

echo "✅ Found: $APP_PATH"

# Staging folder
STAGING=$(mktemp -d)
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "📦 Creating DMG..."
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$OUTPUT_DIR/$DMG_NAME"

rm -rf "$STAGING"

echo ""
echo "✅ Done: $OUTPUT_DIR/$DMG_NAME"
echo "   Drag Kairos.app into Applications to install."
