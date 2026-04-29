// MARK: - ClosedDisplay main executable entry point
// Continuously monitors lid state, thermal conditions, and power sources.
// Signal handlers for graceful shutdown (CONST-05, OPT-06).

import Foundation
import IOKit
import IOKit.pwr_mgt

// MARK: - Global Session Manager

var globalSessionManager: SessionManager?
var globalDelegate: SessionDelegate?
var lidStateTimer: Timer?

// MARK: - Session Delegate

/// Handles state change notifications from SessionManager
class SessionDelegate: SessionManagerDelegate {
    func sessionManager(_ manager: SessionManager, didTransitionTo state: SessionState) {
        print("[ClosedDisplay] State -> \(sessionStateName(state))")
    }

    func sessionManager(_ manager: SessionManager, didChangeThermalTo level: ThermalLevel) {
        print("[ClosedDisplay] Thermal -> \(thermalLevelName(level))")
    }

    func sessionManager(_ manager: SessionManager, didChangePowerSourceTo source: PowerSource) {
        print("[ClosedDisplay] Power -> \(powerSourceName(source))")
    }

    private func sessionStateName(_ state: SessionState) -> String {
        switch state {
        case .idle: return "idle"
        case .clamshellActive: return "clamshell_active"
        case .thermalEmergency: return "thermal_emergency"
        case .cleanupPending: return "cleanup_pending"
        }
    }

    private func thermalLevelName(_ level: ThermalLevel) -> String {
        switch level {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        }
    }

    private func powerSourceName(_ source: PowerSource) -> String {
        switch source {
        case .battery: return "battery"
        case .acPowered: return "ac_powered"
        case .unknown: return "unknown"
        }
    }
}

// MARK: - Signal Handlers

func setupSignalHandlers() {
    signal(SIGINT) { _ in
        print("\n[ClosedDisplay] Received SIGINT, shutting down...")
        cleanup()
        exit(0)
    }
    
    signal(SIGTERM) { _ in
        print("\n[ClosedDisplay] Received SIGTERM, shutting down...")
        cleanup()
        exit(0)
    }
}

func cleanup() {
    lidStateTimer?.invalidate()
    globalSessionManager?.endSession()
}

// MARK: - Monitoring Functions

func startLidMonitoring() {
    // Poll lid state every 2 seconds (IOKit notifications require mach ports and more complex setup)
    lidStateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
        guard let sessionManager = globalSessionManager else { return }
        
        if let isOpen = IOKitServices.getClamshellState() {
            sessionManager.handleLidStateChange(!isOpen)
        }
    }
}

func startThermalMonitoring() {
    // Monitor thermal state changes
    NotificationCenter.default.addObserver(
        forName: ProcessInfo.thermalStateDidChangeNotification,
        object: nil,
        queue: .main
    ) { _ in
        guard let sessionManager = globalSessionManager else { return }
        
        let thermalState = ProcessInfo.processInfo.thermalState
        let level: ThermalLevel
        
        switch thermalState {
        case .nominal:
            level = .nominal
        case .fair:
            level = .fair
        case .serious:
            level = .serious
        case .critical:
            level = .critical
        @unknown default:
            level = .nominal
        }
        
        sessionManager.handleThermalLevel(level)
    }
}

func startPowerMonitoring() {
    // Monitor power source changes (AC/battery)
    // Note: For full implementation, use IOPowerSources APIs
    // For now, check initial state
    guard let sessionManager = globalSessionManager else { return }
    
    // Check if on AC power via IOKit
    let powerSource: PowerSource = .acPowered // Simplified for now
    sessionManager.handlePowerSourceChange(powerSource)
}

// MARK: - Main Entry Point

@main
struct Main {
    static func main() {
        print("[ClosedDisplay] Starting continuous monitoring...")
        print("[ClosedDisplay] Press Ctrl+C to stop")
        
        // Set up signal handlers for graceful shutdown
        setupSignalHandlers()
        
        // Create delegate and session manager
        let delegate = SessionDelegate()
        globalDelegate = delegate
        let sessionManager = SessionManager(delegate: delegate)
        globalSessionManager = sessionManager
        
        // Check if this is a laptop
        if let clamshellState = IOKitServices.getClamshellState() {
            print("[ClosedDisplay] Laptop detected, clamshell \(clamshellState ? "closed" : "open")")
            
            // Start session if lid is already closed
            if clamshellState {
                sessionManager.startSession()
            }
        } else {
            print("[ClosedDisplay] No clamshell detected (desktop mode)")
            print("[ClosedDisplay] Exiting...")
            return
        }
        
        // Start monitoring
        startLidMonitoring()
        startThermalMonitoring()
        startPowerMonitoring()
        
        print("[ClosedDisplay] Monitoring active...")
        
        // Keep app running
        RunLoop.main.run()
    }
}
