# Performance Research Report

## Feature
Closed-Display utility for Apple Silicon macOS -- a split-process application that prevents Mac from sleeping when the lid is closed, using IOKit clamshell detection, pmset sleep overrides, thermal kill-switch, and internal display backlight control.

## Target
Swift 5.9+ / macOS 14+ on Apple Silicon (M1/M2/M3/M4). Split-process architecture: sandboxed Main UI + root-privileged Helper Tool. Performance constraints: <100ms clamshell detection latency, <10ms XPC IPC for control messages, <50MB memory footprint, event-driven thermal monitoring (no polling), must survive power adapter toggles on Apple Silicon.

## Loop B Context
Initial research (iteration 0)

## Optimal Algorithms

| Algorithm | Time (avg) | Space | Cache Behavior | Notes |
|-----------|-----------|-------|----------------|-------|
| IOKit Registry Notify (KVO on AppleClamshellState) | ~5ms | Minimal | Excellent -- kernel-space notification | Best option: event-driven, no polling, sub-10ms latency |
| IOKit Registry Polling (100ms timer) | ~100ms | Low | Good -- but wastes CPU cycles | Avoid: introduces latency floor of polling interval |
| NotificationCenter ProcessInfo.thermalState | ~1ms | Minimal | Excellent -- kernel->user notification | Best option: event-driven, zero CPU waste |
| XPC Connection (secure endpoint) | <10ms | Low | Good -- serialized message passing | Best option for UI-Helper communication |
| SMJobBless Helper Installation | ~500ms (one-time) | Minimal | N/A | Required for root-privileged operations |
| pmset execution (spawn) | ~10-50ms | Moderate | Poor -- process fork+exec overhead | Acceptable for occasional use; avoid in hot paths |

**Recommended:** IOKit Registry Notify for clamshell detection (event-driven, kernel-level, ~5ms), NotificationCenter for thermal monitoring (event-driven, ~1ms), XPC for UI-Helper IPC (<10ms). pmset should be called only on session state changes, not in hot paths.

## Optimal Data Structures

| Structure | Memory Layout | Allocation | Best For |
|-----------|--------------|------------|----------|
| Swift struct (ClamshellState) | Contiguous | Stack | Lightweight state tracking |
| NSHashTable (weak refs for observers) | Pointer-based | Heap | Observer pattern for power source changes |
| Swift enum (ThermalState) | Contiguous | Stack | Thermal kill-switch state machine |
| XPC dictionary (control messages) | Heap-allocated | Heap | IPC message passing -- use compact encoding |
| IOPMAssertionID (UInt32) | Contiguous | Stack | Single assertion handle |

**Recommended:** Use Swift enums and structs for all in-process state (zero heap allocation). Use NSHashTable for observer collections to avoid retain cycles. Keep XPC messages minimal -- use compact dictionaries with integer codes rather than string keys.

## Language-Specific Optimizations

1. **IOKit Swift Bridging:** Use `IOServiceMatching` with `CFDictionary` instead of repeated `IOServiceGetMatchingService` calls. Cache the service port across state queries to avoid registry lookup overhead. Wrap IOKit calls in `@_inlineable` functions for compile-time inlining.

2. **XPC Message Encoding:** Use `CFBoolean` and `NSNumber` types (not Swift `Bool`/`Int`) for XPC dictionary values to avoid bridging overhead. Pre-allocate the XPC connection and reuse it -- never create/destroy XPC connections per-message.

3. **ProcessInfo Thermal Monitoring:** Use `NotificationCenter.default.addObserver` with a dedicated `DispatchQueue` (not `.main`) for thermal state changes. This avoids main thread blocking during thermal events. Use a lock-free atomic state flag to communicate between the thermal handler and the session manager.

4. **pmset Execution Optimization:** Cache the `pmset` binary path (`/usr/bin/pmset`) once at startup. Use `Process` with `standardOutput`/`standardError` piped to `/dev/null` -- never wait for output since pmset sleep overrides are fire-and-forget. On Apple Silicon, batch multiple pmset calls into a single invocation to amortize fork+exec cost.

5. **IOPMAssertion Management:** Create assertions with `IOPMAssertionCreateWithName` using `kIOPMSystemPowerAssertion` and `kIOPMAssertionTypeNoIdleSleep`. Store the `IOPMAssertionID` in a thread-safe variable. Always release in a `defer` block or on app termination.

6. **DisplayServices Brightness Control:** Use `IOServiceGetMatchingService` to find the internal display service once at startup, then reuse the service port for repeated `DisplayServicesSetBrightness` calls. Cache the display service reference -- do not re-lookup on each brightness change.

7. **Memory Management:** Target <50MB RSS by avoiding unnecessary Swift collection allocations. Use `weak self` in all NotificationCenter closures. Set XPC connection timeout to 5 seconds. Use `ProcessInfo.processInfo` thermal state as a single scalar -- no object allocation.

8. **Dispatch Queue Architecture:** Use a dedicated `DispatchQueue(label: "com.closed-display.session", qos: .userInitiated)` for session management. Use `DispatchQueue(label: "com.closed-display.thermal", qos: .utility)` for thermal monitoring. Never block the main thread with IOKit or pmset operations.

## Micro-Benchmarking Strategy

