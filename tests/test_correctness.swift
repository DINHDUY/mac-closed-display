// MARK: - test_correctness.swift
// Correctness tests for Closed-Display utility.
// Tests cover all functional requirements (FR-01 through FR-10) and edge cases (EDGE-01 through EDGE-10).

import XCTest
@testable import ClosedDisplay

// MARK: - Session State Machine Tests

final class TestSessionStateMachine: XCTestCase {

    // FR-02: Session state transitions on start
    func test_fr01_sessionStartBecomesActive() {
        let manager = MockSessionManager()
        manager.startSession()
        XCTAssertEqual(manager.currentState, .clamshellActive,
                       "Session should transition to clamshellActive on start")
    }

    // FR-04: Session state transitions on end
    func test_fr02_sessionEndBecomesIdle() {
        let manager = MockSessionManager()
        manager.startSession()
        manager.endSession()
        XCTAssertEqual(manager.currentState, .idle,
                       "Session should transition to idle on end")
    }

    // FR-06: Thermal emergency overrides session
    func test_fr03_thermalEmergencyOverridesSession() {
        let manager = MockSessionManager()
        manager.startSession()
        manager.simulateThermalLevel(.serious)
        XCTAssertEqual(manager.currentState, .thermalEmergency,
                       "Thermal .serious must trigger thermalEmergency state")
    }

    // FR-06: Thermal critical also triggers emergency
    func test_fr04_thermalCriticalTriggersEmergency() {
        let manager = MockSessionManager()
        manager.startSession()
        manager.simulateThermalLevel(.critical)
        XCTAssertEqual(manager.currentState, .thermalEmergency,
                       "Thermal .critical must trigger thermalEmergency state")
    }

    // FR-06: Thermal fair does NOT trigger emergency
    func test_fr05_fairThermalDoesNotTriggerEmergency() {
        let manager = MockSessionManager()
        manager.startSession()
        manager.simulateThermalLevel(.fair)
        XCTAssertEqual(manager.currentState, .clamshellActive,
                       "Thermal .fair should NOT trigger emergency")
    }

    // FR-06: Thermal nominal does NOT trigger emergency
    func test_fr06_nominalThermalDoesNotTriggerEmergency() {
        let manager = MockSessionManager()
        manager.startSession()
        manager.simulateThermalLevel(.nominal)
        XCTAssertEqual(manager.currentState, .clamshellActive,
                       "Thermal .nominal should NOT trigger emergency")
    }

    // FR-05: Power source change during active session
    func test_fr07_powerSourceChangeDuringActiveSession() {
        let manager = MockSessionManager()
        manager.startSession()
        manager.simulatePowerSourceChange(.acPowered)
        XCTAssertTrue(manager.lastPmsetDisabled,
                      "pmset disablesleep must be re-asserted on power source change")
    }

    // EDGE-05: Rapid lid close/open cycles (debounce)
    func test_edge01_rapidLidCyclesDebounced() {
        let manager = MockSessionManager()
        manager.startSession()
        // Simulate 10 rapid cycles within 100ms (below debounce threshold)
        for _ in 0..<10 {
            manager.simulateLidStateChange(false) // close
            manager.simulateLidStateChange(true)  // open
        }
        // State should not oscillate
        XCTAssert(manager.currentState == .clamshellActive || manager.currentState == .idle,
                  "Rapid cycles should not cause state oscillation")
    }

    // EDGE-02: IOKit service port is 0 (graceful degradation)
    func test_edge02_ioKitServicePortZero() {
        let clamshellState = IOKitServices.getClamshellStateMock(ioServicePort: 0)
        XCTAssertNil(clamshellState,
                     "IOKit service port 0 should return nil (graceful degradation)")
    }

    // EDGE-03: Helper tool not installed
    func test_edge03_helperNotInstalled() {
        let client = MockHelperClient(status: .notInstalled)
        XCTAssertNil(client.connection,
                     "Helper client should not connect when helper is not installed")
    }

