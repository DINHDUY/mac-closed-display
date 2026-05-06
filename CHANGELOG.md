# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-05-06

### Added
- **Setup Permissions dialog**: new "Setup Permissions..." menu item in the status bar menu creates `/private/etc/sudoers.d/closeddisplay`, granting the current user passwordless sudo for `/usr/bin/pmset`
- **First-run auto-prompt**: on first launch (sudoers file absent and user not yet prompted), the permissions dialog appears automatically after a 0.5 s delay so the menu bar icon is visible first
- `make test-debug` target: runs `swift test --enable-code-coverage` then exports an lcov report to `.build/debug/codecov/coverage.lcov`

### Fixed
- Code coverage export: `xcrun llvm-cov` → `xcrun --toolchain swift llvm-cov` to fix "unsupported instrumentation profile format version" error caused by a version mismatch between the Xcode-bundled and Swift-toolchain-bundled `llvm-cov` (both `Makefile` and `.github/workflows/test.yml`)

## [1.1.1] - 2026-05-02

### Added
- App icon: `AppIcon` asset catalog with all required macOS sizes (16 → 1024 pt, @1x and @2x)
- 1024 × 1024 px App Store icon (no alpha channel; squircle mask applied by system)
- `Makefile` with targets: `build`, `build-debug`, `test`, `app`, `install`, `uninstall`, `release`, `release-dmg`, `release-all`, `clean`, `help`

### Changed
- `scripts/build-app.sh` and `scripts/create-release.sh` now compile the asset catalog via `actool` and set `CFBundleIconName` in `Info.plist`

## [1.0.1] - 2026-04-29

### Added
- Menu bar status icon with three states: active (●), suspended (⏸), disabled (○)
- Dropdown menu with Enable/Disable, Suspend, About, and Quit actions
- Native macOS notifications on state change (requires app bundle)
- Suspend mode — temporarily allow sleep without fully disabling
- Hover tooltip showing current state

### Changed
- App now ships as a proper `.app` bundle (`ClosedDisplay.app`) instead of a bare binary
- DMG uses drag-to-Applications layout for standard macOS install experience
- Reorganized all shell scripts into `scripts/` directory
- Release pipeline builds and packages the `.app` bundle


## [1.0.0] - 2026-04-29 MVP

### Added
- Initial release of ClosedDisplay
- Continuous monitoring of lid state via IOKit
- Prevent system sleep when lid is closed
- Thermal safety monitoring with automatic revert
- Power source awareness (AC/battery transitions)
- Signal handling for graceful shutdown (SIGINT/SIGTERM)
- Automated installation script
- DMG and TAR.GZ distribution formats
- Comprehensive test suite (correctness, performance, property-based)
- GitHub Actions CI/CD pipeline
- Automated release workflow

### Features
- Support for Apple Silicon Macs (M1/M2/M3/M4)
- macOS 14.0+ compatibility
- Passwordless sudo configuration for pmset
- LaunchAgent for auto-start on login (optional)
- Thermal kill-switch at serious/critical levels
- Debounced lid state changes (500ms)
- Clean resource cleanup on exit

### Documentation
- Comprehensive README with installation and usage instructions
- Architecture documentation
- Release packaging guide
- Security policy
- Contributing guidelines
- Issue and PR templates

### Security
- Limited sudo scope (pmset only)
- No network connectivity
- No data collection or telemetry
- Open source for security audit

[Unreleased]: https://github.com/DINHDUY/mac-closed-display/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/DINHDUY/mac-closed-display/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/DINHDUY/mac-closed-display/releases/tag/v1.0.0