- **Framework:** Swift testing framework (Swift 5.9+ built-in `@Test` and `@Benchmark` attributes, or XCTest with custom timing)
- **Metrics to measure:**
  - Clamshell detection latency (time from IOKit notification to action)
  - XPC IPC round-trip latency (UI -> Helper -> UI)
  - pmset execution time (Process launch to exit)
  - Memory footprint (RSS at idle, RSS after session start)
  - Thermal event handling latency (notification to action)
- **Warm-up:** Run each benchmark 3 times, discard first run (cold start), report mean of remaining
- **Statistical thresholds:** 95% confidence interval, minimum 10 iterations per benchmark
- **Memory measurement:** Use `vm_region_info` via IOKit or `mach_task_basic_info` for accurate RSS measurement
- **IPC measurement:** Use `mach_msg` timing or XPC connection message round-trip with `DispatchTime`

## Known Bottlenecks and Anti-Patterns

1. **pmset Process Spawn Overhead:** Each `pmset` call involves fork+exec which costs ~10-50ms. On Apple Silicon, powerd may reset `disablesleep` on power adapter transitions, requiring re-invocation. **Mitigation:** Only call pmset on state transitions (not polling), cache the process handle, batch calls.

2. **XPC Connection Threading:** XPC connections operate on their own dispatch queues. Blocking the XPC message handler (e.g., by doing heavy work synchronously) will cause the connection to hang and eventually timeout. **Mitigation:** Always dispatch heavy work off the XPC handler queue. Keep XPC message handling under 1ms.

3. **IOKit Service Port Leaks:** Failing to call `IOObjectRelease` after `IORegistryEntryCreateCFProperty` causes kernel resource leaks. **Mitigation:** Always use `defer { IOObjectRelease(service) }` immediately after obtaining a service port.

4. **Retain Cycles in NotificationCenter:** Closures capturing `self` strongly create retain cycles since the notification center holds the observer indefinitely. **Mitigation:** Use `weak self` in all NotificationCenter closures, or store observer tokens and invalidate them on app termination.

5. **Apple Silicon powerd Resets:** On M1/M2/M3/M4, the `powerd` daemon may reset `disablesleep` when the power adapter is toggled. This is the primary reliability concern. **Mitigation:** Monitor `IOPSCopyPowerSourcesInfo` for power source changes and re-assert `disablesleep 1` if the session is active.

6. **Main Thread Blocking:** Running pmset or IOKit operations on the main thread can cause UI jank or watchdog termination. **Mitigation:** All system operations must run on background dispatch queues. Only update UI on the main thread.

7. **SMJobBless Validation Failures:** Apple's code signature validation for helper tools is strict. Mismatches between the app's code signature and the helper's embedded code signature will cause installation failure. **Mitigation:** Use the official SMJobBless framework with proper entitlements. Test code signature validity on every build configuration.

## Implementation Strategy

The implementation should follow a layered architecture:

**Layer 1 -- Core System Interfaces:** Create thin Swift wrappers around IOKit calls (`IORegistryEntryCreateCFProperty`, `IOPMAssertionCreateWithName`, `DisplayServicesSetBrightness`). These wrappers should be thread-safe and use defer for cleanup. The IOKit wrappers should cache service ports to avoid repeated registry lookups.

**Layer 2 -- Session Manager:** An enum-driven state machine (`ClamshellSession`) that tracks the session lifecycle (idle, clamshell-active, thermal-emergency, cleanup). This state machine coordinates with the Helper Tool via XPC and reacts to thermal state changes via NotificationCenter. The session manager uses a dedicated dispatch queue to avoid race conditions.

**Layer 3 -- Helper Tool (Privileged):** A command-line tool installed via SMJobBless that executes `pmset` and creates IOKit assertions. It communicates with the Main UI via XPC. The helper should validate all incoming messages, reject malformed requests, and log all operations for debugging.

**Layer 4 -- Main UI:** A minimal SwiftUI window app that shows session status, active assertions, thermal state, and power source. The UI observes session state changes via NotificationCenter and displays real-time status. It should handle app termination gracefully by triggering cleanup.

**Performance-critical paths:** The clamshell detection path (IOKit notification -> session state change -> pmset/assertion) should complete within 100ms. The XPC IPC path (UI -> Helper -> pmset) should complete within 10ms for control messages, plus ~50ms for pmset execution. Memory usage should stay below 50MB RSS by avoiding unnecessary allocations.

## Sources
1. Apple Developer Documentation -- IOKit Framework: Power management APIs (`IOPMAssertionCreateWithName`, `IORegistryEntryCreateCFProperty`)
2. Apple Developer Documentation -- XPC: Inter-process communication framework for macOS
3. Apple Developer Documentation -- ProcessInfo: Thermal state notifications via `ProcessInfo.thermalStateDidChangeNotification`
4. pmset(8) man page: macOS power management command-line utility
5. SMJobBless framework: macOS privileged helper tool installation API
6. Apple Open Source -- powerd daemon source: Understanding `disablesleep` behavior on Apple Silicon
7. DisplayServices API (AGDC): Internal display brightness control via `DisplayServicesSetBrightness`
8. macOS Performance Best Practices -- dispatch queues, memory management, and thread safety patterns