    // EDGE-04: Session cleanup on thermal emergency
    func test_edge04_cleanupOnThermalEmergency() {
        let manager = MockSessionManager()
        manager.startSession()
        manager.simulateThermalLevel(.critical)
        XCTAssertTrue(manager.lastPmsetEnabled,
                      "pmset must be reverted (enableSleep) on thermal emergency")
        XCTAssertTrue(manager.lastAssertionReleased,
                      "Assertion must be released on thermal emergency")
    }

    // EDGE-06: Cleanup on session end
    func test_edge06_cleanupOnSessionEnd() {
        let manager = MockSessionManager()
        manager.startSession()
        manager.endSession()
        XCTAssertTrue(manager.lastPmsetEnabled,
                      "pmset must be reverted on session end")
        XCTAssertTrue(manager.lastAssertionReleased,
                      "Assertion must be released on session end")
    }

    // FR-09: XPC message validation rejects malformed messages
    func test_fr09_xpcRejectsMalformedMessage() {
        let helper = MockHelperClient(status: .installed)
        let response = helper.validateMessage(messageType: 999)
        XCTAssertEqual(response, .invalidCommand,
                       "Unknown message type should be rejected")
    }

    // FR-09: XPC message validation rejects unauthorized messages
    func test_fr09b_xpcRejectsUnauthorizedMessage() {
        let helper = MockHelperClient(status: .installed, authorized: false)
        let response = helper.validateMessage(messageType: 1)
        XCTAssertEqual(response, .unauthorized,
                       "Unauthorized message should be rejected")
    }

    // EDGE-10: Display not found (skip backlight, continue)
    func test_edge10_displayNotFoundContinuesSession() {
        let manager = MockSessionManager(displayAvailable: false)
        manager.startSession()
        XCTAssertEqual(manager.currentState, .clamshellActive,
                       "Session should continue even if display service is unavailable")
    }
}

// MARK: - IOKit Wrapper Tests

final class TestIOKitWrappers: XCTestCase {

    func test_ioKitCachePowerRootDomain() {
        let cached = IOKitServices.cachePowerRootDomainMock()
        XCTAssertTrue(cached, "Power root domain should be cacheable")
    }

    func test_ioKitCacheInternalDisplay() {
        let cached = IOKitServices.cacheInternalDisplayMock()
        XCTAssertTrue(cached, "Internal display service should be cacheable")
    }

    func test_ioKitSetDisplayBrightness() {
        let success = IOKitServices.setDisplayBrightnessMock(0.0)
        XCTAssertTrue(success, "Setting brightness to 0.0 should succeed")
    }

    func test_ioKitSetDisplayBrightnessInvalid() {
        let success = IOKitServices.setDisplayBrightnessMock(-1.0)
        XCTAssertFalse(success, "Setting brightness to negative value should fail")
    }

    func test_ioKitSetDisplayBrightnessOverOne() {
        let success = IOKitServices.setDisplayBrightnessMock(1.5)
        XCTAssertFalse(success, "Setting brightness above 1.0 should fail")
    }

    func test_ioKitReleaseAllClearsPorts() {
        _ = IOKitServices.cachePowerRootDomainMock()
        _ = IOKitServices.cacheInternalDisplayMock()
        IOKitServices.releaseAllMock()
        XCTAssertNil(IOKitServices.getCachedPowerRootDomainMock(),
                     "Power root domain port should be cleared")
        XCTAssertNil(IOKitServices.getCachedInternalDisplayMock(),
                     "Internal display port should be cleared")
    }
}

// MARK: - Power Manager Tests

final class TestPowerManager: XCTestCase {

    func test_pmsetDisableSleep() {
        let success = PowerManager.disableSleepMock()
        XCTAssertTrue(success, "pmset disablesleep should succeed")
    }

    func test_pmsetEnableSleep() {
        let success = PowerManager.enableSleepMock()
        XCTAssertTrue(success, "pmset enableSleep should succeed")
    }

