# Release Package Guide

## Automated Release (Recommended)

### Using GitHub Actions

The project includes automated CI/CD pipelines for production releases:

**Method 1: Tag-based Release (Recommended)**
```bash
# Create a version tag
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions automatically:
# ✓ Builds release binary (stripped)
# ✓ Runs full test suite
# ✓ Creates DMG package
# ✓ Creates TAR.GZ package
# ✓ Generates SHA256 checksums
# ✓ Creates GitHub Release with notes
# ✓ Uploads all assets
```

**Method 2: Manual Workflow Dispatch**
1. Go to GitHub Actions → Release workflow
2. Click "Run workflow"
3. Enter version (e.g., `1.0.0`)
4. Click "Run workflow"

The release workflow uses Apple Silicon runners (`macos-14`) and Swift 6.0 for consistent, reproducible builds.

### CI/CD Pipeline Details

**Workflows:**
1. **Build** (`.github/workflows/build.yml`) - CI on every push
2. **Test** (`.github/workflows/test.yml`) - Matrix testing + coverage
3. **Release** (`.github/workflows/release.yml`) - Automated releases

**Each release includes:**
- ✅ `ClosedDisplay-v{version}-arm64.dmg` (DMG installer)
- ✅ `ClosedDisplay-v{version}-arm64.dmg.sha256` (DMG checksum)
- ✅ `ClosedDisplay-v{version}-arm64.tar.gz` (TAR.GZ archive)
- ✅ `ClosedDisplay-v{version}-arm64.tar.gz.sha256` (TAR checksum)
- ✅ Auto-generated release notes

---

## Manual Release (Local Development)

For local testing or custom builds:

### Quick Method:

**Create all formats at once:**
```bash
./create-all-releases.sh [version]
```

**Individual formats:**
- **TAR.GZ**: `./create-release.sh [version]`
- **DMG**: `./create-dmg.sh [version]`

---

## What to Include in a Release

### Required Files:
1. **ClosedDisplay** (compiled binary from `.build/release/ClosedDisplay`)
2. **install.sh** - Automated installation script
3. **uninstall.sh** - Automated uninstallation script
4. **README.md** - Usage instructions
5. **LICENSE** - License file

### Optional Files:
6. **com.closeddisplay.app.plist** - LaunchAgent for auto-start (optional)

---

## Manual Release Creation (Advanced)

If you prefer to create releases manually:
```bash
swift build -c release
```

### 2. Create Release Directory
```bash
mkdir ClosedDisplay-v1.0.0
cd ClosedDisplay-v1.0.0
```

### 3. Copy Files
```bash
# Copy binary
cp ../.build/release/ClosedDisplay .

# Copy scripts
cp ../install.sh .
cp ../uninstall.sh .

# Make scripts executable
chmod +x install.sh uninstall.sh

# Copy documentation
cp ../README.md .
cp ../LICENSE . # If you have one
cp ../com.closeddisplay.app.plist .
```

### 4. Create Archive

**Option A: TAR.GZ (cross-platform)**
```bFrom DMG (Easiest):
```bash
# Open the DMG file
open ClosedDisplay-v1.0.0-arm64.dmg

# Double-click install.sh (or right-click → Open)
# Follow the prompts
```

### From TAR.GZ:
cd ..
tar -czf ClosedDisplay-v1.0.0-arm64.tar.gz ClosedDisplay-v1.0.0/
```

**Option B: DMG (macOS native, recommended)**
```bash
cd ..
./create-dmg.sh 1.0.0
```

The DMG provides a better user experience:
- Native macOS format
- Double-click to open
- Includes clear installation instructions
- Professional appearance

---

## User Installation Instructions

Users receiving your release should:

### Quick Install (Recommended)
```bash
# Extract the archive
tar -xzf ClosedDisplay-v1.0.0-arm64.tar.gz
cd ClosedDisplay-v1.0.0

# Run installation script
./install.sh
```

### Manual Install
1. Copy `ClosedDisplay` to `/usr/local/bin/`
2. Make it executable: `chmod +x /usr/local/bin/ClosedDisplay`
3. Create sudoers file:
   ```bash
   sudo visudo -f /private/etc/sudoers.d/closeddisplay
   ```
   Add line (replace `username` with your username):
   ```
   username ALL=(ALL) NOPASSWD: /usr/bin/pmset
   ```

### Optional: Auto-Start on Login
```bash
# Copy LaunchAgent plist
cp com.closeddisplay.app.plist ~/Library/LaunchAgents/

# Load it
launchctl load ~/Library/LaunchAgents/com.closeddisplay.app.plist
```

---

## Release Checklist

Before distributing:

- [ ] Build release binary: `swift build -c release`
- [ ] Test on clean machine (VM or separate Mac)
- [ ] Verify installation script works
- [ ] Verify uninstallation script works
- [ ] Test basic functionality (lid close/open detection)
- [ ] Test thermal safety (if possible)
- [ ] Verify sudoers configuration works
- [ ] Update version numbers in README
- [ ] Create release notes
- [ ] Sign binary (optional, for notarization)
- [ ] Notarize with Apple (optional, recommended for distribution)

---

## Code Signing & Notarization (Optional but Recommended)

For wider distribution, consider:

1. **Sign the binary:**
   ```bash
   codesign --sign "Developer ID Application: Your Name" \
       --timestamp --options runtime \
       .build/release/ClosedDisplay
   ```

2. **Create a signed package:**
   ```bash
   productbuild --component ClosedDisplay /usr/local/bin \
       --sign "Developer ID Installer: Your Name" \
       ClosedDisplay-v1.0.0.pkg
   ```

3. **Notarize with Apple:**
   ```bash
   xcrun notarytool submit ClosedDisplay-v1.0.0.pkg \
       --apple-id your@email.com \
       --team-id TEAMID \
       --password app-specific-password \
       --wait
   ```

4. **Staple the ticket:**
   ```bash
   xcrun stapler staple ClosedDisplay-v1.0.0.pkg
   ```

---

## Distribution Channels

Consider distributing through:
- **GitHub Releases** - Free, version controlled
- **Homebrew tap** - Easy installation for technical users
- **Direct download** - Host on your website
- **Mac App Store** - Requires more packaging work

### Example GitHub Release Command:
```bash
gh release create v1.0.0 \
    ClosedDisplay-v1.0.0-arm64.tar.gz \
    --title "ClosedDisplay v1.0.0" \
    --notes "Initial release"
```

### Example Homebrew Formula:
```ruby
class Closeddisplay < Formula
  desc "Allow Apple Silicon Macs to run with lid closed"
  homepage "https://github.com/DINHDUY/mac-closed-display"
  url "https://github.com/DINHDUY/mac-closed-display/releases/download/v1.0.0/ClosedDisplay-v1.0.0-arm64.tar.gz"
  sha256 "CALCULATED_SHA256_HERE"
  
  def install
    bin.install "ClosedDisplay"
  end
end
```
