#!/bin/bash
# Script to create both TAR.GZ and DMG release packages

set -e

VERSION="${1:-1.0.0}"

echo "========================================"
echo "Creating Release Packages for v$VERSION"
echo "========================================"
echo ""

# Create tar.gz package
echo "1. Creating TAR.GZ package..."
echo "----------------------------------------"
./create-release.sh "$VERSION"

echo ""
echo ""

# Create DMG package
echo "2. Creating DMG package..."
echo "----------------------------------------"
./create-dmg.sh "$VERSION"

echo ""
echo ""
echo "========================================"
echo "All Release Packages Created!"
echo "========================================"
echo ""
echo "Release files:"
ls -lh ClosedDisplay-v${VERSION}* 2>/dev/null | grep -v "^d"
echo ""
echo "Distribution options:"
echo "  • DMG (recommended for Mac users): ClosedDisplay-v${VERSION}-arm64.dmg"
echo "  • TAR.GZ (for command-line users):  ClosedDisplay-v${VERSION}-arm64.tar.gz"
echo ""
echo "Both formats include:"
echo "  ✓ Pre-compiled binary"
echo "  ✓ Automated installation script"
echo "  ✓ Uninstallation script"
echo "  ✓ Documentation"
echo "  ✓ SHA256 checksums"
echo ""
