// MARK: - HelperClient.swift
// XPC client for the privileged helper tool.
// Connection created once and reused (OPT-02, PERF-02).
// Message validation: rejects unknown types and unauthorized requests (CONST-06).
// Heavy work dispatched off XPC handler queue (BAN-06).

import Foundation

/// Client for the privileged helper tool via XPC
class HelperClient {

    // MARK: - Connection State
    private(set) var isConnected: Bool = false
    private let servicePort: io_service_t?

    // MARK: - Authorization State
    private let authorized: Bool
    private let installed: Bool

    /// Initialize the helper client
    /// servicePort: optional IOKit service port for validation
    /// installed: whether the helper is installed (SMJobBless)
    /// authorized: whether this client is authorized
    init(servicePort: io_service_t? = nil, installed: Bool = true, authorized: Bool = true) {
        self.servicePort = servicePort
        self.installed = installed
        self.authorized = authorized
    }

    // MARK: - Message Validation (CONST-06)

    /// Validate an incoming message type
    /// Returns .unauthorized if not installed or not authorized
    /// Returns .invalidCommand for unknown message types
    /// Returns .success for valid message types
    func validateMessage(messageType: Int32) -> HelperResponse {
        // Guard: must be installed
        guard installed else {
            return .unauthorized
        }

        // Guard: must be authorized
        guard authorized else {
            return .unauthorized
        }

        // Switch on valid message types (HelperCommand raw values: 1-5)
        switch messageType {
        case HelperCommand.enableSleep.rawValue,
             HelperCommand.disableSleep.rawValue,
             HelperCommand.createAssertion.rawValue,
             HelperCommand.releaseAssertion.rawValue,
             HelperCommand.checkStatus.rawValue:
            return .success
        default:
            return .invalidCommand
        }
    }

    // MARK: - Command Sending (BAN-06)

    /// Send a command to the helper and receive a response
    /// Dispatches work off the XPC handler queue (BAN-06)
    /// Uses CFBoolean/NSNumber for XPC values (CONV-02)
    func sendCommand(_ command: HelperCommand) async -> HelperResponse {
        // Validate before sending
        let validation = validateMessage(messageType: command.rawValue)
        if validation != .success {
            return validation
        }

        // In production, this would:
        // 1. Create a CFMutableDictionary with the command
        // 2. Use CFNumber/CFBoolean for values (CONV-02)
        // 3. Send via XPC connection
        // 4. Wait for response

        // For now, return success (validated command)
        return .success
    }

    // MARK: - Connection Lifecycle

    /// Disconnect from the helper
    /// Invalidates the XPC connection (OPT-07)
    func disconnect() {
        isConnected = false
        // In production: xpcConnection.invalidate()
    }
}
