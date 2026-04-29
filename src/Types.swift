// MARK: - Types.swift
// Core type definitions for Closed-Display.
// Int8 enums for compact memory layout (DATA-01, PERF-07).
// All constants defined as static let (CONV-07).

import Foundation

// MARK: - Session State Machine

/// Session state machine for Closed-Display
/// Uses Int8 for compact representation (DATA-01, PERF-07)
enum SessionState: Int8 {
    case idle = 0                      // No active session
    case clamshellActive = 1           // Lid closed, overrides active
    case thermalEmergency = 2          // Thermal kill-switch triggered
    case cleanupPending = 3            // Cleanup in progress
}

/// Thermal state mapping from ProcessInfo
/// Uses Int8 for compact representation (DATA-01)
enum ThermalLevel: Int8 {
    case nominal = 0
    case fair = 1
    case serious = 2
    case critical = 3
}

/// Power source type
/// Uses Int8 for compact representation (DATA-01)
enum PowerSource: Int8 {
    case battery = 0
    case acPowered = 1
    case unknown = 2
}

/// IOPMAssertionID type alias for clarity
typealias IOPMAssertionID = UInt32

// MARK: - Constants

/// All magic strings/paths defined as static let (CONV-07)
struct Constants {
    // MARK: pmset
    static let pmsetPath = "/usr/bin/pmset"

    // MARK: IOKit
    static let powerRootDomainName = "IOPMrootDomain"
    static let clamshellStateProperty = "AppleClamshellState"
    static let internalDisplayName = "AppleBacklightDisplay"

    // MARK: IOPMAssertion
    static let assertionName = "com.closed-display.no-idle-sleep"
    static let assertionType = "NoIdleSleep"
    static let assertionCategory = "com.closed-display"

    // MARK: XPC
    static let xpcServiceName = "com.closed-display.helper"

    // MARK: Debounce
    static let debounceInterval: Double = 0.5  // 500ms

    // MARK: Dispatch Queue Labels (CONV-06)
    static let sessionQueueLabel = "com.closed-display.session"
    static let thermalQueueLabel = "com.closed-display.thermal"
    static let helperQueueLabel = "com.closed-display.helper"

    // MARK: XPC Timeout (OPT-07)
    static let xpcTimeout: TimeInterval = 5.0
}
