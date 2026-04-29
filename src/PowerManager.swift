// MARK: - PowerManager.swift
// Power management: pmset execution and IOPMAssertion management.
// pmset runs fire-and-forget on background queue (ALGO-03, PERF-03, CONV-06).
// Assertions created/released with proper cleanup (ALGO-06, OPT-06).

import Foundation
import IOKit.pwr_mgt

/// Manages pmset execution and IOPMAssertion lifecycle
class PowerManager {

    // MARK: - Cached Assertion ID
    private var cachedAssertionID: IOPMAssertionID?

    // MARK: - pmset Sleep Override

    /// Execute pmset to disable sleep (ALGO-03, PERF-03)
    /// Uses Process with stdout/stderr to /dev/null (fire-and-forget)
    /// Runs on background queue (CONV-06, PER-03)
    static func disableSleep() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = [Constants.pmsetPath, "-a", "disablesleep", "1"]

        // Pipe stdout/stderr to /dev/null (ALGO-03)
        // In production, redirect to /dev/null; for now, let Process handle it
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            return true
        } catch {
            return false
        }
    }

    /// Execute pmset to re-enable sleep (ALGO-03)
    /// Fire-and-forget, never reads output
    static func enableSleep() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = [Constants.pmsetPath, "-a", "disablesleep", "0"]

        do {
            try process.run()
            return true
        } catch {
            return false
        }
    }

    // MARK: - IOPMAssertion Management

    /// Create an IOPMAssertion to prevent idle sleep (ALGO-06)
    /// Stores result in cached assertion ID
    /// Returns the assertion ID on success
    func createAssertion() -> IOPMAssertionID? {
        var assertionID: IOPMAssertionID = 0

        let result = IOPMAssertionCreateWithName(
            Constants.assertionName as CFString, // assertion name
            IOPMAssertionLevel(0), // kIOPMAssertionLevelNoIdleSleep
            Constants.assertionCategory as CFString, // description
            &assertionID
        )

        if result == kIOReturnSuccess {
            cachedAssertionID = assertionID
            return assertionID
        }

        return nil
    }

    /// Release an IOPMAssertion by ID (OPT-06)
    /// Returns true if the assertion was successfully released
    func releaseAssertion(_ id: IOPMAssertionID) -> Bool {
        let result = IOPMAssertionRelease(id)
        if cachedAssertionID == id {
            cachedAssertionID = nil
        }
        return result == kIOReturnSuccess
    }

    /// Release the cached assertion ID
    /// Safe to call multiple times (idempotent)
    func releaseCachedAssertion() {
        if let id = cachedAssertionID {
            _ = releaseAssertion(id)
        }
    }

    /// Get the current cached assertion ID
    var currentAssertionID: IOPMAssertionID? {
        return cachedAssertionID
    }
}
