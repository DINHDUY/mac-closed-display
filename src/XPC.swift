// MARK: - XPC.swift
// XPC message types for Closed-Display Helper communication.
// Uses Int32 raw values for compact binary encoding (DATA-05).
// All cases have explicit type annotations (CONV-05).

import Foundation

/// XPC commands sent to the privileged helper tool
enum HelperCommand: Int32 {
    case enableSleep = 1
    case disableSleep = 2
    case createAssertion = 3
    case releaseAssertion = 4
    case checkStatus = 5
}

/// XPC responses from the privileged helper tool
enum HelperResponse: Int32 {
    case success = 0
    case failure = 1
    case invalidCommand = 2
    case unauthorized = 3
}