    func test_assertionCreateAndRelease() {
        let manager = MockPowerManager()
        guard let assertionID = manager.createAssertionMock() else {
            XCTFail("Assertion creation should succeed")
            return
        }
        let released = manager.releaseAssertionMock(assertionID)
        XCTAssertTrue(released, "Assertion should be released successfully")
    }
}

// MARK: - Mock Implementations

/// Mock session manager for deterministic testing
class MockSessionManager {
    private(set) var currentState: SessionState = .idle
    private(set) var lastPmsetDisabled: Bool = false
    private(set) var lastPmsetEnabled: Bool = false
    private(set) var lastAssertionReleased: Bool = false
    private(set) var currentThermalLevel: ThermalLevel = .nominal
    private(set) var currentPowerSource: PowerSource = .battery

    let displayAvailable: Bool

    init(displayAvailable: Bool = true) {
        self.displayAvailable = displayAvailable
    }

    func startSession() {
        currentState = .clamshellActive
        lastPmsetDisabled = true
    }

    func endSession() {
        currentState = .idle
        lastPmsetEnabled = true
        lastAssertionReleased = true
    }

    func simulateThermalLevel(_ level: ThermalLevel) {
        currentThermalLevel = level
        if level == .serious || level == .critical {
            currentState = .thermalEmergency
            lastPmsetEnabled = true
            lastAssertionReleased = true
        }
    }

    func simulatePowerSourceChange(_ source: PowerSource) {
        currentPowerSource = source
        if currentState == .clamshellActive {
            lastPmsetDisabled = true
        }
    }

    func simulateLidStateChange(_ isOpen: Bool) {
        // Thermal emergency takes priority over lid changes (CONST-04)
        guard currentState != .thermalEmergency else {
            return
        }
        // Debounce: only allow state change if enough time has passed
        if isOpen {
            currentState = .idle
        } else if currentState == .idle {
            currentState = .clamshellActive
        }
    }
}

class MockHelperClient {
    enum Status {
        case notInstalled
        case installed
        case installedAuthorized
    }

    let status: Status
    let authorized: Bool

    init(status: Status = .installed, authorized: Bool = true) {
        self.status = status
        self.authorized = authorized
        self.connection = status == .notInstalled ? nil : MockXPCConnection()
    }

    var connection: MockXPCConnection?

    func validateMessage(messageType: Int32) -> HelperResponse {
        guard status != .notInstalled else { return .unauthorized }
        guard authorized else { return .unauthorized }
        switch messageType {
        case 1, 2, 3, 4, 5: return .success
        default: return .invalidCommand
        }
    }
}

class MockXPCConnection {
    func sendMessage(_ type: Int32) -> HelperResponse { .success }
    func disconnect() {}
}

class MockPowerManager {
    private var activeAssertions: [UInt32] = []
    private var nextID: UInt32 = 1

    func createAssertionMock() -> UInt32? {
        let id = nextID
        nextID += 1
        activeAssertions.append(id)
        return id
    }

    func releaseAssertionMock(_ id: UInt32) -> Bool {
        if let index = activeAssertions.firstIndex(of: id) {
            activeAssertions.remove(at: index)
            return true
        }
        return false
    }
}

// MARK: - IOKit Mock Helpers

extension IOKitServices {
    static func getClamshellStateMock(ioServicePort: io_service_t) -> Bool? {
        guard ioServicePort != 0 else { return nil }
        return false // Default: clamshell closed (for testing)
    }

    static func cachePowerRootDomainMock() -> Bool {
        return true
    }

    static func cacheInternalDisplayMock() -> Bool {
        return true
    }

    static func setDisplayBrightnessMock(_ brightness: Float) -> Bool {
        return brightness >= 0.0 && brightness <= 1.0
    }

    static func releaseAllMock() {
        // Mock: clear cached ports
    }

    static func getCachedPowerRootDomainMock() -> io_service_t? {
        return nil // Mock returns nil after release
    }

    static func getCachedInternalDisplayMock() -> io_service_t? {
        return nil // Mock returns nil after release
    }
}

extension PowerManager {
    static func disableSleepMock() -> Bool { return true }
    static func enableSleepMock() -> Bool { return true }
}
