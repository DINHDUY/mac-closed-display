# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of ClosedDisplay seriously. If you discover a security vulnerability, please follow these steps:

### Where to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via one of these methods:

1. **GitHub Security Advisories** (Preferred)
   - Go to the repository's Security tab
   - Click "Report a vulnerability"
   - Fill out the form with details

2. **Email**
   - Send details to: [your-security-email@example.com]
   - Use PGP key: [if available]

### What to Include

Please include the following information in your report:

- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Varies by severity
  - Critical: 7-14 days
  - High: 14-30 days
  - Medium: 30-60 days
  - Low: 60-90 days

### What to Expect

1. **Acknowledgment**: We will acknowledge receipt of your vulnerability report
2. **Assessment**: We will assess the vulnerability and determine its impact
3. **Fix Development**: We will develop a fix and prepare a security advisory
4. **Disclosure**: We will publicly disclose the vulnerability after a fix is available
5. **Credit**: We will credit you in the security advisory (unless you prefer to remain anonymous)

## Security Considerations

### ClosedDisplay Security Model

ClosedDisplay requires elevated privileges to function:

- **Sudo Access**: Required to execute `pmset` commands
- **Sudoers Configuration**: Passwordless sudo for `/usr/bin/pmset` only
- **No Network Access**: Application does not make network connections
- **No Data Collection**: No telemetry or user data is collected

### Threat Model

**What ClosedDisplay protects against:**
- Unintended system sleep when lid is closed
- Thermal damage through safety monitoring

**What ClosedDisplay does NOT protect against:**
- Malicious use of sudo privileges (requires user to grant permissions)
- Physical access attacks
- OS-level vulnerabilities

### Best Practices for Users

1. **Verify Downloads**: Always verify SHA256 checksums of downloaded releases
2. **Review Sudoers**: Understand what permissions you're granting
3. **Monitor Thermals**: Pay attention to thermal warnings
4. **Official Sources**: Only download from official GitHub releases

## Known Security Limitations

1. **Sudo Requirement**: Application requires sudo access to `pmset`
   - Mitigation: Limited to specific binary path only
   
2. **Unsigned Binary**: Releases are not code-signed
   - Mitigation: SHA256 checksums provided for verification
   
3. **Root Privileges**: Helper component runs with elevated privileges
   - Mitigation: Minimal privilege scope, open source for audit

## Security Updates

Security updates will be released as patch versions and announced via:

- GitHub Security Advisories
- Release notes
- README.md updates

## Disclosure Policy

We follow **Coordinated Disclosure**:

1. Security issue is reported privately
2. Issue is confirmed and fixed
3. Fix is released
4. Public disclosure is made (typically 90 days after fix or when patch is available)

## Security Hall of Fame

We appreciate security researchers who help keep ClosedDisplay secure:

<!-- Names of contributors who reported security issues will be listed here -->

---

Thank you for helping keep ClosedDisplay and its users safe!
