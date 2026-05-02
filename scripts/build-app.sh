#!/bin/bash
# Script to build ClosedDisplay as a proper macOS .app bundle
# This enables full menu bar functionality including tooltips and menu interactions

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="ClosedDisplay"
APP_BUNDLE="${APP_NAME}.app"
VERSION="${1:-1.0.0}"

echo "Building ${APP_NAME}.app bundle..."
echo ""

# Build release binary first
echo "Building release binary..."
swift build -c release
echo "✓ Binary built"

# Clean up any existing app bundle
rm -rf "${APP_BUNDLE}"

# Create app bundle structure
echo ""
echo "Creating app bundle structure..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
echo "Copying binary..."
cp .build/release/ClosedDisplay "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
echo "✓ Binary copied"

# Create Info.plist
echo ""
echo "Creating Info.plist..."
cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.closeddisplay.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF
echo "✓ Info.plist created"

# Compile asset catalog (AppIcon)
echo ""
echo "Compiling asset catalog..."
ACTOOL=$(xcrun -f actool)
ACCATALOG="${SCRIPT_DIR}/../src/Assets.xcassets"
"$ACTOOL" \
  --output-format human-readable-text \
  --notices --warnings \
  --export-dependency-info /tmp/actool-deps.txt \
  --output-partial-info-plist /tmp/actool-partial.plist \
  --app-icon AppIcon \
  --compress-pngs \
  --enable-on-demand-resources NO \
  --platform macosx \
  --minimum-deployment-target 14.0 \
  --target-device mac \
  --compile "${APP_BUNDLE}/Contents/Resources" \
  "$ACCATALOG" 2>&1 | grep -v '^$' || true
echo "✓ Asset catalog compiled"

echo ""
echo "========================================="
echo "✓ ${APP_NAME}.app bundle created!"
echo "========================================="
echo ""
echo "To run the app:"
echo "  open ${APP_BUNDLE}"
echo ""
echo "To install to Applications folder:"
echo "  cp -R ${APP_BUNDLE} /Applications/"
echo ""
echo "To test:"
echo "  open ${APP_BUNDLE}"
echo "  Then check the menu bar for the icon"
echo ""
