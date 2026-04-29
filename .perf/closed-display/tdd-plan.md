# TDD Implementation Plan

## Meta
- **Feature:** Closed-Display utility for Apple Silicon macOS
- **Language:** Swift 5.9+ / macOS 14+ (Apple Silicon)
- **Total Steps:** 8
- **Estimated Total Lines:** 450
- **Constitution:** `.perf/closed-display/constitution.md`
- **Spec:** `.perf/closed-display/spec.md`

## Components
| Component | Description | Tests Covered | Priority |
|-----------|-------------|---------------|----------|
| Enums (SessionState, ThermalLevel, PowerSource) | Compact Int8 enums for state tracking | test_correctness: all state assertions | 1 |
| IOKitServices | Wrapper struct for IOKit operations (clamshell, brightness, service ports) | test_ioKitCachePowerRootDomain, test_ioKitCacheInternalDisplay, test_ioKitSetDisplayBrightness*, test_ioKitSetDisplayBrightnessInvalid, test_ioKitSetDisplayBrightnessOverOne, test_ioKitReleaseAllClearsPorts, test_edge02_ioKitServicePortZero | 2 |
| PowerManager | pmset execution and IOPMAssertion management | test_pmsetDisableSleep, test_pmsetEnableSleep, test_assertionCreateAndRelease | 3 |
| SessionManager | State machine coordinating clamshell, thermal, power source events | test_fr01*, test_fr02*, test_fr03*, test_fr04*, test_fr05*, test_fr06*, test_fr07*, test_edge01*, test_edge04*, test_edge06*, test_edge10* | 4 |
| HelperClient (XPC) | Client for privileged helper tool with message validation | test_fr09*, test_fr09b* | 5 |
| Constants & Configuration | All magic strings/paths as static let constants | (embedded in other components) | 1 |
| Performance Benchmarks | Latency, memory, and stress tests | All test_performance* tests | 6 |
| Property Invariants | Property-based tests for system invariants | All test_property* tests | 7 |

## Implementation Steps

### Step 1: Enums, Constants, and Foundation Types
- **TDD Cycle:** Write failing test -> Implement -> Refactor
- **Target Tests:** test_correctness: all enum-related assertions
- **Description:** Define the core Swift enums (SessionState, ThermalLevel, PowerSource) with Int8 raw values. Define the IOPMAssertionID type alias. Define all constants (pmset path, assertion names, XPC message codes, dispatch queue labels).
- **Key Constitution Rules:** CONV-04, CONV-07, DATA-01, PERF-07
- **Estimated Lines:** 35
- **Expected Performance Impact:** Establishes baseline -- zero heap allocation for state data
- **Dependencies:** none

### Step 2: IOKitServices Wrapper
- **TDD Cycle:** Write failing test -> Implement -> Refactor
- **Target Tests:** test_ioKitCachePowerRootDomain, test_ioKitCacheInternalDisplay, test_ioKitSetDisplayBrightness*, test_ioKitSetDisplayBrightnessInvalid, test_ioKitSetDisplayBrightnessOverOne, test_ioKitReleaseAllClearsPorts, test_edge02_ioKitServicePortZero
- **Description:** Create the IOKitServices struct with static methods for clamshell detection, service port caching, brightness control, and cleanup. Implement graceful degradation for port 0. Cache service ports at startup per OPT-01.
- **Key Constitution Rules:** CONV-01, DATA-04, OPT-01, OPT-06, BAN-03
- **Estimated Lines:** 55
- **Expected Performance Impact:** Service port caching eliminates repeated IOKit registry lookups (~5ms per lookup avoided)
- **Dependencies:** Step 1

### Step 3: PowerManager (pmset + Assertions)
- **TDD Cycle:** Write failing test -> Implement -> Refactor
- **Target Tests:** test_pmsetDisableSleep, test_pmsetEnableSleep, test_assertionCreateAndRelease
- **Description:** Create the PowerManager class with methods for pmset execution (fire-and-forget, stdout/stderr to /dev/null per ALGO-03) and IOPMAssertion management (create/release with unique IDs). Use Process for pmset execution on background queue per PERF-03.
- **Key Constitution Rules:** ALGO-03, ALGO-06, CONV-06, OPT-06, BAN-02
- **Estimated Lines:** 45
- **Expected Performance Impact:** pmset execution on background queue prevents main thread blocking
- **Dependencies:** Step 1

