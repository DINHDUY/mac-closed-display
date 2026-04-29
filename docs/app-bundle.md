# Building ClosedDisplay as a macOS App Bundle

## Why Use the App Bundle?

When built as a command-line executable, ClosedDisplay has limitations:
- **Tooltips don't display** on the menu bar icon
- **Clicking the icon doesn't show the menu** (macOS UI restrictions for non-bundled apps)

When built as a proper `.app` bundle:
- ✅ **Tooltips work** - Hover to see detailed status
- ✅ **Menu interactions work** - Click to access all options
- ✅ **System notifications work** - Full native notification support
- ✅ **Better integration** - Runs as a proper macOS application

## Building the App Bundle

### Quick Build

```bash
./scripts/build-app.sh
```

This creates `ClosedDisplay.app` in the project directory.

### Manual Build

```bash
# Build release binary
swift build -c release

# Run the build script
./scripts/build-app.sh
```

## Installing the App

### Option 1: Copy to Applications (Recommended)

```bash
cp -R ClosedDisplay.app /Applications/
```

Then launch from Applications folder or Spotlight.

### Option 2: Run from Project Directory

```bash
open ClosedDisplay.app
```

## Using the App

1. **Launch the app** - The menu bar icon appears automatically
2. **Hover over the icon** - See the tooltip with current status
3. **Click the icon** - Access the dropdown menu:
   - Enable/Disable ClosedDisplay
   - Suspend (temporarily allow sleep on lid close)
   - About
   - Quit

## Menu Bar Icon States

- **⦿ Filled Checkmark** - ClosedDisplay is ON (preventing sleep on lid close)
- **⏸ Pause Symbol** - ClosedDisplay is SUSPENDED (temporarily allowing sleep)
- **○ Empty Circle** - ClosedDisplay is OFF (normal lid behavior)

## Tooltips

Hover over the menu bar icon to see:
- **ON**: "ClosedDisplay ON - You can close the lid without interrupting background processes"
- **SUSPENDED**: "ClosedDisplay SUSPENDED - Temporarily allowing sleep on lid close"
- **OFF**: "ClosedDisplay OFF - Lid closure will sleep the Mac"

## Auto-Start on Login

To make ClosedDisplay start automatically on login:

1. Open **System Settings** → **General** → **Login Items**
2. Click the **+** button under "Open at Login"
3. Navigate to `/Applications/ClosedDisplay.app`
4. Click **Add**

## Uninstalling the App

```bash
# Remove from Applications
rm -rf /Applications/ClosedDisplay.app

# Remove from Login Items (via System Settings)
System Settings → General → Login Items → Remove ClosedDisplay
```

## Command Line vs App Bundle

| Feature | Command Line | App Bundle |
|---------|-------------|------------|
| Menu bar icon | ✅ | ✅ |
| Tooltips | ❌ | ✅ |
| Click menu | ❌ | ✅ |
| Notifications | ❌ (console only) | ✅ |
| Auto-start | Via launchd | Login Items |
| Installation | `/usr/local/bin` | `/Applications` |

## Troubleshooting

### App won't open
- Check if another instance is running: `killall ClosedDisplay`
- Rebuild: `./scripts/build-app.sh`

### Menu bar icon doesn't appear
- Check Console app for errors
- Ensure you're running the .app bundle, not the command-line version

### Tooltip doesn't show
- Make sure you're running the `.app` bundle
- Command-line executable doesn't support tooltips due to macOS restrictions
