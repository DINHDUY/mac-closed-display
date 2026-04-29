# StatusBar Integration

## Overview

ClosedDisplay now includes a menu bar icon that provides visual feedback about the application state and allows users to control the application behavior.

## Features

### 1. Menu Bar Icon
- **Enabled State**: Displays a filled checkmark circle icon (⦿)
- **Suspended State**: Displays a filled pause circle icon (⏸) - temporarily allows sleep on lid close
- **Disabled State**: Displays an empty circle icon (○)
- The icon uses template rendering to match the system appearance (light/dark mode)

### 2. Tooltips
Hover over the menu bar icon to see detailed status information:
- **Enabled**: "ClosedDisplay ON - You can close the lid without interrupting background processes"
- **Suspended**: "ClosedDisplay SUSPENDED - Temporarily allowing sleep on lid close"
- **Disabled**: "ClosedDisplay OFF - Lid closure will sleep the Mac"
- On first installation, the application defaults to **enabled/running**
- **Disabled**: "ClosedDisplay OFF - Lid closure will sleep the Mac"

### 3. Default State
- On first installation, the application defaults to **enabled/running**
- The state is persisted in UserDefaults using the key `com.closed-display.enabled`
- State persists across application restarts

### 4. Suspend Feature
- **Purpose**: Temporarily allow the Mac to sleep when the lid is closed without fully disabling ClosedDisplay
- **Use Case**: When you want to put your Mac to sleep for a short period (e.g., during a meeting or travel) but plan to resume background processes later
- **Behavior**: 
  - Suspend is only available when ClosedDisplay is enabled
  - When suspended, lid closure will allow the Mac to sleep normally
  - Icon changes to pause symbol (⏸) to indicate suspended state
  - Resuming ClosedDisplay restores the normal behavior (prevents sleep on lid close)
  - Disabling ClosedDisplay automatically clears the suspended state

### 5. State Change Notifications
- When the application state changes (enabled ↔ disabled), a system notification is displayed
- Notifications show:
  - "ClosedDisplay enabled" when turned on
  - "ClosedDisplay disabled" when turned off
- Notifications use the standard macOS notification system (UNUserNotificationCenter)
- **Note**: When running as a command-line executable (without app bundle), notifications will be printed to console instead of displaying as system notifications. For full notification support, the app should be bundled as a `.app` with an Info.plist file.

### 6. Menu Options

Click the menu bar icon to access:
- **Enable/Disable ClosedDisplay**: Toggle the application state (enabled ↔ disabled)
- **Suspend/Resume**: Temporarily allow sleep on lid close without disabling ClosedDisplay (only available when enabled)
- **About ClosedDisplay**: Display version and information
- **Quit**: Exit the application

## Technical Details

### Architecture
- **StatusBarController**: New Swift class managing menu bar UI and state
- **Integration**: Initialized in `AppMain.swift` during application startup
- **Dependencies**: Uses Cocoa's NSStatusBar API and UserNotifications framework

### State Management
- State is stored in UserDefaults for persistence
- Lid monitoring respects the status bar state - when disabled, any active clamshell session is ended
- The application runs as an accessory app (menu bar only, no dock icon)

### Performance
- Minimal memory footprint: StatusBarController uses lazy-loaded SF Symbols for icons
- No continuous polling: state changes trigger updates via property observers
- Notification requests are fire-and-forget (no blocking)
- Graceful degradation: Notifications are optional and safely disabled when running without app bundle

## User Experience

1. **First Launch**: Application starts enabled, menu bar icon appears with filled checkmark (⦿)
2. **Toggle State**: Click menu bar icon → Enable/Disable to control behavior
3. **Suspend**: Click menu bar icon → Suspend to temporarily allow sleep on lid close
   - Icon changes to pause symbol (⏸)
   - Click Resume to restore normal behavior
4. **Visual Feedback**: Icon and tooltip update immediately to reflect current state
5. **Persistence**: State remembered across launches
6. **Hover Tooltip**: Hover over icon to see detailed status message

## Code Files

- `src/StatusBarController.swift`: Menu bar and notification management
- `src/AppMain.swift`: Integration and application lifecycle
- `src/Types.swift`: Constants for UserDefaults keys
