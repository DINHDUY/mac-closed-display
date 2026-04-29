# ClosedDisplay

A macOS utility that allows Apple Silicon Macs to continue running with the lid closed, without requiring an external display.

## Overview

ClosedDisplay uses a split-process architecture to safely override macOS power management while maintaining thermal safety:

- **Main App**: Monitors lid state, power sources, and thermal conditions
- **Helper Tool**: Executes privileged system commands (`pmset`) to prevent sleep
- **Safety**: Automatically reverts on thermal pressure to prevent hardware damage

## Requirements

- macOS 14.0 or later
- Apple Silicon Mac (M1/M2/M3+)
- Administrator privileges (for initial setup)

## Installation

### 1. Build the Project

```bash
swift build -c release
```

The build produces two executables:
- `.build/release/ClosedDisplay` - Main application
- `.build/release/ClosedDisplayHelper` - Privileged helper

### 2. Configure Permissions

Create a sudoers entry to allow `pmset` to run without password prompts:

```bash
sudo visudo -f /private/etc/sudoers.d/closeddisplay
```

Add the following line (replace `<username>` with your username):

```
<username> duy ALL=(ALL) NOPASSWD: /usr/bin/pmset
```

Save and exit the editor.

## Usage

### Starting a Session

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

## Architecture

See [docs/closed-display.md](docs/closed-display.md) for detailed architecture documentation.

## License

See LICENSE file for details.
