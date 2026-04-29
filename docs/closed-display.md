Building a production-ready "Closed-Display" utility for Apple Silicon requires a multi-process architecture to balance security with the deep system hooks needed to override macOS power management.

As a **Senior Architect**, you know that a "one-click" solution must be robust enough to handle the transition between power states (AC to Battery) without the kernel forcing a sleep event during the lid-closure transition.

---

## 1. The Architecture: Split-Process Model
Since modern macOS (especially in 2026) enforces strict sandboxing, a single app cannot achieve this. You need a **Main App** for UI and a **Privileged Helper** for system overrides.

| Component | Responsibility | Privilege Level |
| :--- | :--- | :--- |
| **Main UI (App)** | Session management, UI, monitoring `ProcessInfo`. | User / Sandboxed |
| **Helper Tool** | Executing `pmset` and `IOKit` assertions. | Root (Privileged) |
| **Sudoers/XPC** | Secure communication between UI and Helper. | System |

---

## 2. Detection: The IOKit Registry Monitor
To react before the system sleeps, you must monitor the `AppleClamshellState` property. This property is specific to laptops and allows you to detect the moment the Hall effect sensor is triggered.

### Swift Implementation
```swift
import Foundation
import IOKit

func getLidState() -> Bool {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, 
                                              IOServiceNameMatching("IOPMAppleRootDomain"))
    defer { IOObjectRelease(service) }
    
    if service != 0 {
        let property = IORegistryEntryCreateCFProperty(service, 
                                                       "AppleClamshellState" as CFString, 
                                                       kCFAllocatorDefault, 0)
        return property?.takeRetainedValue() as? Bool ?? false
    }
    return false
}
```

---

## 3. The "Nuclear Option": System Overrides
On Apple Silicon, user-space assertions (like `caffeinate`) are often ignored during a lid-close event if an external display isn't detected. You must use the **global sleep disable** via `pmset`.

### The Core Commands
1.  **Disable Sleep:** `sudo pmset -a disablesleep 1`
2.  **Enable Sleep:** `sudo pmset -a disablesleep 0`

> **Note on Apple Silicon Persistence:** On M1/M2/M3+ chips, the `powerd` daemon may reset this flag when you toggle the power adapter. Your helper tool should "watch" power source changes and re-assert `disablesleep 1` if a session is active.

---

## 4. Safety First: Thermal Pressure "Kill-Switch"
Running a MacBook with the lid closed increases thermal density. You must implement a safety watchdog that reverts all overrides if the system enters a throttled state.

### Thermal Monitoring Logic
```swift
import Foundation

func setupThermalWatchdog() {
    NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, 
                                           object: nil, 
                                           queue: .main) { _ in
        let state = ProcessInfo.processInfo.thermalState
        if state == .serious || state == .critical {
            // EMERGENCY REVERT: Prevent hardware damage
            executeCommand("sudo pmset -a disablesleep 0")
            triggerSystemSleep()
        }
    }
}
```

---

## 5. The Playbook: Implementation Steps

### Phase 1: Security Setup
* **Create a Helper Tool:** Use `SMJobBless` or a modern `LaunchAgent` to install a helper.
* **Whitelist the Helper:** Add a `sudoers` entry in `/private/etc/sudoers.d/` so the app can run `pmset` without a password prompt.

### Phase 2: Session Logic
* **On Session Start:**
    1. Create an `IOPMAssertion` to prevent idle sleep.
    2. Execute `pmset -a disablesleep 1`.
* **On Lid Close Detection:**
    1. Force internal display backlight to 0% (using `DisplayServicesSetBrightness`) to prevent heat build-up against the screen.
    2. Maintain the `disablesleep` state.

### Phase 3: Cleanup & Restoration
* **On Session End OR Lid Open:**
    1. Immediately run `pmset -a disablesleep 0`.
    2. Release all `IOPMAssertions`.
    3. Restore original brightness levels.

---

## 6. Comparison of Thermal States

| State | Internal Action | Solution Recommendation |
| :--- | :--- | :--- |
| **Nominal** | Standard operation. | Keep session active. |
| **Fair** | Fans ramp up. | Monitor closely; alert user. |
| **Serious** | CPU/GPU Throttling begins. | **Safety Kill-Switch Active: Revert to Sleep.** |
| **Critical** | Hardware shutdown imminent. | **Immediate Shutdown/Sleep.** |

> **Pro-Tip for 2026 Architectures:** If you are supporting M3/M4 MacBooks, remember that closing the lid is a **hardware requirement** to drive two external displays on the base-model chips. Your implementation should detect if multiple displays are connected and offer to "Enable Clamshell Optimization" automatically.

Does this architectural flow align with your existing platform engineering standards, or should we dive deeper into the XPC communication layer?