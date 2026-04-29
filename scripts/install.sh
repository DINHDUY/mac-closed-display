#!/bin/bash
# ClosedDisplay Installation Script
# Installs the ClosedDisplay utility for macOS

set -e

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="ClosedDisplay"
SUDOERS_FILE="/private/etc/sudoers.d/closeddisplay"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "  ClosedDisplay Installation"
echo "========================================="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script is for macOS only${NC}"
    exit 1
fi

# Check if running on Apple Silicon
if [[ $(uname -m) != "arm64" ]]; then
    echo -e "${YELLOW}Warning: This utility is designed for Apple Silicon Macs${NC}"
    echo "It may not work correctly on Intel Macs"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if binary exists
if [ ! -f ".build/release/$BINARY_NAME" ]; then
    echo -e "${RED}Error: Binary not found. Please run 'swift build -c release' first${NC}"
    exit 1
fi

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script requires administrator privileges${NC}"
    echo "Please enter your password when prompted"
    sudo -v
fi

echo -e "${GREEN}✓${NC} Checking prerequisites..."

# Install app bundle or binary
echo ""
APP_BUNDLE="${BINARY_NAME}.app"
if [ -d "$APP_BUNDLE" ]; then
    echo "Installing app bundle to /Applications..."
    sudo cp -R "$APP_BUNDLE" /Applications/
    echo -e "${GREEN}✓${NC} App bundle installed to /Applications/${APP_BUNDLE}"
else
    echo "Installing binary to $INSTALL_DIR..."
    sudo cp .build/release/$BINARY_NAME $INSTALL_DIR/
    sudo chmod +x $INSTALL_DIR/$BINARY_NAME
    echo -e "${GREEN}✓${NC} Binary installed"
fi

# Configure sudoers
echo ""
echo "Configuring sudoers for passwordless pmset access..."
CURRENT_USER=$(whoami)

# Create sudoers entry
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/pmset" | sudo tee $SUDOERS_FILE > /dev/null
sudo chmod 440 $SUDOERS_FILE

# Validate sudoers file
if sudo visudo -c -f $SUDOERS_FILE > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Sudoers configured"
else
    echo -e "${RED}Error: Invalid sudoers configuration${NC}"
    sudo rm $SUDOERS_FILE
    exit 1
fi

echo ""
echo "========================================="
echo -e "${GREEN}Installation complete!${NC}"
echo "========================================="
echo ""
echo "Usage:"
echo "  Start monitoring: $BINARY_NAME"
echo "  Stop monitoring:  Press Ctrl+C"
echo ""
echo "The app will prevent sleep when your laptop lid is closed"
echo "while maintaining thermal safety monitoring."
echo ""
