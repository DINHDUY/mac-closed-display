// MARK: - test_property.swift
// Property-based tests for Closed-Display utility.
// Tests verify invariants across all combinations of thermal state, session state, and power source.

import XCTest
@testable import ClosedDisplay

final class TestPropertyBased: XCTestCase {

    // Property: Thermal kill-switch is idempotent
    // Once in thermalEmergency state, subsequent thermal events keep it there
    func test_property_thermalKillSwitchIdempotent() {
        let manager = MockSessionManager()
        manager.startSession()
        manager.simulateThermalLevel(.serious)

        // Subsequent thermal events should not change the emergency state
        manager.simulateThermalLevel(.critical)
        manager.simulateThermalLevel(.serious)
        manager.simulateThermalLevel(.fair)

        XCTAssertEqual(manager.currentState, .thermalEmergency,
                       "Once thermal emergency is triggered, state should remain emergency")
    }

    // Property: Session start always sets pmset disabled
    func test_property_sessionAlwaysDisablesSleep() {
        let manager = MockSessionManager()

        for _ in 0..<100 {
            manager.startSession()
            XCTAssertTrue(manager.lastPmsetDisabled,
                          "Every session start must disable sleep")
            manager.endSession()
        }
    }

    // Property: Session end always re-enables sleep
    func test_property_sessionAlwaysEnablesSleep() {
        let manager = MockSessionManager()
        manager.startSession()

        for _ in 0..<100 {
            manager.endSession()
            XCTAssertTrue(manager.lastPmsetEnabled,
                          "Every session end must enable sleep")
            manager.startSession()
        }
    }

    // Property: Thermal emergency always re-enables sleep
    func test_property_thermalAlwaysReEnablesSleep() {
        let manager = MockSessionManager()
        manager.startSession()

        let thermalLevels: [ThermalLevel] = [.serious, .critical, .serious, .critical]

        for thermal in thermalLevels {
            manager.simulateThermalLevel(thermal)
            XCTAssertTrue(manager.lastPmsetEnabled,
                          "Every thermal emergency must re-enable sleep")
        }
    }

    // Property: Thermal emergency always releases assertion
    func test_property_thermalAlwaysReleasesAssertion() {
        let manager = MockSessionManager()
        manager.startSession()

        let thermalLevels: [ThermalLevel] = [.nominal, .fair, .serious, .critical]

        for thermal in thermalLevels {
            manager.simulateThermalLevel(thermal)
            if thermal == .serious || thermal == .critical {
                XCTAssertTrue(manager.lastAssertionReleased,
                              "Every thermal emergency must release assertion")
            } else {
                // For non-emergency thermal states, assertion should NOT be released
                XCTAssertFalse(manager.lastAssertionReleased,
                               "Non-emergency thermal states should NOT release assertion")
            }
        }
    }

    // Property: Power source change only re-asserts when session is active
    func test_property_powerSourceChangeOnlyWhenActive() {
        let manager = MockSessionManager()
        // Start in idle state
        manager.simulatePowerSourceChange(.acPowered)
        XCTAssertFalse(manager.lastPmsetDisabled,
                       "Power source change should NOT disable sleep when idle")

        // Start session
        manager.startSession()
        manager.simulatePowerSourceChange(.battery)
        XCTAssertTrue(manager.lastPmsetDisabled,
                      "Power source change MUST disable sleep when clamshell-active")
    }

    // Property: All valid brightness values (0.0 to 1.0) are accepted
    func test_property_brightnessRangeAccepted() {
        let brightnesses: [Float] = [0.0, 0.25, 0.5, 0.75, 1.0]
        for brightness in brightnesses {
            let success = IOKitServices.setDisplayBrightnessMock(brightness)
            XCTAssertTrue(success,
                          "Brightness \(brightness) should be accepted")
        }
    }

    // Property: All invalid brightness values are rejected
    func test_property_brightnessRangeRejected() {
        let brightnesses: [Float] = [-0.1, -1.0, 1.001, 2.0, -10.0, 100.0]
        for brightness in brightnesses {
            let success = IOKitServices.setDisplayBrightnessMock(brightness)
            XCTAssertFalse(success,
                           "Brightness \(brightness) should be rejected")
        }
    }

    // Property: State machine state space is consistent
    // A session in thermalEmergency can only end via explicit endSession
    func test_property_stateSpaceConsistency() {
        let manager = MockSessionManager()
        manager.startSession()
        manager.simulateThermalLevel(.serious)

        // Simulate power source change during thermal emergency
        manager.simulatePowerSourceChange(.acPowered)
        XCTAssertEqual(manager.currentState, .thermalEmergency,
                       "Thermal emergency state should be preserved during power changes")

        // Simulate lid state change during thermal emergency
        manager.simulateLidStateChange(true)
        XCTAssertEqual(manager.currentState, .thermalEmergency,
                       "Thermal emergency state should be preserved during lid changes")
    }

    // Property: IOKit service port 0 always returns nil
    func test_property_ioKitPortZeroAlwaysNil() {
        for _ in 0..<50 {
            let state = IOKitServices.getClamshellStateMock(ioServicePort: 0)
            XCTAssertNil(state,
                         "IOKit service port 0 should always return nil")
        }
    }

    // Property: IOKit service port != 0 always returns a Bool (not nil)
    func test_property_ioKitPortNonZeroAlwaysBool() {
        let validPorts: [io_service_t] = [1, 100, 9999, 123456, 42]
        for port in validPorts {
            let state = IOKitServices.getClamshellStateMock(ioServicePort: port)
            XCTAssertNotNil(state,
                            "Non-zero IOKit service port should always return a Bool")
        }
    }

    // Property: XPC message validation is deterministic
    func test_property_xpcValidationDeterministic() {
        let helper = MockHelperClient()

        let validTypes: [Int32] = [1, 2, 3, 4, 5]
        let invalidTypes: [Int32] = [0, -1, 100, -100, 999]

        for _ in 0..<10 {
            for valid in validTypes {
                XCTAssertEqual(helper.validateMessage(messageType: valid),
                               .success, "Valid type \(valid) should always succeed")
            }
            for invalid in invalidTypes {
                XCTAssertEqual(helper.validateMessage(messageType: invalid),
                               .invalidCommand, "Invalid type \(invalid) should always fail")
            }
        }
    }

    // Property: Power manager assertion IDs are unique
    func test_property_assertionIdsUnique() {
        let manager = MockPowerManager()
        var ids: Set<UInt32> = []

        for _ in 0..<1000 {
            if let id = manager.createAssertionMock() {
                XCTAssertFalse(ids.contains(id), "Assertion ID \(id) must be unique")
                ids.insert(id)
            }
        }

        XCTAssertEqual(ids.count, 1000, "All 1000 assertion IDs should be unique")
    }

    // Property: Release of non-existent assertion fails
    func test_property_releaseNonExistentFails() {
        let manager = MockPowerManager()
        let released = manager.releaseAssertionMock(999999)
        XCTAssertFalse(released, "Releasing non-existent assertion should fail")
    }

    // Property: Double-release of assertion fails
    func test_property_doubleReleaseFails() {
        let manager = MockPowerManager()
        guard let id = manager.createAssertionMock() else {
            XCTFail("Assertion creation should succeed")
            return
        }

        let firstRelease = manager.releaseAssertionMock(id)
        XCTAssertTrue(firstRelease, "First release should succeed")

        let secondRelease = manager.releaseAssertionMock(id)
        XCTAssertFalse(secondRelease, "Double release should fail")
    }
}
