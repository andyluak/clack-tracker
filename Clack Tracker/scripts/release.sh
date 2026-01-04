#!/bin/bash
set -e

# Clack Tracker Release Script
# Usage: ./scripts/release.sh [version]
# Example: ./scripts/release.sh 1.1

cd "$(dirname "$0")/.."

APP_NAME="Clack Tracker"
SCHEME="Clack Tracker"
BUILD_DIR="build"
EXPORT_DIR="$BUILD_DIR/export"

# Get version from argument or prompt
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "Usage: ./scripts/release.sh <version>"
    echo "Example: ./scripts/release.sh 1.1"
    exit 1
fi

DMG_NAME="ClackTracker-${VERSION}.dmg"

echo "========================================"
echo "Building $APP_NAME v$VERSION"
echo "========================================"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Archive
echo ""
echo "Step 1/4: Archiving..."
xcodebuild -scheme "$SCHEME" -configuration Release \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    archive \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$VERSION"

# Export (Developer ID signed)
echo ""
echo "Step 2/4: Exporting..."
xcodebuild -exportArchive \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist ExportOptions.plist

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "Error: create-dmg not found. Install with: brew install create-dmg"
    exit 1
fi

# Create DMG
echo ""
echo "Step 3/4: Creating DMG..."
create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 150 190 \
    --app-drop-link 450 185 \
    "$BUILD_DIR/$DMG_NAME" \
    "$EXPORT_DIR/$APP_NAME.app"

# Notarize
echo ""
echo "Step 4/4: Notarizing..."
xcrun notarytool submit "$BUILD_DIR/$DMG_NAME" \
    --keychain-profile "ClackTracker" \
    --wait

# Staple the ticket
xcrun stapler staple "$BUILD_DIR/$DMG_NAME"

echo ""
echo "========================================"
echo "SUCCESS! DMG ready at: $BUILD_DIR/$DMG_NAME"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Sign the DMG for Sparkle:"
echo "   ./Sparkle/bin/sign_update $BUILD_DIR/$DMG_NAME"
echo ""
echo "2. Update appcast.xml with:"
echo "   - Version: $VERSION"
echo "   - DMG URL: https://YOUR_R2_BUCKET.r2.dev/$DMG_NAME"
echo "   - EdDSA signature from step 1"
echo "   - File size: $(stat -f%z "$BUILD_DIR/$DMG_NAME") bytes"
echo ""
echo "3. Upload to R2:"
echo "   - $BUILD_DIR/$DMG_NAME"
echo "   - appcast.xml"
