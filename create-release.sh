#!/bin/bash
# Script to create a release package for ClosedDisplay

set -e

VERSION="${1:-1.0.0}"
PACKAGE_NAME="ClosedDisplay-v$VERSION"
RELEASE_DIR="$PACKAGE_NAME"

echo "Creating release package: $PACKAGE_NAME"
echo ""

# Check if binary exists
if [ ! -f ".build/release/ClosedDisplay" ]; then
    echo "Error: Binary not found. Building release binary..."
    swift build -c release
fi

# Create release directory
echo "Creating release directory..."
rm -rf "$RELEASE_DIR" 2>/dev/null || true
mkdir -p "$RELEASE_DIR"

# Copy files
echo "Copying files..."
cp .build/release/ClosedDisplay "$RELEASE_DIR/"
cp install.sh "$RELEASE_DIR/"
cp uninstall.sh "$RELEASE_DIR/"
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
echo "  ./create-dmg.sh $VERSION"
echo ""
echo "To distribute:"
echo "  1. Upload ${PACKAGE_NAME}-arm64.tar.gz to GitHub Releases"
echo "  2. Include SHA256 checksum in release notes"
echo "  3. Users run: tar -xzf ${PACKAGE_NAME}-arm64.tar.gz && cd $RELEASE_DIR && ./install.sh"
echo ""
