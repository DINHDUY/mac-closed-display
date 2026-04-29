# Specification: Closed-Display Utility

## 1. Overview
Closed-Display is a macOS utility for Apple Silicon that prevents the Mac from sleeping when the lid is closed. It uses a split-process architecture: a sandboxed Main UI app manages session state and monitors thermal conditions, while a root-privileged Helper Tool executes `pmset` commands and manages IOKit assertions. The application detects lid closure via IOKit registry notifications on `AppleClamshellState`, disables sleep via `pmset -a disablesleep 1`, creates an IOPMAssertion to prevent idle sleep, dims the internal display to 0% backlight, and monitors for thermal emergencies to trigger an immediate kill-switch. It also survives power adapter toggles by re-asserting `disablesleep` when the session is active.

## 2. Functional Requirements
- [FR-01] Detect AppleClamshellState via IOKit registry notification (not polling)
- [FR-02] On session start: create IOPMAssertion (kIOPMAssertionTypeNoIdleSleep) and execute `pmset -a disablesleep 1`
- [FR-03] On clamshell close (lid closed): force internal display backlight to 0% via DisplayServicesSetBrightness
- [FR-04] On clamshell open (lid open): revert pmset to `disablesleep 0`, release IOPMAssertion, restore display brightness
- [FR-05] On power source change (AC/Battery transition): re-assert pmset disablesleep if session is active
- [FR-06] On thermal state .serious or .critical: immediately revert all overrides, release assertions, trigger sleep, and stop monitoring
- [FR-07] On app termination (quit or crash): clean up all overrides (pmset revert, assertion release, brightness restore)
- [FR-08] Main UI must display current session state, thermal state, power source, and active assertions
- [FR-09] Helper Tool must validate all incoming XPC messages and reject malformed or unauthorized requests
- [FR-10] Graceful degradation: if IOKit clamshell detection is unavailable (desktop Mac), the app must operate in desktop mode without crashing

## 3. Non-Functional Requirements

### 3.1 Performance Targets
| Metric | Target | Unit | Measurement Method |
|--------|--------|------|--------------------|
| Clamshell detection latency | <100 | ms | IOKit notification to action |
| XPC IPC control message latency | <10 | ms | UI->Helper->UI round-trip |
| pmset execution time | <50 | ms | Process launch to exit |
| Thermal event handling latency | <10 | ms | Notification to action |
| Peak memory (RSS) | <50 | MB | mach_task_basic_info |
| XPC message handling time | <1 | ms | XPC handler duration |

### 3.2 Correctness Targets
- All unit tests must pass (state machine, IOKit wrappers, XPC encoding)
- All property-based tests must pass (thermal kill-switch logic)
- No undefined behavior or unhandled exceptions in any code path
- State machine transitions must be deterministic and complete

### 3.3 Reliability Targets
- Must survive power adapter toggles on Apple Silicon (M1/M2/M3/M4)
- Must survive powerd daemon resets of `disablesleep` flag
- Must handle IOKit service port failures gracefully (no crashes)
- Deterministic cleanup on all exit paths (normal quit, crash, thermal kill-switch)

## 4. API Design

