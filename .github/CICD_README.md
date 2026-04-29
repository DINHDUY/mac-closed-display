# GitHub Actions CI/CD

This directory contains GitHub Actions workflows for automated building, testing, and releasing.

## Workflows

### build.yml - Continuous Integration
**Trigger:** Push to main/develop, Pull Requests
- Builds release binary on Apple Silicon runners
- Runs test suite
- Caches Swift packages for faster builds
- Uploads build artifacts for inspection

### test.yml - Comprehensive Testing
**Trigger:** Push, Pull Requests, Daily schedule, Manual
- Runs tests in both debug and release configurations
- Generates code coverage reports
- Uploads coverage to Codecov
- Matrix testing across configurations

### release.yml - Automated Release
**Trigger:** Version tags (v*.*.*), Manual workflow dispatch
- Builds stripped release binary
- Creates both DMG and TAR.GZ packages
- Generates SHA256 checksums
- Creates GitHub Release with auto-generated notes
- Uploads all release artifacts
- Supports manual releases via workflow dispatch

## Usage

### Automated Release (Recommended)
```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will automatically:
# 1. Build the release binary
# 2. Run tests
# 3. Create DMG and TAR.GZ packages
# 4. Generate checksums
# 5. Create GitHub release with assets
```

### Manual Release
1. Go to Actions → Release workflow
2. Click "Run workflow"
3. Enter version (e.g., 1.0.0)
4. Click "Run workflow"

## Requirements

- Repository must use `macos-14` runners (Apple Silicon)
- Swift 6.0 toolchain
- Permissions: `contents: write` for releases

## Secrets

Optional secrets for enhanced functionality:

- `CODECOV_TOKEN` - For code coverage uploads (optional)

## Best Practices

1. **Version Tags**: Always use semantic versioning (v1.0.0)
2. **Pull Requests**: All PRs are tested automatically
3. **Release Notes**: Auto-generated from commits and checksums
4. **Caching**: Swift packages cached for faster builds
5. **Security**: Minimal permissions, no credential exposure

## Dependabot

The `dependabot.yml` configuration keeps GitHub Actions up to date:
- Weekly checks for action updates
- Automatic PRs for updates
- Labeled for easy identification

## Issue Templates

- `bug_report.yml` - Structured bug reports
- `feature_request.yml` - Feature suggestions

## Pull Request Template

`PULL_REQUEST_TEMPLATE.md` provides a structured format for PRs.
