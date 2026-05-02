#!/bin/bash
# Script to create a DMG package for ClosedDisplay (.app bundle)

set -e

VERSION="${1:-1.0.0}"
APP_NAME="ClosedDisplay"
APP_BUNDLE="${APP_NAME}.app"
PACKAGE_NAME="ClosedDisplay-v$VERSION"
DMG_NAME="${PACKAGE_NAME}-arm64.dmg"
VOLUME_NAME="ClosedDisplay-v$VERSION"
STAGING_DIR="dmg_staging"

echo "Creating DMG package: $DMG_NAME"
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

# Clean up old staging directory
echo ""
echo "Preparing DMG staging directory..."
rm -rf "$STAGING_DIR" 2>/dev/null || true
mkdir -p "$STAGING_DIR"

# Copy .app bundle and supporting files to staging directory
echo "Copying files..."
cp -R "${APP_BUNDLE}" "$STAGING_DIR/"
cp README.md "$STAGING_DIR/"

# Create a symlink to /Applications for drag-and-drop install
ln -s /Applications "$STAGING_DIR/Applications"

# Create install instructions
cat > "$STAGING_DIR/INSTALL.txt" << 'EOF'
ClosedDisplay Installation
===========================

DRAG & DROP INSTALL:
   Drag ClosedDisplay.app to the Applications folder shortcut.

LAUNCH:
   Open ClosedDisplay from your Applications folder.
   The menu bar icon will appear automatically.

AUTO-START ON LOGIN:
   System Settings → General → Login Items → Add ClosedDisplay.app

UNINSTALL:
   Move ClosedDisplay.app from /Applications to Trash.
   Remove from Login Items if added.

For more information, see README.md
EOF

echo "✓ Files prepared"

# Remove old DMG if it exists
rm -f "$DMG_NAME" 2>/dev/null || true

# Create DMG directly from staging folder
echo ""
echo "Creating DMG image..."
TEMP_DMG="temp_${DMG_NAME}"
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDRW \
    "$TEMP_DMG"

# Mount the temporary DMG
echo "Mounting DMG for customization..."
hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" > /dev/null
MOUNT_POINT="/Volumes/${VOLUME_NAME}"

if [ ! -d "$MOUNT_POINT" ]; then
    echo "Error: Could not mount DMG at $MOUNT_POINT"
    exit 1
fi

# Configure DMG window appearance (drag-to-install layout)
echo "Configuring DMG appearance..."
osascript <<EOD 2>/dev/null || true
tell application "Finder"
    try
        tell disk "${VOLUME_NAME}"
            open
            set current view of container window to icon view
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set the bounds of container window to {100, 100, 700, 450}
            set viewOptions to the icon view options of container window
            set arrangement of viewOptions to not arranged
            set icon size of viewOptions to 128
            set position of item "ClosedDisplay.app" of container window to {180, 200}
            set position of item "Applications" of container window to {500, 200}
            set position of item "INSTALL.txt" of container window to {340, 350}
            close
            open
            update without registering applications
            delay 2
        end tell
    end try
end tell
EOD

sleep 1

# Unmount the DMG
echo "Finalizing DMG..."
hdiutil detach "$MOUNT_POINT" -force -quiet
sleep 2

# Convert to compressed read-only DMG
echo "Compressing DMG..."
hdiutil convert "$TEMP_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_NAME"

# Clean up
rm -f "$TEMP_DMG"
rm -rf "$STAGING_DIR"
rm -rf "${APP_BUNDLE}"

# Calculate checksum
echo ""
echo "Calculating SHA256 checksum..."
if command -v shasum &> /dev/null; then
    shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"
    echo "✓ Checksum saved to: ${DMG_NAME}.sha256"
    echo ""
    cat "${DMG_NAME}.sha256"
fi

DMG_SIZE=$(du -h "$DMG_NAME" | cut -f1)

echo ""
echo "========================================="
echo "DMG created successfully!"
echo "========================================="
echo ""
echo "File created:"
echo "  - $DMG_NAME ($DMG_SIZE)"
echo "  - ${DMG_NAME}.sha256"
echo ""
echo "User installation:"
echo "  1. Open $DMG_NAME"
echo "  2. Drag ClosedDisplay.app to Applications"
echo "  3. Launch from Applications or Spotlight"
echo ""
echo "To distribute:"
echo "  Upload $DMG_NAME to GitHub Releases"
echo ""