### Step 4: SessionManager State Machine
- **TDD Cycle:** Write failing test -> Implement -> Refactor
- **Target Tests:** test_fr01*, test_fr02*, test_fr03*, test_fr04*, test_fr05*, test_fr06*, test_fr07*, test_edge01*, test_edge04*, test_edge06*, test_edge10*
- **Description:** Create the SessionManager class implementing the full state machine. Start/end session, thermal emergency handling (serious/critical trigger cleanup), power source change handling (re-assert pmset when active), lid state change with debounce. Coordinate with IOKitServices and PowerManager.
- **Key Constitution Rules:** DATA-01, DATA-02, ALGO-01, ALGO-02, OPT-02, OPT-03, BAN-01, BAN-07
- **Estimated Lines:** 120
- **Expected Performance Impact:** Core business logic -- all performance targets flow from correct state machine operation
- **Dependencies:** Step 2, Step 3

### Step 5: HelperClient (XPC Message Validation)
- **TDD Cycle:** Write failing test -> Implement -> Refactor
- **Target Tests:** test_fr09*, test_fr09b*
- **Description:** Create the HelperClient class with XPC connection management (create once, reuse per PERF-02), message validation (reject unknown types, reject unauthorized), and command dispatch. Pre-allocate connection at launch per OPT-05.
- **Key Constitution Rules:** CONV-02, OPT-05, OPT-07, PERF-02, PERF-06, BAN-05, BAN-06
- **Estimated Lines:** 60
- **Expected Performance Impact:** Pre-allocated XPC connection + <1ms message handling
- **Dependencies:** Step 1

### Step 6: Mock Implementations for Testing
- **TDD Cycle:** Tests exist -> Implement mocks -> Verify all tests compile
- **Target Tests:** All correctness test mock references (MockSessionManager, MockHelperClient, MockPowerManager, MockXPCConnection, IOKitServices mock extensions, PowerManager mock extensions)
- **Description:** Implement the mock classes and extensions referenced in test_correctness.swift. These must provide the same public API as the real implementations but with deterministic, test-friendly behavior.
- **Key Constitution Rules:** CONV-05, DATA-03
- **Estimated Lines:** 80
- **Expected Performance Impact:** N/A (test infrastructure only)
- **Dependencies:** Step 4, Step 5

### Step 7: Performance Benchmarks
- **TDD Cycle:** All correctness tests passing -> Add benchmarks -> Verify targets
- **Target Tests:** test_clamshellDetectionLatency, test_xpcIPCControlMessageLatency, test_stateMachineTransitionLatency, test_memoryFootprintIdle, test_xpcMessageHandlingLatency, test_stateEnumMemorySize, test_stateMachineStress
- **Description:** Implement performance benchmarks measuring latency, memory footprint, and stress behavior. Verify all performance targets from spec Section 3.1.
- **Key Constitution Rules:** PERF-01 through PERF-07, CONST-08
- **Estimated Lines:** 70
- **Expected Performance Impact:** Validates all performance targets (<100ms detection, <10ms XPC, <50MB memory)
- **Dependencies:** Step 4, Step 5, Step 6

### Step 8: Property-Based Tests (Final Invariants)
- **TDD Cycle:** All tests passing -> Run property tests -> Verify invariants
- **Target Tests:** All test_property* tests
- **Description:** The property-based tests verify system invariants across all combinations of thermal state, session state, and power source. This is the final validation step.
- **Key Constitution Rules:** TEST-02, TEST-03, TEST-06, CONST-04, CONST-05
- **Estimated Lines:** 0 (tests only, no source code changes)
- **Expected Performance Impact:** Validates correctness of all invariants
- **Dependencies:** Step 7

## Test Execution Order

| After Step | Tests to Run | Expected Result |
|------------|-------------|-----------------|
| 1 | All enum-related assertions in test_correctness | All passing |
| 2 | All IOKitServices tests in test_correctness | All passing |
| 3 | All PowerManager tests in test_correctness | All passing |
| 4 | All SessionManager tests in test_correctness | All passing |
| 5 | All HelperClient tests in test_correctness | All passing |
| 6 | All test_correctness.swift tests | All 19 passing |
| 7 | All test_performance.swift tests | All 7 passing |
| 8 | All test_property.swift tests | All 15 passing |

## TDD Cycle Instructions

For each step, the implementer must follow this exact cycle:

1. **Red:** Confirm the target tests fail (or do not yet exist in code)
2. **Green:** Write the minimal code to make the target tests pass
3. **Refactor:** Apply relevant constitution optimization rules without breaking any passing tests
4. **Verify:** Run all previously-passing tests to confirm no regressions