```swift
// MARK: - Core State Machine

/// Session state machine for Closed-Display
enum SessionState: Int8 {
    case idle = 0       // No active session
    case clamshellActive = 1  // Lid closed, overrides active
    case thermalEmergency = 2 // Thermal kill-switch triggered
    case cleanupPending = 3   // Cleanup in progress
}

/// Thermal state mapping from ProcessInfo
enum ThermalLevel: Int8 {
    case nominal = 0
    case fair = 1
    case serious = 2
    case critical = 3
}

/// Power source type
enum PowerSource: Int8 {
    case battery = 0
    case acPowered = 1
    case unknown = 2
}

// MARK: - Session Manager

class SessionManager {
    /// Initialize the session manager with delegate callbacks
    init(delegate: SessionManagerDelegate?)

    /// Start the clamshell monitoring session
    func startSession()

    /// End the clamshell monitoring session (cleanup all overrides)
    func endSession()

    /// Get current session state
    var currentState: SessionState { get }

    /// Get current thermal level
    var currentThermalLevel: ThermalLevel { get }

    /// Get current power source
    var currentPowerSource: PowerSource { get }
}

protocol SessionManagerDelegate: AnyObject {
    func sessionManager(_ manager: SessionManager, didTransitionTo state: SessionState)
    func sessionManager(_ manager: SessionManager, didChangeThermalTo level: ThermalLevel)
    func sessionManager(_ manager: SessionManager, didChangePowerSourceTo source: PowerSource)
}

// MARK: - IOKit Wrappers

struct IOKitServices {
    /// Get the clamshell state from the power root domain
    static func getClamshellState() -> Bool?

    /// Cache the power root domain service port
    static func cachePowerRootDomain() -> Bool

    /// Cache the internal display service port
    static func cacheInternalDisplay() -> Bool

    /// Set display brightness (0.0 to 1.0)
    static func setDisplayBrightness(_ brightness: Float) -> Bool

    /// Release all cached service ports
    static func releaseAll()
}

// MARK: - Power Manager

class PowerManager {
    /// Create an IOPMAssertion to prevent idle sleep
    func createAssertion() -> IOPMAssertionID?

    /// Release an IOPMAssertion by ID
    func releaseAssertion(_ assertionID: IOPMAssertionID) -> Bool

    /// Execute pmset to disable sleep
    static func disableSleep() -> Bool

    /// Execute pmset to re-enable sleep
    static func enableSleep() -> Bool
}

// MARK: - XPC Helper

class HelperClient {
    /// Connect to the privileged helper tool
    static func connect() -> HelperClient?

    /// Send a command to the helper and receive a response
    func sendCommand(_ command: HelperCommand) async throws -> HelperResponse

    /// Disconnect from the helper
    func disconnect()
}

enum HelperCommand: Int32 {
    case enableSleep = 1
    case disableSleep = 2
    case createAssertion = 3
    case releaseAssertion = 4
    case checkStatus = 5
}

enum HelperResponse: Int32 {
    case success = 0
    case failure = 1
    case invalidCommand = 2
    case unauthorized = 3
}

// MARK: - Thermal Monitor

class ThermalMonitor {
    /// Start monitoring thermal state changes
    func startMonitoring(delegate: ThermalDelegate?)

    /// Stop monitoring
    func stopMonitoring()
}

protocol ThermalDelegate: AnyObject {
    func thermalMonitor(_ monitor: ThermalMonitor, didChangeTo level: ThermalLevel)
}

// MARK: - Power Source Monitor

class PowerSourceMonitor {
    /// Start monitoring power source changes
    func startMonitoring(delegate: PowerSourceDelegate?)

    /// Stop monitoring
    func stopMonitoring()
}

protocol PowerSourceDelegate: AnyObject {
    func powerSourceMonitor(_ monitor: PowerSourceMonitor, didChangeTo source: PowerSource)
}
```

## 5. Edge Cases
- [EDGE-01] Desktop Mac with no clamshell state: detect absence and operate in desktop mode
- [EDGE-02] IOKit service port is 0 (service not found): graceful degradation, no crash
- [EDGE-03] Helper tool is not installed or SMJobBless failed: show user-facing error, disable privileged operations
- [EDGE-04] Thermal state transitions: nominal -> fair -> serious -> critical (each transition must be handled)
- [EDGE-05] Rapid lid close/open cycles: debounce with 500ms minimum interval to prevent oscillation
- [EDGE-06] Power adapter toggled during active session: re-assert pmset disablesleep immediately
- [EDGE-07] Multiple external displays connected: offer clamshell optimization mode for M3/M4 base chips
- [EDGE-08] App termination during pmset execution: use defer blocks to guarantee cleanup
- [EDGE-09] XPC connection lost during active session: attempt reconnection, fall back to local assertions if helper unavailable
- [EDGE-10] Display not found via IOKit: skip backlight control, continue with sleep overrides only

## 6. Constraints
- macOS 14+ on Apple Silicon only (M1/M2/M3/M4)
- Helper tool installed via SMJobBless with proper code signatures
- All cleanup must happen on all exit paths
- Thermal kill-switch mandatory, no user override
- Sandbox-compatible operations only
- Clamshell detection <100ms, XPC IPC <10ms, peak memory <50MB

## 7. Acceptance Criteria
- [ ] All functional requirements implemented (FR-01 through FR-10)
- [ ] All performance targets met (Section 3.1)
- [ ] All edge cases handled (EDGE-01 through EDGE-10)
- [ ] All tests passing (state machine, IOKit wrappers, thermal logic, XPC encoding)
- [ ] No anti-pattern violations (per constitution BAN-01 through BAN-08)
- [ ] Thermal kill-switch tested with all thermal state combinations
- [ ] Cleanup verified on all exit paths (normal quit, crash simulation, thermal emergency)

## 8. Loop B History
[Initial implementation -- no history yet]
