#!/bin/bash
# Script to create a DMG package for ClosedDisplay

set -e

VERSION="${1:-1.0.0}"
PACKAGE_NAME="ClosedDisplay-v$VERSION"
DMG_NAME="${PACKAGE_NAME}-arm64.dmg"
VOLUME_NAME="ClosedDisplay"
STAGING_DIR="dmg_staging"

echo "Creating DMG package: $DMG_NAME"
echo ""

# Check if binary exists
if [ ! -f ".build/release/ClosedDisplay" ]; then
    echo "Error: Binary not found. Building release binary..."
    swift build -c release
fi

# Clean up old staging directory
echo "Preparing staging directory..."
rm -rf "$STAGING_DIR" 2>/dev/null || true
mkdir -p "$STAGING_DIR"

# Copy files to staging directory
echo "Copying files..."
cp .build/release/ClosedDisplay "$STAGING_DIR/"
cp install.sh "$STAGING_DIR/"
cp uninstall.sh "$STAGING_DIR/"
cp com.closeddisplay.app.plist "$STAGING_DIR/"
cp README.md "$STAGING_DIR/"

# Make scripts executable
chmod +x "$STAGING_DIR/install.sh"
chmod +x "$STAGING_DIR/uninstall.sh"

# Create a simple installation instructions file
cat > "$STAGING_DIR/INSTALL_INSTRUCTIONS.txt" << 'EOF'
ClosedDisplay Installation Instructions
========================================

QUICK INSTALL (Recommended):
   Double-click "install.sh" to run the installation script
   (You may need to right-click → Open if prompted about unidentified developer)

MANUAL INSTALL:
   1. Open Terminal
   2. Navigate to this folder: cd /Volumes/ClosedDisplay
   3. Run: ./install.sh

WHAT THE INSTALLER DOES:
   • Copies ClosedDisplay to /usr/local/bin
   • Configures sudo permissions for pmset
   • Makes the app ready to use

USAGE:
   After installation, run in Terminal: ClosedDisplay
   Press Ctrl+C to stop

OPTIONAL - AUTO-START ON LOGIN:
   • Copy com.closeddisplay.app.plist to ~/Library/LaunchAgents/
   • Run: launchctl load ~/Library/LaunchAgents/com.closeddisplay.app.plist

UNINSTALL:
   Run: ./uninstall.sh

For more information, see README.md
EOF

echo "✓ Files prepared"

# Remove old DMG if it exists
rm -f "$DMG_NAME" 2>/dev/null || true

# Create temporary DMG
echo ""
echo "Creating DMG image..."
TEMP_DMG="temp_${DMG_NAME}"
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDRW \
    "$TEMP_DMG"

# Mount the temporary DMG
echo "Mounting DMG for customization..."
MOUNT_POINT=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | grep "/Volumes/$VOLUME_NAME" | awk '{print $3}')

if [ -z "$MOUNT_POINT" ]; then
    echo "Error: Could not mount DMG"
    exit 1
fi

# Set DMG window properties (basic)
echo "Configuring DMG appearance..."

# Create a symbolic link to Applications (optional, if you want drag-to-install style)
# ln -s /Applications "$MOUNT_POINT/Applications"

# Set custom icon positions and window size using AppleScript
osascript <<EOD 2>/dev/null || true
tell application "Finder"
    try
        tell disk "$VOLUME_NAME"
            open
            set current view of container window to list view
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set the bounds of container window to {100, 100, 700, 500}
            
            close
            open
            update without registering applications
            delay 1
        end tell
    end try
end tell
EOD

sleep 1

# Unmount the DMG
echo "Finalizing DMG..."
hdiutil detach "$MOUNT_POINT" -force -quiet
sleep 2  # Wait for unmount to complete

# Convert to compressed read-only DMG
echo "Compressing DMG..."
hdiutil convert "$TEMP_DMG" \
    -format UDZO \
    -o "$DMG_NAME"

# Clean up
rm -f "$TEMP_DMG"
rm -rf "$STAGING_DIR"

# Calculate checksum
echo ""
echo "Calculating SHA256 checksum..."
if command -v shasum &> /dev/null; then
    shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"
    echo "✓ Checksum saved to: ${DMG_NAME}.sha256"
    echo ""
    cat "${DMG_NAME}.sha256"
fi

# Get file size
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
echo "User installation steps:"
echo "  1. Download and open $DMG_NAME"
echo "  2. Double-click 'install.sh' (or right-click → Open)"
echo "  3. Follow the installation prompts"
echo ""
echo "To distribute:"
echo "  Upload $DMG_NAME to GitHub Releases or your website"
echo ""
