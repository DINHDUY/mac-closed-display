# Constitution

## Meta
- **Feature:** Closed-Display utility for Apple Silicon macOS
- **Language:** Swift 5.9+ / macOS 14+ (Apple Silicon M1/M2/M3/M4)
- **Generated from:** `.perf/closed-display/performance-research-report.md`
- **Loop B Iteration:** 0
- **Last updated:** 2026-04-27

## Coding Conventions
- [CONV-01] All IOKit functions must be wrapped in try/defer blocks that call `IOObjectRelease` -- prevents kernel resource leaks
- [CONV-02] All XPC dictionary values must use `CFBoolean` and `NSNumber` types, never Swift `Bool` or `Int`, to avoid bridging overhead
- [CONV-03] All NotificationCenter observers must use `weak self` in closures and store observer tokens for explicit invalidation on teardown
- [CONV-04] All state machines must be enum-driven with explicit `rawValue` types (e.g., `enum SessionState: Int8`) for compact memory layout
- [CONV-05] All public APIs must have full type annotations including parameter labels and return types -- no omitted types anywhere
- [CONV-06] All dispatch queue labels must follow the pattern `com.closed-display.[component]` with QoS matching the operation criticality
- [CONV-07] All constants (paths, assertion names, message codes) must be defined as `static let` at the top of their respective modules, never as magic strings

## Performance Principles
- [PERF-01] Event-driven architecture only -- no polling timers for state detection (IOKit registry notify for clamshell, NotificationCenter for thermal)
- [PERF-02] XPC connections must be created once and reused -- never create or destroy XPC connections per-message
- [PERF-03] All heavy system operations (pmset execution, IOKit calls) must run on background dispatch queues, never on the main thread
- [PERF-04] Service port caching is mandatory -- IOKit service ports must be cached after first lookup and reused across calls
- [PERF-05] Memory footprint must stay below 50MB RSS; avoid Swift collection allocations for hot-path state tracking
- [PERF-06] XPC message handling must complete in under 1ms; dispatch any work that takes longer off the XPC handler queue
- [PERF-07] Use Swift enums and structs for in-process state to achieve zero heap allocation for state data

## Algorithm Rules
- [ALGO-01] Clamshell detection must use IOKit Registry Notify (`IOServiceGetMatchingService` + `IOServiceAddMatchingNotification`), never polling
- [ALGO-02] Thermal monitoring must use `ProcessInfo.thermalStateDidChangeNotification` via NotificationCenter, never polling `ProcessInfo.thermalState`
- [ALGO-03] pmset execution must use `Process` with stdout/stderr piped to `/dev/null` (fire-and-forget); never read output
- [ALGO-04] Power source monitoring must use `IOPSCopyPowerSourcesList` and `IOPSCopyPowerSourcesInfo` with `PSRegisterPowerSourceChangeCallback`
- [ALGO-05] Display backlight control must use `DisplayServicesSetBrightness` on a cached internal display service port
- [ALGO-06] IOPMAssertion creation must use `IOPMAssertionCreateWithName` with `kIOPMAssertionTypeNoIdleSleep` and `kIOPMSystemPowerAssertion`

## Data Structure Rules
- [DATA-01] Session state must use a Swift enum with raw `Int8` value for compact representation and explicit state transitions
- [DATA-02] Thermal state flag must use `DispatchQueue.concurrentPerform` with `OSAtomicCompareAndSwap` or `Atomic<Int32>` for lock-free inter-thread communication
- [DATA-03] Observer collections must use `NSHashTable` with `weakObjects` option to prevent retain cycles in NotificationCenter patterns
- [DATA-04] IOKit service ports must be stored as optional `io_service_t` with `defer { IOObjectRelease(port) }` for guaranteed cleanup
- [DATA-05] XPC messages must use `CFMutableDictionary` with `CFNumber` values for compact binary encoding

## Optimization Rules
- [OPT-01] Cache `IOServiceGetMatchingService` results for IOKit services (power root domain, internal display) at startup
- [OPT-02] Use `DispatchQueue` with `.userInitiated` QoS for session management path (clamshell detection -> pmset/assertion)
- [OPT-03] Use `DispatchQueue` with `.utility` QoS for thermal monitoring path to deprioritize from user-facing work
- [OPT-04] Batch pmset calls into a single `Process` invocation when multiple overrides need to be set simultaneously
- [OPT-05] Pre-allocate the XPC connection at app launch; never defer XPC connection creation until first message
- [OPT-06] Use `defer` blocks for all IOKit resource release (`IOObjectRelease`) and pmset cleanup to guarantee cleanup on early return
- [OPT-07] Set XPC connection timeout to 5 seconds to prevent indefinite hangs; use `setTimeInterval` on the connection

## Anti-Pattern Prohibitions
- [BAN-01] NEVER use polling timers (e.g., `Timer.scheduledTimer` or `DispatchSourceTimer`) for clamshell state detection
- [BAN-02] NEVER call pmset or IOKit functions on the main dispatch queue or in SwiftUI view bodies
- [BAN-03] NEVER omit `IOObjectRelease` after obtaining an IOKit service port -- this is a kernel resource leak
- [BAN-04] NEVER capture `self` strongly in NotificationCenter closures -- always use `[weak self]`
- [BAN-05] NEVER create a new XPC connection per-message -- create once and reuse
- [BAN-06] NEVER block the XPC message handler with synchronous heavy work -- always dispatch off the handler queue
- [BAN-07] NEVER skip the thermal kill-switch -- the app must exit and revert all overrides when thermal state is `.serious` or `.critical`
- [BAN-08] NEVER use `NSKeyValueObservation` on `AppleClamshellState` as a fallback -- always use IOKit registry notifications

## Testing Philosophy
- [TEST-01] Every IOKit wrapper function must have a mock-based test that verifies correct `IOObjectRelease` on both success and error paths
- [TEST-02] Every state transition in the session state machine must have a deterministic test case (no async or timing-dependent tests)
- [TEST-03] The thermal kill-switch logic must be tested with property-based tests covering all combinations of thermal state + session state
- [TEST-04] XPC message encoding/decoding must be tested for correctness with all valid message types and rejected malformed messages
- [TEST-05] Memory footprint must be measured using `mach_task_basic_info` and verified to stay below 50MB RSS at idle
- [TEST-06] All async operations (pmset execution, IOKit calls) must have timeout guards to prevent indefinite hangs

## Constraints
- [CONST-01] The application must compile and run on macOS 14+ (Sonoma) on Apple Silicon (M1/M2/M3/M4) only -- no Intel support
- [CONST-02] The helper tool must be installed via SMJobBless with proper code signatures -- no sudoers-based approach
- [CONST-03] All system operations must have graceful degradation: if IOKit detection fails, the app must not crash
- [CONST-04] The thermal kill-switch is mandatory and must operate without user intervention -- no exceptions
- [CONST-05] All cleanup (pmset revert, assertion release, brightness restore) must happen on app termination, crash, or session end
- [CONST-06] The helper tool must validate all incoming XPC messages and reject any malformed or unauthorized requests
- [CONST-07] The main app must be sandbox-compatible -- all IOKit and Process operations must work within App Sandbox constraints
- [CONST-08] Clamshell detection latency (IOKit notification to action) must be under 100ms; XPC IPC must be under 10ms for control messages
