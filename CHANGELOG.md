# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release preparation

## [1.0.0] - TBD

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

[Unreleased]: https://github.com/yourusername/closed-display/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/closed-display/releases/tag/v1.0.0
