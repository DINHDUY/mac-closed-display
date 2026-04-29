# Contributing to ClosedDisplay

First off, thank you for considering contributing to ClosedDisplay! It's people like you that make ClosedDisplay such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible using our bug report template.

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. Create an issue using the feature request template and provide the following information:

- Use a clear and descriptive title
- Provide a detailed description of the suggested enhancement
- Explain why this enhancement would be useful
- List any alternative solutions you've considered

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. Ensure the test suite passes
4. Make sure your code follows the existing style
5. Write a clear commit message
6. Submit a pull request using the PR template

## Development Setup

### Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 6.0

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/closed-display.git
cd closed-display

# Build the project
swift build

# Run tests
swift test

# Build for release
swift build -c release
```

### Project Structure

```
closed-display/
├── src/                    # Source code
│   ├── AppMain.swift      # Application entry point
│   ├── SessionManager.swift
│   ├── PowerManager.swift
│   ├── IOKitServices.swift
│   └── Types.swift
├── tests/                  # Test files
├── docs/                   # Documentation
└── Package.swift          # Swift package manifest
```

## Coding Guidelines

### Swift Style

- Follow Swift API Design Guidelines
- Use 4 spaces for indentation (no tabs)
- Maximum line length: 120 characters
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

Examples:
```
feat(power): add battery level monitoring
fix(thermal): correct temperature threshold check
docs(readme): update installation instructions
```

### Testing

- Write tests for new features
- Ensure all tests pass before submitting PR
- Aim for good test coverage
- Include both unit tests and integration tests where applicable

### Documentation

- Update README.md if you change functionality
- Add inline comments for complex code
- Update docs/ directory for architectural changes
- Keep RELEASE.md updated with new features

## Release Process

Releases are automated through GitHub Actions:

1. Update version numbers
2. Update CHANGELOG (if exists)
3. Create and push a version tag: `git tag v1.0.0 && git push origin v1.0.0`
4. GitHub Actions will build and create the release

## Getting Help

- Read the [README.md](README.md)
- Check existing [Issues](https://github.com/yourusername/closed-display/issues)
- Read the [Documentation](docs/)

## Recognition

Contributors will be recognized in:
- GitHub contributors list
- Release notes (for significant contributions)
- README acknowledgments section

Thank you for your contributions! 🎉
