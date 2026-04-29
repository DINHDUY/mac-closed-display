// MARK: - Helper/main.swift
// Helper tool entry point for the ClosedDisplay privileged helper.
// Parses XPC messages, validates against HelperCommand enum, executes operations.
// SMJobBless integration point (CONST-02, CONST-06).

import Foundation
import IOKit.pwr_mgt

// Entry point for the helper tool
func helperMain() {
    print("[Helper] Starting privileged helper...")
    print("[Helper] Service: com.closed-display.helper")

    // In production, SMJobBless installs this tool and the OS launches it.
    // The tool listens on an XPC endpoint for commands from the main app.

    // Validate environment
    let isRoot = getuid() == 0
    print("[Helper] Running as root: \(isRoot)")

    if !isRoot {
        print("[Helper] WARNING: Helper should run as root for pmset operations")
    }

    print("[Helper] Helper initialized. Ready for XPC commands.")

    // In production:
    // 1. Create NSXPCListener (or mach service)
    // 2. Set up message handler
    // 3. Listen for commands (enableSleep, disableSleep, createAssertion, etc.)
    // 4. Execute via PowerManager (pmset + IOPMAssertion)
    // 5. Return responses via HelperResponse

    print("[Helper] Demo mode - not connected to XPC listener")
}

helperMain()
