#!/bin/bash
# ClosedDisplay Uninstallation Script

set -e

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="ClosedDisplay"
SUDOERS_FILE="/private/etc/sudoers.d/closeddisplay"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.closeddisplay.app.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "========================================="
echo "  ClosedDisplay Uninstallation"
echo "========================================="
echo ""

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script requires administrator privileges"
    sudo -v
fi

# Stop LaunchAgent if running
if [ -f "$LAUNCH_AGENT" ]; then
    echo "Stopping LaunchAgent..."
    launchctl unload "$LAUNCH_AGENT" 2>/dev/null || true
    rm "$LAUNCH_AGENT"
    echo -e "${GREEN}✓${NC} LaunchAgent removed"
fi

# Remove binary
if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
    echo "Removing binary..."
    sudo rm "$INSTALL_DIR/$BINARY_NAME"
    echo -e "${GREEN}✓${NC} Binary removed"
fi

# Remove sudoers configuration
if [ -f "$SUDOERS_FILE" ]; then
    echo "Removing sudoers configuration..."
    sudo rm "$SUDOERS_FILE"
    echo -e "${GREEN}✓${NC} Sudoers configuration removed"
fi

echo ""
echo "========================================="
echo -e "${GREEN}Uninstallation complete!${NC}"
echo "========================================="
echo ""
