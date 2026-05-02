# Mac App Store Publishing Checklist

> **Version:** 1.0 · **Last updated:** April 2026
> A deterministic, phase‑by‑phase checklist for shipping a macOS application through the Mac App Store. Designed for engineering teams; suitable for onboarding, CI gating, and release sign‑off.

---

## Table of Contents

1. [Prerequisites & Environment](#1-prerequisites--environment)
2. [Technical Requirements](#2-technical-requirements)
3. [Code Signing & Provisioning](#3-code-signing--provisioning)
4. [Notarization](#4-notarization)
5. [App Store Connect Metadata](#5-app-store-connect-metadata)
6. [Privacy & Compliance](#6-privacy--compliance)
7. [Testing & Quality Assurance](#7-testing--quality-assurance)
8. [App Review Readiness](#8-app-review-readiness)
9. [Release Strategy](#9-release-strategy)
10. [Post‑Launch](#10-postlaunch)
11. [Appendix — Quick‑Reference Tables](#appendix--quickreference-tables)

---

## 1. Prerequisites & Environment

### 1.1 Apple Developer Program

- [ ] Active Apple Developer Program membership ($99 USD/year)
- [ ] Team Agent or Admin role for App Store Connect access
- [ ] Two‑factor authentication enabled on Apple ID
- [ ] Legal entity / D‑U‑N‑S Number on file (for organizations)

### 1.2 Development Environment

- [ ] Xcode — latest stable release (or minimum version supporting your deployment target)
- [ ] macOS — latest stable release on build machine
- [ ] Command‑line tools installed (`xcode-select --install`)
- [ ] `notarytool` available (ships with Xcode 14+; `altool` is deprecated as of Nov 1, 2023)
- [ ] CocoaPods / Swift Package Manager / Carthage dependencies resolved and locked
- [ ] CI/CD pipeline configured (Xcode Cloud, GitHub Actions, Buildkite, etc.)

---

## 2. Technical Requirements

### 2.1 Build Configuration

- [ ] Deployment target set to a currently supported macOS version (minimum **macOS 13 Ventura** recommended for new apps)
- [ ] **Universal Binary** (arm64 + x86_64) — required to support both Apple Silicon and Intel Macs
- [ ] Build number (`CFBundleVersion`) is unique and monotonically increasing per version
- [ ] Marketing version (`CFBundleShortVersionString`) follows semantic versioning
- [ ] `LSMinimumSystemVersion` in `Info.plist` matches Xcode deployment target
- [ ] Bundle identifier matches App Store Connect record exactly

### 2.2 App Sandbox (Mandatory for Mac App Store)

- [ ] `com.apple.security.app-sandbox` entitlement set to `YES`
- [ ] Only required entitlements requested — reject the rest:
  - [ ] Network: `com.apple.security.network.client` / `.server`
  - [ ] File access: `com.apple.security.files.user-selected.read-only` / `.read-write`
  - [ ] Hardware: camera, microphone, USB, Bluetooth
  - [ ] Apple Events / Accessibility
  - [ ] Temporary exception entitlements (document rationale for each; Apple may reject)
- [ ] No file‑system access outside the sandbox container unless via user‑granted entitlements
- [ ] `NSOpenPanel` / `NSSavePanel` used for user‑initiated file access
- [ ] Security‑scoped bookmarks used for persistent file access across launches

### 2.3 Hardened Runtime (Mandatory)

- [ ] `com.apple.security.hardened-runtime` enabled (or "Hardened Runtime" in Xcode Signing & Capabilities)
- [ ] Runtime exceptions declared only where absolutely necessary:
  - [ ] `com.apple.security.cs.allow-jit` — JIT compilation
  - [ ] `com.apple.security.cs.allow-unsigned-executable-memory`
  - [ ] `com.apple.security.cs.disable-library-validation` — loading third‑party dylibs
  - [ ] `com.apple.security.cs.allow-dyld-environment-variables`
- [ ] All exceptions documented with justification (reviewers may ask)

### 2.4 Frameworks & APIs

- [ ] No use of deprecated or private Apple APIs
- [ ] No calls to `dlopen`, `NSTask`, or `Process` with arbitrary executables (sandbox violation)
- [ ] Any embedded frameworks are properly signed and in `Frameworks/` directory
- [ ] Third‑party dylibs/frameworks include `arm64` slice
- [ ] App does not embed its own copy of a system framework
- [ ] No use of `IOKit` or kernel extensions without explicit entitlement approval
- [ ] SwiftUI / AppKit lifecycle correctly configured

### 2.5 App Icon

- [ ] 1024 × 1024 px icon in the asset catalog (`AppIcon` set)
- [ ] macOS icon uses the **rounded‑rectangle (squircle)** shape — do **not** apply the mask manually; the system does it
- [ ] No alpha channel / transparency in the 1024 × 1024 App Store icon
- [ ] Icon set includes all required sizes: 16, 32, 64, 128, 256, 512, 1024 pt (@1x and @2x)

---

## 3. Code Signing & Provisioning

### 3.1 Certificates

- [ ] **Mac App Distribution** certificate generated in Apple Developer portal
- [ ] **Mac Installer Distribution** certificate generated (required for `.pkg` upload)
- [ ] Certificates installed in the build machine's Keychain
- [ ] Certificates are not expired (valid for 5 years; check expiration dates)
- [ ] If using CI: certificates and private keys exported as `.p12` and securely stored in CI secrets

### 3.2 Provisioning Profiles

- [ ] **Mac App Store** provisioning profile created in Certificates, Identifiers & Profiles
- [ ] Profile includes the correct App ID (bundle identifier)
- [ ] All required entitlements are present in the profile
- [ ] Profile is not expired and is downloaded / installed on the build machine
- [ ] Xcode "Automatically manage signing" is either consistently on or off project‑wide (avoid mixing)

### 3.3 Signing Verification

- [ ] Run `codesign --verify --deep --strict /path/to/YourApp.app` — no errors
- [ ] Run `codesign -dvvv /path/to/YourApp.app` — verify Team ID, signing identity, and Hardened Runtime flag
- [ ] Run `spctl --assess --type execute /path/to/YourApp.app` — "accepted"
- [ ] All nested bundles, frameworks, XPC services, and helpers are individually signed
- [ ] Embedded provisioning profile matches the app's bundle ID (`security cms -D -i embedded.provisionprofile`)

---

## 4. Notarization

> **Note:** Notarization is handled automatically when uploading to the Mac App Store via Xcode or Transporter. This section is included for completeness and for teams that also distribute outside the App Store.

### 4.1 Pre‑Notarization Checks

- [ ] Hardened Runtime is enabled (required for notarization)
- [ ] App is signed with a valid Developer ID or Mac App Distribution certificate
- [ ] No unsigned code or libraries
- [ ] Timestamps included in the signature (`--timestamp` flag)

### 4.2 Submission & Stapling (Direct Distribution Only)

- [ ] Submit with `notarytool`: `xcrun notarytool submit YourApp.zip --apple-id … --team-id … --password …`
- [ ] Poll or wait for completion: `xcrun notarytool wait <submission-id> …`
- [ ] Retrieve log if issues arise: `xcrun notarytool log <submission-id> …`
- [ ] Staple ticket: `xcrun stapler staple YourApp.app`
- [ ] Validate staple: `xcrun stapler validate YourApp.app`

### 4.3 CI Integration

- [ ] App‑specific password or API key stored as CI secret (never hardcoded)
- [ ] Notarization step runs post‑signing, pre‑archiving in pipeline
- [ ] Failure in notarization breaks the build

---

## 5. App Store Connect Metadata

### 5.1 App Record Setup

- [ ] App record created in App Store Connect with correct Bundle ID
- [ ] Primary language selected
- [ ] Primary and (optional) secondary category chosen
- [ ] Content rights declaration completed (if app contains third‑party content)
- [ ] SKU assigned (internal reference, not visible to users)

### 5.2 Version Metadata

- [ ] **App Name** — up to 30 characters; unique on the App Store
- [ ] **Subtitle** — up to 30 characters; distinct from app name
- [ ] **Description** — up to 4,000 characters; no keyword stuffing; plain text only
- [ ] **What's New** (release notes) — up to 4,000 characters
- [ ] **Keywords** — up to 100 characters, comma‑separated; no duplicates of app name
- [ ] **Support URL** — valid, publicly accessible
- [ ] **Marketing URL** — optional but recommended
- [ ] **Privacy Policy URL** — required for all apps

### 5.3 Screenshots (Mac)

- [ ] **Minimum 1, maximum 10** screenshots per localization
- [ ] Accepted dimensions (16:10 aspect ratio, landscape):

| Size             | Resolution       | Type       | Status          |
|------------------|------------------|------------|-----------------|
| MacBook Pro 15″  | 2880 × 1800 px   | Retina     | **Recommended** |
| MacBook Pro 13″  | 2560 × 1600 px   | Retina     | Accepted        |
| MacBook Air      | 1440 × 900 px    | Non‑Retina | Accepted        |
| Legacy           | 1280 × 800 px    | Non‑Retina | Minimum         |

- [ ] Format: PNG or JPEG; RGB color space; **no transparency**
- [ ] Each file ≤ 10 MB
- [ ] Screenshots show real app content — no placeholder or misleading imagery
- [ ] Localized screenshots provided for each supported language

### 5.4 App Preview Videos (Optional)

- [ ] 15–30 seconds; `.mov`, `.mp4`, or `.m4v`
- [ ] No device frame required for Mac
- [ ] Demonstrates actual app experience; no rendered/conceptual footage
- [ ] App audio only (no voiceover unless it's part of the app)

### 5.5 Pricing & Availability

- [ ] Price tier or custom price set
- [ ] Territory availability configured (default: all territories)
- [ ] Pre‑order configured if desired (up to 180 days before release)
- [ ] Volume Purchase Program (VPP / Apple Business Manager) availability toggled

### 5.6 In‑App Purchases & Subscriptions

- [ ] All IAPs created in App Store Connect with reference names, product IDs, and pricing
- [ ] Review screenshot uploaded for each IAP
- [ ] Subscription groups configured with proper hierarchy
- [ ] Introductory / promotional offer configured (if applicable)
- [ ] "Restore Purchases" button accessible in the app
- [ ] StoreKit 2 or original StoreKit API integrated and tested
- [ ] Server‑side receipt validation implemented (recommended)

---

## 6. Privacy & Compliance

### 6.1 Privacy Nutrition Labels

- [ ] All data types collected or tracked are declared in App Store Connect:
  - Contact Info, Health & Fitness, Financial Info, Location, Contacts, User Content, Browsing History, Search History, Identifiers, Purchases, Usage Data, Diagnostics, Sensitive Info, Other Data
- [ ] Each data type categorized by purpose: App Functionality, Analytics, Product Personalization, Third‑Party Advertising, Developer's Advertising, Other
- [ ] "Linked to User" vs. "Not Linked to User" accurately declared
- [ ] "Used to Track" accurately declared (if data is combined with third‑party data for ad targeting)
- [ ] Declarations updated when any SDK or data‑collection behavior changes

### 6.2 Privacy Policy

- [ ] Publicly accessible URL provided
- [ ] Covers all data collected by the app and embedded SDKs
- [ ] Explains data usage, retention, sharing, and deletion practices
- [ ] Compliant with GDPR, CCPA, and other applicable privacy regulations
- [ ] Updated whenever data practices change

### 6.3 App Tracking Transparency (ATT)

- [ ] If tracking users across apps/websites owned by other companies: `NSUserTrackingUsageDescription` in `Info.plist`
- [ ] ATT prompt displayed before any tracking occurs (AppTrackingTransparency framework)
- [ ] If **not** tracking: ATT prompt is not shown (do not prompt unnecessarily)

### 6.4 Encryption Export Compliance

- [ ] `ITSAppUsesNonExemptEncryption` key set in `Info.plist`
  - `NO` — if app uses only exempt encryption (HTTPS/TLS, standard OS APIs)
  - `YES` — if app uses proprietary or non‑standard encryption; CCATS / ERN documentation required
- [ ] If `YES`: export compliance documentation uploaded in App Store Connect
- [ ] French encryption declaration completed (if distributing in France)

### 6.5 Account Deletion

- [ ] If users can create an account in the app, a mechanism to **initiate account deletion** is provided within the app
- [ ] Deletion process deletes or disassociates all personal data (per Apple guideline 5.1.1(v))
- [ ] Users can find the deletion option without contacting support

### 6.6 Age Rating & Content Descriptions

- [ ] Age rating questionnaire completed in App Store Connect
- [ ] Content descriptions accurate (violence, language, mature themes, gambling, etc.)
- [ ] If rated 17+: confirm app does not target children
- [ ] If app is for kids (Kids Category): complies with COPPA; no behavioral ads, no third‑party analytics without parental consent

---

## 7. Testing & Quality Assurance

### 7.1 Device & OS Coverage

- [ ] Tested on **Apple Silicon** Mac (M1/M2/M3/M4)
- [ ] Tested on **Intel** Mac (if supporting x86_64)
- [ ] Tested on **minimum deployment target** macOS version
- [ ] Tested on **latest stable** macOS version
- [ ] Tested on latest macOS **beta** (optional but recommended)

### 7.2 Functional Testing

- [ ] All primary features work end‑to‑end
- [ ] All IAPs complete correctly in Sandbox environment
- [ ] Subscription lifecycle tested: purchase → renewal → cancellation → grace period → restore
- [ ] App launches on first run without crashing or hanging
- [ ] Deep links / universal links resolve correctly
- [ ] App handles no‑network / offline scenario gracefully
- [ ] All onboarding / login flows function correctly
- [ ] Account deletion flow works and data is actually removed
- [ ] Accessibility: VoiceOver navigation, keyboard‑only navigation, Dynamic Type (if applicable)
- [ ] Localization: all supported languages display correctly; no untranslated strings

### 7.3 Performance & Stability

- [ ] No crashes in Xcode Organizer / crash logs
- [ ] Memory usage stays within acceptable bounds (profile with Instruments → Leaks, Allocations)
- [ ] CPU usage does not spike idle (profile with Instruments → Time Profiler)
- [ ] Disk usage reasonable; temp files cleaned up
- [ ] Energy Impact acceptable (profile with Instruments → Energy Log)
- [ ] App size optimized: bitcode, asset catalogs, slicing, on‑demand resources

### 7.4 TestFlight (Beta Testing)

- [ ] Internal testing group created and build distributed
- [ ] External testing group configured (if applicable — requires Beta App Review)
- [ ] Beta App Description, feedback email, and privacy policy URL set
- [ ] Crash‑free rate acceptable before promotion to release
- [ ] All beta feedback triaged and critical issues resolved

---

## 8. App Review Readiness

### 8.1 Review Notes

- [ ] **Demo account** credentials provided in "App Review Information" if login is required
- [ ] Step‑by‑step instructions for any non‑obvious functionality
- [ ] Backend / server is live and accessible at review time
- [ ] Notes explain any entitlements or special permissions requested

### 8.2 Common Rejection Avoidance

| Rejection Reason                          | Prevention                                                      |
|-------------------------------------------|-----------------------------------------------------------------|
| **Guideline 2.1 — App Completeness**      | No placeholder content, lorem ipsum, or "coming soon" features  |
| **Guideline 2.3 — Accurate Metadata**     | Screenshots, description, and name match actual app behavior    |
| **Guideline 2.1 — Performance: Crashes**  | Thorough testing on all supported hardware                      |
| **Guideline 3.1.1 — IAP Required**        | Digital goods/services use Apple IAP; no links to external pay  |
| **Guideline 4.0 — Design: Minimum**       | App must not be a repackaged website or trivial utility         |
| **Guideline 5.1.1 — Data Collection**     | Privacy nutrition labels match actual behavior                  |
| **Guideline 5.1.1(v) — Account Deletion** | In‑app account deletion available if account creation exists    |
| **Guideline 1.2 — User‑Generated Content**| Moderation, reporting, and blocking features implemented        |

### 8.3 Contact Information

- [ ] First and last name of a real contact person
- [ ] Valid email address reachable during review
- [ ] Valid phone number (with country code) reachable during review

---

## 9. Release Strategy

### 9.1 Pre‑Submission

- [ ] Archive built in Xcode → `Product > Archive`
- [ ] Archive validated: `Xcode Organizer > Validate App` (checks signing, entitlements, symbols)
- [ ] Archive uploaded: `Xcode Organizer > Distribute App > App Store Connect` (or via Transporter)
- [ ] Build appears in App Store Connect under the app's "TestFlight" or "Build" section
- [ ] Build is processed by Apple (status goes from "Processing" to ready)

### 9.2 Release Type

Choose one:

- [ ] **Manual release** — you click "Release This Version" after approval
- [ ] **Automatic release** — goes live immediately upon approval
- [ ] **Scheduled release** — set a specific date/time (must be after expected approval)

### 9.3 Phased Release (Optional)

- [ ] Enable phased release for automatic updates (rolls out over 7 days):
  - Day 1: 1% · Day 2: 2% · Day 3: 5% · Day 4: 10% · Day 5: 20% · Day 6: 50% · Day 7: 100%
- [ ] Monitor crash rates and feedback at each phase
- [ ] Pause or halt the rollout if critical issues emerge

### 9.4 Version Submission

- [ ] Select the processed build in App Store Connect
- [ ] All metadata fields completed (see Section 5)
- [ ] All compliance questions answered (see Section 6)
- [ ] App Review Information filled out (see Section 8)
- [ ] Click "Submit for Review"
- [ ] Status moves to "Waiting for Review" → "In Review" → "Approved" (or "Rejected")

---

## 10. Post‑Launch

### 10.1 Monitoring

- [ ] **Crash reports** monitored in Xcode Organizer or third‑party tool (Sentry, Crashlytics, etc.)
- [ ] **App Store ratings & reviews** monitored; respond to critical feedback
- [ ] **App Analytics** reviewed in App Store Connect: impressions, product page views, downloads, proceeds
- [ ] **Sales and Trends** reports checked
- [ ] Server‑side logs and APM monitored for backend issues

### 10.2 Post‑Release Actions

- [ ] Verify the live listing: screenshots, description, pricing are correct
- [ ] Test a fresh download from the Mac App Store on a clean machine
- [ ] Validate auto‑update flow for existing users (if applicable)
- [ ] Announce the release (website, social media, newsletter, press)
- [ ] Submit app for **App Store editorial consideration** (optional; forms available at developer.apple.com)

### 10.3 Ongoing Maintenance

- [ ] Plan regular updates to maintain compatibility with new macOS releases
- [ ] Update privacy nutrition labels when data practices change
- [ ] Renew Apple Developer Program membership before expiration
- [ ] Rotate / renew certificates and provisioning profiles before expiration (5‑year lifecycle)
- [ ] Monitor Apple Developer News and WWDC announcements for guideline and API changes
- [ ] Archive dSYMs for every release build (needed for crash symbolication)

---

## Appendix — Quick‑Reference Tables

### A. Certificate Types

| Certificate                  | Use Case                             | Required For         |
|------------------------------|--------------------------------------|----------------------|
| Mac App Distribution         | Signing apps for Mac App Store       | App Store submission |
| Mac Installer Distribution   | Signing `.pkg` installer for upload  | App Store submission |
| Developer ID Application     | Signing apps for direct distribution | Outside App Store    |
| Developer ID Installer       | Signing `.pkg` for direct distro     | Outside App Store    |
| Apple Development            | Development / debugging on device    | Local development    |

### B. Mac App Store Screenshot Dimensions

| Display              | Resolution (px) | Type       | Status          |
|----------------------|-----------------|------------|-----------------|
| MacBook Pro 15/16″   | 2880 × 1800     | Retina     | **Recommended** |
| MacBook Pro 13/14″   | 2560 × 1600     | Retina     | Accepted        |
| MacBook Air (legacy) | 1440 × 900      | Non‑Retina | Accepted        |
| Legacy displays      | 1280 × 800      | Non‑Retina | Minimum         |

> Aspect ratio: **16:10** · Format: PNG / JPEG · RGB · No transparency · ≤ 10 MB each · 1–10 per localization

### C. Key `Info.plist` Entries

| Key                                  | Purpose                                    |
|--------------------------------------|--------------------------------------------|
| `CFBundleIdentifier`                 | Must match App Store Connect App ID        |
| `CFBundleShortVersionString`         | Marketing version (e.g., `1.2.0`)          |
| `CFBundleVersion`                    | Build number; unique per upload            |
| `LSMinimumSystemVersion`             | Minimum macOS version                      |
| `LSApplicationCategoryType`          | App category for the Mac App Store         |
| `ITSAppUsesNonExemptEncryption`      | Encryption compliance declaration          |
| `NSUserTrackingUsageDescription`     | ATT prompt string (if tracking)            |
| `NSCameraUsageDescription`           | Camera access justification                |
| `NSMicrophoneUsageDescription`       | Microphone access justification            |
| `NSAppleEventsUsageDescription`      | Apple Events / automation justification    |

### D. Useful CLI Commands

```bash
# Verify code signature
codesign --verify --deep --strict /path/to/YourApp.app

# Display signature details
codesign -dvvv /path/to/YourApp.app

# Check Gatekeeper acceptance
spctl --assess --type execute /path/to/YourApp.app

# Notarize (direct distribution)
xcrun notarytool submit YourApp.zip \
  --apple-id "you@example.com" \
  --team-id XXXXXXXXXX \
  --password @keychain:AC_PASSWORD --wait

# Staple notarization ticket
xcrun stapler staple YourApp.app

# Check provisioning profile contents
security cms -D -i /path/to/embedded.provisionprofile
