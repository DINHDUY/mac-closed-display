#!/bin/bash
# Script to create a release package for ClosedDisplay (.app bundle)

set -e

VERSION="${1:-1.0.0}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="ClosedDisplay"
APP_BUNDLE="${APP_NAME}.app"
PACKAGE_NAME="ClosedDisplay-v$VERSION"
RELEASE_DIR="$PACKAGE_NAME"

echo "Creating release package: $PACKAGE_NAME"
echo ""

# Build .app bundle only if not already present (e.g. pre-built in CI)
if [ -f "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" ]; then
    echo "✓ Using existing app bundle: ${APP_BUNDLE}"
else
    # Build release binary
    echo "Building release binary..."
    swift build -c release
    echo "✓ Binary built"

    # Build .app bundle
    echo ""
    echo "Building app bundle..."
    rm -rf "${APP_BUNDLE}"
    mkdir -p "${APP_BUNDLE}/Contents/MacOS"
    mkdir -p "${APP_BUNDLE}/Contents/Resources"
    cp .build/release/ClosedDisplay "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
    chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

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
</dict>
</plist>
EOF
    echo "✓ App bundle created"
fi

# Create release directory
echo ""
echo "Creating release directory..."
rm -rf "$RELEASE_DIR" 2>/dev/null || true
mkdir -p "$RELEASE_DIR"

# Copy files
echo "Copying files..."
cp -R "${APP_BUNDLE}" "$RELEASE_DIR/"
cp "${SCRIPT_DIR}/install.sh" "$RELEASE_DIR/"
cp "${SCRIPT_DIR}/uninstall.sh" "$RELEASE_DIR/"
cp com.closeddisplay.app.plist "$RELEASE_DIR/"
cp README.md "$RELEASE_DIR/"
cp RELEASE.md "$RELEASE_DIR/INSTALL.md"

# Make scripts executable
chmod +x "$RELEASE_DIR/install.sh"
chmod +x "$RELEASE_DIR/uninstall.sh"

echo "✓ Files copied"

# Create archive
echo ""
echo "Creating archive..."
tar -czf "${PACKAGE_NAME}-arm64.tar.gz" "$RELEASE_DIR/"
echo "✓ Archive created: ${PACKAGE_NAME}-arm64.tar.gz"

# Calculate checksum
echo ""
echo "Calculating SHA256 checksum..."
if command -v shasum &> /dev/null; then
    shasum -a 256 "${PACKAGE_NAME}-arm64.tar.gz" > "${PACKAGE_NAME}-arm64.tar.gz.sha256"
    echo "✓ Checksum saved to: ${PACKAGE_NAME}-arm64.tar.gz.sha256"
    echo ""
    cat "${PACKAGE_NAME}-arm64.tar.gz.sha256"
fi

echo ""
echo "========================================="
echo "Release package created successfully!"
echo "========================================="
echo ""
echo "Files created:"
echo "  - ${PACKAGE_NAME}-arm64.tar.gz"
echo "  - ${PACKAGE_NAME}-arm64.tar.gz.sha256"
echo ""
echo "Package contents:"
ls -lh "$RELEASE_DIR"
echo ""
echo "To also create a DMG:"
echo "  ./scripts/create-dmg.sh $VERSION"
echo ""
echo "To distribute:"
echo "  1. Upload ${PACKAGE_NAME}-arm64.tar.gz to GitHub Releases"
echo "  2. Include SHA256 checksum in release notes"
echo "  3. Users: tar -xzf ${PACKAGE_NAME}-arm64.tar.gz && cp -R ${RELEASE_DIR}/ClosedDisplay.app /Applications/"
echo ""
