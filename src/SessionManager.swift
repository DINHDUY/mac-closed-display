// MARK: - SessionManager.swift
// Core session state machine for Closed-Display.
// Enum-driven state machine with explicit Int8 transitions (DATA-01).
// Event-driven, no polling (PERF-01, BAN-01).
// Thermal kill-switch mandatory (CONST-04, BAN-07).

import Foundation

/// Protocol for SessionManager callbacks
protocol SessionManagerDelegate: AnyObject {
    func sessionManager(_ manager: SessionManager, didTransitionTo state: SessionState)
    func sessionManager(_ manager: SessionManager, didChangeThermalTo level: ThermalLevel)
    func sessionManager(_ manager: SessionManager, didChangePowerSourceTo source: PowerSource)
}

/// Session manager implementing the full state machine
/// Coordinates with IOKitServices and PowerManager
class SessionManager {

    // MARK: - State Properties (DATA-01)
    private(set) var currentState: SessionState = .idle
    private(set) var currentThermalLevel: ThermalLevel = .nominal
    private(set) var currentPowerSource: PowerSource = .battery

    // MARK: - Dependencies
    private let powerManager = PowerManager()
    private weak var delegate: SessionManagerDelegate?

    // MARK: - Display Availability
    let displayAvailable: Bool

    // MARK: - Debounce Tracking (EDGE-05)
    private var lastLidChange: TimeInterval = 0

    // MARK: - Initialization

    /// Initialize the session manager with delegate callbacks
    init(delegate: SessionManagerDelegate? = nil, displayAvailable: Bool = true) {
        self.delegate = delegate
        self.displayAvailable = displayAvailable
    }

    // MARK: - Session Lifecycle

    /// Start the clamshell monitoring session (FR-02)
    /// Creates IOPMAssertion, disables sleep, caches IOKit services
    func startSession() {
        // Transition to active state
        let previousState = currentState
        currentState = .clamshellActive

        // Cache IOKit service ports (OPT-01)
        _ = IOKitServices.cachePowerRootDomain()
        if displayAvailable {
            _ = IOKitServices.cacheInternalDisplay()
        }

        // Disable sleep via pmset (ALGO-03)
        _ = PowerManager.disableSleep()

        // Create idle sleep assertion (ALGO-06)
        _ = powerManager.createAssertion()

        // Notify delegate
        if previousState != currentState {
            delegate?.sessionManager(self, didTransitionTo: currentState)
        }
    }

    /// End the clamshell monitoring session (FR-04, CONST-05)
    /// Reverts all overrides, releases assertions, clears IOKit services
    func endSession() {
        // Re-enable sleep (ALGO-03)
        _ = PowerManager.enableSleep()

        // Release assertion (OPT-06)
        powerManager.releaseCachedAssertion()

        // Clear IOKit service ports (OPT-06)
        IOKitServices.releaseAll()

        // Transition to idle
        currentState = .idle

        // Notify delegate
        delegate?.sessionManager(self, didTransitionTo: currentState)
    }

    // MARK: - Thermal Handling (FR-06, CONST-04, BAN-07)

    /// Handle thermal level change
    /// .serious or .critical triggers thermal emergency (CONST-04)
    /// Other states update thermal level without state change
    func handleThermalLevel(_ level: ThermalLevel) {
        currentThermalLevel = level
        delegate?.sessionManager(self, didChangeThermalTo: level)

        // Thermal kill-switch: mandatory (CONST-04, BAN-07)
        guard level == .serious || level == .critical else {
            // Fair/nominal: no state change, just update level
            return
        }

        // Thermal emergency: immediate cleanup (CONST-04)
        let previousState = currentState
        currentState = .thermalEmergency

        // Re-enable sleep immediately
        _ = PowerManager.enableSleep()

        // Release assertion
        powerManager.releaseCachedAssertion()

        // Notify delegate
        if previousState != currentState {
            delegate?.sessionManager(self, didTransitionTo: currentState)
        }
    }

    // MARK: - Power Source Handling (FR-05)

    /// Handle power source change
    /// Re-asserts pmset disablesleep if session is active (FR-05)
    /// Does nothing for non-active states
    func handlePowerSourceChange(_ source: PowerSource) {
        currentPowerSource = source
        delegate?.sessionManager(self, didChangePowerSourceTo: source)

        // Only re-assert when clamshell is active (FR-05)
        guard currentState == .clamshellActive else {
            return
        }

        // Re-assert pmset disablesleep (survives powerd resets on Apple Silicon)
        _ = PowerManager.disableSleep()
    }

    // MARK: - Lid State Handling (FR-03, FR-04, EDGE-05)

    /// Handle lid state change with debounce (EDGE-05)
    /// Debounce interval: 500ms to prevent oscillation
    func handleLidStateChange(_ isOpen: Bool) {
        let now = Date().timeIntervalSince1970
        let elapsed = now - lastLidChange

        // Debounce: skip if less than 500ms since last change (EDGE-05)
        if elapsed < Constants.debounceInterval {
            return
        }

        lastLidChange = now

        // If lid is open, end session
        if isOpen {
            currentState = .idle

            // Re-enable sleep
            _ = PowerManager.enableSleep()
            powerManager.releaseCachedAssertion()
            IOKitServices.releaseAll()

            delegate?.sessionManager(self, didTransitionTo: currentState)
        }
        // If lid is closed and we're idle, start session
        else if currentState == .idle {
            currentState = .clamshellActive

            // Disable sleep
            _ = PowerManager.disableSleep()
            _ = powerManager.createAssertion()

            // Dim display if available (FR-03)
            if displayAvailable {
                _ = IOKitServices.setDisplayBrightness(0.0)
            }

            delegate?.sessionManager(self, didTransitionTo: currentState)
        }
        // If in thermal emergency, lid changes don't affect state
        // (thermal emergency takes priority)
    }

    // MARK: - Query Methods

    /// Get the current assertion ID (for debugging/status display)
    var currentAssertionID: IOPMAssertionID? {
        return powerManager.currentAssertionID
    }
}
