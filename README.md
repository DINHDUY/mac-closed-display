# ClosedDisplay

[![Build](https://github.com/DINHDUY/mac-closed-display/actions/workflows/build.yml/badge.svg)](https://github.com/DINHDUY/mac-closed-display/actions/workflows/build.yml)
[![Tests](https://github.com/DINHDUY/mac-closed-display/actions/workflows/test.yml/badge.svg)](https://github.com/DINHDUY/mac-closed-display/actions/workflows/test.yml)
[![Release](https://github.com/DINHDUY/mac-closed-display/actions/workflows/release.yml/badge.svg)](https://github.com/DINHDUY/mac-closed-display/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A macOS utility that allows Apple Silicon Macs to continue running with the lid closed, without requiring an external display.

## Overview

ClosedDisplay uses a split-process architecture to safely override macOS power management while maintaining thermal safety:

- **Main App**: Monitors lid state, power sources, and thermal conditions
- **Helper Tool**: Executes privileged system commands (`pmset`) to prevent sleep
- **Safety**: Automatically reverts on thermal pressure to prevent hardware damage

## Use Cases

ClosedDisplay is perfect for scenarios where you need your Mac to keep working with the lid closed:

### 🤖 **AI Agent & Workflow Development**
Running multi-agent workflows or long-running AI tasks in the background? When you close your MacBook Pro lid, macOS typically shuts down network connectivity, interrupting your background processes. ClosedDisplay keeps your system active, maintaining network connections so your AI agents, workflows, and background tasks continue running uninterrupted.

### 🎵 **Media Server**
Use your MacBook as a music or media server in a closed, space-saving configuration while streaming content to other devices on your network.

### 💻 **Remote Development & SSH Sessions**
Keep your Mac accessible for remote SSH sessions, remote desktop connections, or as a development server while saving desk space with the lid closed.

### 📊 **Data Processing & Long-Running Tasks**
Run overnight data analysis, batch processing jobs, machine learning training, or rendering tasks without needing to keep the lid open or connect an external display.

### 🔄 **Background Synchronization**
Keep cloud syncing services (Time Machine backups, iCloud, Dropbox, etc.) running continuously without interruption, even with the lid closed.

### 🖥️ **Headless Server Mode**
Transform your MacBook into a headless server for development, testing, or home automation tasks while maintaining full processing power.

## Requirements

- macOS 14.0 or later
- Apple Silicon Mac (M1/M2/M3+)
- Administrator privileges (for initial setup)

## Installation

### Option 1: Download DMG (Recommended)

1. Download the latest `.dmg` file from the [GitHub Releases page](https://github.com/DINHDUY/mac-closed-display/releases)
2. Open the downloaded DMG file
3. Follow the installation instructions inside
4. Run the installer:
   ```bash
   sudo ./install.sh
   ```

The DMG package includes the binary, installation scripts, and all necessary documentation.

### Option 2: Download TAR.GZ

1. Download the latest `.tar.gz` file from the [GitHub Releases page](https://github.com/DINHDUY/mac-closed-display/releases)
2. Verify the checksum (optional but recommended):
   ```bash
   shasum -a 256 -c ClosedDisplay-v*.tar.gz.sha256
   ```
3. Extract the archive:
   ```bash
   tar -xzf ClosedDisplay-v*.tar.gz
   cd ClosedDisplay-v*
   ```
4. Run the installer:
   ```bash
   sudo ./install.sh
   ```

### Option 3: Build from Source

For developers or those who want to build manually:

1. **Build the Project**
   ```bash
   swift build -c release
   ```
   
   The build produces the main executable:
   - `.build/release/ClosedDisplay` - Main application

2. **Configure Permissions**
   
   Create a sudoers entry to allow `pmset` to run without password prompts:
   
   ```bash
   sudo visudo -f /private/etc/sudoers.d/closeddisplay
   ```
   
   Add the following line (replace `<username>` with your username):
   
   ```
   <username> ALL=(ALL) NOPASSWD: /usr/bin/pmset
   ```
   
   Save and exit the editor.

3. **Copy Binary** (optional)
   ```bash
   sudo cp .build/release/ClosedDisplay /usr/local/bin/
   ```

### Option 4: Build as macOS App Bundle (Recommended for Menu Bar)

For full menu bar functionality including tooltips and menu interactions:

1. **Build the App Bundle**
   ```bash
   ./build-app.sh
   ```
   
   This creates `ClosedDisplay.app` with full macOS integration.

2. **Install to Applications**
   ```bash
   cp -R ClosedDisplay.app /Applications/
   ```

3. **Launch the App**
   ```bash
   open /Applications/ClosedDisplay.app
   ```
   
   Or launch from Spotlight/Launchpad.

**App Bundle Benefits:**
- ✅ Menu bar icon with working tooltips
- ✅ Click menu to access all features
- ✅ Native system notifications
- ✅ Auto-start via Login Items

See [docs/app-bundle.md](docs/app-bundle.md) for detailed instructions.

## Usage

### Menu Bar App (Recommended)

When running as an app bundle, ClosedDisplay provides a menu bar icon:

- **Hover** over the icon to see status tooltip
- **Click** the icon to access:
  - Enable/Disable ClosedDisplay
  - Suspend (temporarily allow sleep)
  - About
  - Quit

### Command Line

Run the main application:

```bash
.build/release/ClosedDisplay
```

The application will:
1. Monitor for lid closure events
2. Prevent system sleep when the lid is closed
3. Maintain thermal safety monitoring
4. Restore normal behavior when the session ends

### Stopping a Session

Press `Ctrl+C` or send a termination signal. The application will:
1. Restore normal sleep behavior
2. Release all system assertions
3. Clean up resources

## How It Works

1. **Lid Detection**: Monitors `AppleClamshellState` via IOKit Registry
2. **Sleep Prevention**: Executes `pmset -a disablesleep 1` via privileged helper
3. **Thermal Safety**: Watches `ProcessInfo.thermalState` and reverts on critical conditions
4. **Power Monitoring**: Tracks AC/battery transitions and reasserts settings as needed

## Safety Features

- **Thermal Watchdog**: Automatically reverts to normal sleep behavior if thermal state becomes serious or critical
- **Clean Shutdown**: Ensures all overrides are removed on exit
- **Power Awareness**: Adjusts behavior based on power source

## Testing

Run the test suite:

```bash
swift test
```

The test suite includes:
- Correctness tests (state transitions, lifecycle)
- Performance benchmarks (state change overhead)
- Property-based tests (state machine invariants)
Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Security

For security concerns, please see our [Security Policy](SECURITY.md).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## 
## Architecture

See [docs/closed-display.md](docs/closed-display.md) for detailed architecture documentation.

## License

See LICENSE file for details.
