# Performance-First Code Generation Workflow - Specification

## Overview

The Performance-First Code Generation workflow is an advanced multi-agent system designed to generate high-performance, correctness-guaranteed code from natural language feature requests. It orchestrates 9 specialized agents through a rigorous 7-stage sequential pipeline with two nested feedback loops, producing optimized implementations with comprehensive test suites, performance benchmarks, and full provenance documentation.

### Key Capabilities

- **Performance-First Development**: Research-driven optimization strategies applied before code generation
- **Test-Driven Development (TDD)**: Comprehensive test suites written before implementation
- **Dual Feedback Loops**: Inner loop for correctness (Loop A), outer loop for performance optimization (Loop B)
- **Constitution-Driven**: All agents follow a unified set of performance rules and coding standards
- **Incremental Implementation**: Atomic tasks with dependency management for reliable execution
- **Full Traceability**: Complete audit trail from research to final implementation

### Target Use Cases

- High-performance library development (parsers, algorithms, data processors)
- Performance-critical application components
- Optimization of existing code with measurable targets
- TDD-based code generation with strict quality gates
- Algorithm implementation with complexity guarantees

## Architecture

### Agent Roster

The workflow comprises 9 specialized agents, each with distinct responsibilities:

| Agent | Role | Model | Readonly | Primary Responsibilities |
|-------|------|-------|----------|-------------------------|
| **perf.orchestrator** | Master coordinator | Sonnet | No | Coordinates all 8 subagents through 7-stage pipeline; manages Loop B iterations |
| **perf.researcher** | Performance researcher | Sonnet | Yes | Researches algorithms, data structures, language-specific optimizations, benchmarking strategies |
| **perf.constitution-writer** | Rule codifier | Fast | No | Converts research into enforceable coding rules and performance principles |
| **perf.spec-writer** | Spec & test author | Sonnet | No | Creates formal specifications with functional/non-functional requirements; authors comprehensive test suites |
| **perf.planner** | TDD planner | Fast | No | Generates test-driven implementation plans with build order and test-to-step mappings |
| **perf.task-decomposer** | Task atomizer | Fast | No | Decomposes plans into atomic tasks (<30 lines each) with dependency graphs (DAGs) |
| **perf.loop-controller** | Inner loop manager | Fast | No | Manages implement-test-retry cycles (Loop A); enforces max retry limits |
| **perf.implementer** | Code generator | Sonnet | No | Implements atomic tasks following constitution rules; fixes failing tests on retry |
| **perf.test-runner** | Test executor | Fast | Yes | Executes correctness tests and performance benchmarks; generates structured reports |

### Data Flow Architecture

```
User Request
     ↓
perf.orchestrator (Loop B Manager)
     ↓
[Stage 1] perf.researcher → performance-research-report.md
     ↓
[Stage 2] perf.constitution-writer → constitution.md
     ↓
[Stage 3] perf.spec-writer → spec.md + test files
     ↓
[Stage 4] perf.planner → tdd-plan.md
     ↓
[Stage 5] perf.task-decomposer → task-graph.json
     ↓
[Stage 6] perf.loop-controller (Loop A Manager)
     ├─→ perf.implementer → source code
     ├─→ perf.test-runner → test-report.json
     └─→ [retry if tests fail, max 5 iterations]
     ↓
[Stage 7] Performance Analysis & Loop B Decision
     ├─→ If performance targets met: SUCCESS ✓
     └─→ If performance plateau: Re-run Stages 1-6 with focus on bottlenecks (max 3 Loop B iterations)
```

## Workflow Stages

### Stage 0: Workspace Initialization

**Orchestrator** creates the directory structure for artifact storage:

```
.perf/[feature-name]/           # Planning and documentation
├── performance-research-report.md
├── constitution.md
├── spec.md
├── tdd-plan.md
└── task-graph.json

.perf/temp/                     # Temporary intermediate files

output/tests/[feature-name]/    # Test execution results
└── test-report.json

output/bench/[feature-name]/    # Benchmark results
├── loop-a-summary.md
├── loop-b-state.json
└── implementation-log.md

tests/                          # Test files (project level)
├── test_correctness.py
├── test_performance.py
└── test_property.py

src/                            # Source code (project level)
└── [implementation files]
```

Initializes `loop-b-state.json` to track outer loop iterations:

```json
{
  "iteration": 0,
  "max_iterations": 3,
  "performance_history": [],
  "status": "in_progress"
}
```

### Stage 1: Performance Research

**Agent**: `perf.researcher` (read-only, Sonnet)

**Input**:
- User feature request (natural language)
- Target language/platform
- Performance constraints
- On Loop B re-invocations: previous test report with bottleneck analysis

**Output**: `.perf/[feature-name]/performance-research-report.md`

**Process**:
1. Analyzes feature request to identify core computation, scale requirements, performance dimensions
2. Researches optimal algorithms (compares 3+ approaches, records complexity analysis)
3. Researches optimal data structures (memory layout, cache behavior)
4. Researches language-specific optimizations (e.g., Python vectorization, Rust SIMD)
5. Researches micro-benchmarking strategies for the problem domain
6. Identifies known bottlenecks and anti-patterns
7. Compiles comprehensive report with recommendations

**On Loop B iterations**: Focuses research on measured bottlenecks from previous test results.

### Stage 2: Constitution Generation

**Agent**: `perf.constitution-writer` (write, Fast)

**Input**:
- Performance research report
- On Loop B re-invocations: previous constitution + test report

**Output**: `.perf/[feature-name]/constitution.md`

**Process**:
1. Extracts knowledge from research report
2. Structures into 8 canonical sections:
   - **Coding Conventions**: Style rules affecting performance
   - **Performance Principles**: High-level optimization mandates
   - **Algorithm Rules**: Specific algorithm choices with rationale
   - **Data Structure Rules**: Required structures and memory patterns
   - **Optimization Rules**: Language-specific techniques
   - **Anti-Pattern Prohibitions**: Forbidden patterns
   - **Testing Philosophy**: Validation requirements
   - **Constraints**: Hard constraints
3. Each rule is concrete, actionable, and enforceable by code-generating agents
4. On Loop B iterations: Strengthens or revises rules based on test failures

**Example Rules**:
- `[ALGO-01] Use TimSort (built-in sorted()) for general sorting; use radix sort for integer-only sorting of >10k elements`
- `[DATA-01] Use array.array('d') instead of list for homogeneous numeric sequences`
- `[BAN-01] NEVER use string concatenation in a loop; use join() or io.StringIO`

### Stage 3: Specification and Test Authoring

**Agent**: `perf.spec-writer` (write, Sonnet)

**Input**:
- Feature request
- Constitution file
- Research report
- On Loop B re-invocations: previous spec + test report

**Output**:
- `.perf/[feature-name]/spec.md` (formal specification)
- `tests/test_correctness.py` (functional requirements tests)
- `tests/test_performance.py` (benchmarks with thresholds)
- `tests/test_property.py` (property-based tests using Hypothesis)

**Specification Structure**:
1. **Overview**: Feature purpose and performance goals
2. **Functional Requirements**: FR-01, FR-02, ... (specific, testable requirements)
3. **Non-Functional Requirements**:
   - Performance targets (throughput, latency, memory with thresholds)
   - Correctness targets (100% test pass rate)
   - Reliability targets (deterministic, graceful failure handling)
4. **API Design**: Function/class signatures with type annotations
5. **Edge Cases**: EDGE-01, EDGE-02, ... (boundary conditions)
6. **Constraints**: Hard limitations from constitution
7. **Acceptance Criteria**: Checklist for completion
8. **Loop B History**: Performance progression across iterations

**Test Suite Coverage**:
- **Correctness tests**: One test per functional requirement and edge case
- **Performance benchmarks**: Throughput, latency (p50, p99), memory tests with pass/fail thresholds
- **Property-based tests**: Invariant checks using Hypothesis (min 100 examples)
- **Regression tests**: Ensures optimizations don't break functionality

**Threshold Adjustment Logic** (Loop B):
- Target met with >20% margin → tighten by 10%
- Target missed by >50% → relax by 25%
- Target nearly met (<10% gap) → keep unchanged

### Stage 4: TDD Planning

**Agent**: `perf.planner` (write, Fast)

**Input**:
- Specification file
- Constitution file
- All test files

**Output**: `.perf/[feature-name]/tdd-plan.md`

**Process**:
1. Analyzes spec to extract all requirements and API design
2. Analyzes constitution for algorithm/data structure rules
3. Analyzes test files to identify all test functions
4. Determines implementation order using priority rules:
   - Core data structures first
   - Simple correctness before complex correctness
   - Correctness before performance
   - Performance-critical paths early
   - Dependencies before dependents
5. Maps components to tests they satisfy
6. Generates step-by-step plan with test-to-code mappings

**Plan Structure**:
```markdown
## Implementation Steps

### Step 1: [Component Name]
- **TDD Cycle**: Write failing test → Implement → Refactor
- **Target Tests**: [test function names]
- **Description**: What to implement
- **Key Constitution Rules**: [rule IDs]
- **Estimated Lines**: [number]
- **Expected Performance Impact**: [baseline / +X% throughput / -Y% memory]
- **Dependencies**: [none / Step N]
```

### Stage 5: Task Decomposition

**Agent**: `perf.task-decomposer` (write, Fast)

**Input**:
- TDD plan
- Specification
- Constitution
- Test files

**Output**: `.perf/[feature-name]/task-graph.json` (DAG)

**Process**:
1. Breaks each TDD plan step into atomic tasks
2. Enforces atomicity rules:
   - **One test per task**: Each task satisfies exactly one test function
   - **Under 30 lines**: Maximum code size per task
   - **Idempotent**: Repeatable without side effects
   - **Self-contained**: Task description includes all necessary context
   - **Single file target**: Each task modifies at most one source file
3. Establishes dependency graph (DAG) for execution ordering
4. Assigns constitution rules to each task

**Task Graph Structure**:
```json
{
  "meta": {
    "feature": "csv-parser",
    "language": "Python 3.12",
    "total_tasks": 42,
    "total_estimated_lines": 856
  },
  "tasks": [
    {
      "task_id": "T-001",
      "step_ref": "Step 1",
      "description": "Create module with imports and constants",
      "target_test": "test_correctness.py::TestFR::test_fr01_import",
      "target_file": "src/parser.py",
      "dependencies": [],
      "estimated_lines": 10,
      "acceptance_criteria": "Module imports without errors",
      "constitution_rules": ["CONV-01", "CONV-02"],
      "task_type": "setup"
    }
  ]
}
```

### Stage 6: Implementation Loop (Loop A)

**Controller**: `perf.loop-controller` (write, Fast)

**Coordinates**: `perf.implementer` and `perf.test-runner`

**Loop Logic**:
```
iteration = 0
max_iterations = 5

while iteration < max_iterations:
    # Sub-stage A: Implementation
    if iteration == 0:
        perf.implementer(all_tasks)
    else:
        perf.implementer(failing_tasks_only)
    
    # Sub-stage B: Testing
    test_report = perf.test-runner(all_tests)
    
    # Sub-stage C: Evaluation
    if test_report.all_tests_pass:
        return SUCCESS
    else:
        failing_tasks = extract_failing_tasks(test_report)
        iteration += 1

return MAX_RETRIES_EXHAUSTED
```

#### Sub-stage 6A: Implementation

**Agent**: `perf.implementer` (write, Sonnet)

**First Invocation** (iteration 0):
- Processes all tasks in topological order (tier 0 → tier 1 → ...)
- For each task:
  1. Reads task definition from task graph
  2. Checks dependencies are satisfied
  3. Reads constitution rules for the task
  4. Writes code (incremental edits, not full rewrites)
  5. Ensures <30 lines per task
  6. Follows TDD cycle: code must make target test pass
- Produces source files in `src/`
- Updates `implementation-log.md`

**Retry Invocations** (iteration > 0):
- Receives list of failing task IDs from test report
- Reads test report for error messages and stack traces
- Focuses only on failing tasks (narrows scope)
- Applies minimal fixes to address test failures
- Never modifies code for passing tests
- If same test fails 3+ times, includes previous error context for alternative approaches

**Code Quality Guarantees**:
- Type annotations on all functions (per constitution)
- No unnecessary allocations in hot paths
- Exact algorithms/data structures from constitution
- Inline comments explaining performance decisions (with rule IDs)
- No anti-pattern violations

#### Sub-stage 6B: Test Execution

**Agent**: `perf.test-runner` (read-only, Fast)

**Process**:
1. Verifies test environment (installs missing dependencies)
2. Executes correctness tests:
   ```bash
   pytest tests/test_correctness.py -v --tb=long
   pytest tests/test_property.py -v --tb=long
   ```
3. Executes performance benchmarks:
   ```bash
   pytest tests/test_performance.py --benchmark-only --benchmark-json=output.json
   ```
4. Compares results against spec thresholds:
   - Throughput: actual >= target → met
   - Latency/memory: actual <= target → met
   - Calculates deltas: `(actual - target) / target * 100`
5. Detects performance plateau (Loop B):
   - If improvement <2% on all metrics vs previous iteration → plateau detected
6. Generates structured report

**Output**: `output/tests/[feature-name]/test-report.json`

```json
{
  "summary": {
    "total_tests": 45,
    "passed": 42,
    "failed": 3,
    "all_tests_pass": false
  },
  "failed_tests": [
    {
      "name": "test_correctness.py::TestFR::test_fr03_parsing",
      "error": "AssertionError: Expected [...] but got [...]",
      "stack_trace": "...",
      "task_id_hint": "T-008"
    }
  ],
  "performance_benchmarks": [
    {
      "name": "bench_throughput_1mb",
      "target": 100.0,
      "target_unit": "MB/s",
      "actual": 95.3,
      "delta_percent": -4.7,
      "met": false
    }
  ],
  "plateau_detected": false,
  "regression_warnings": []
}
```

#### Sub-stage 6C: Retry Decision

**Loop Controller** evaluates test report:

- **All tests pass** → return SUCCESS to orchestrator, proceed to Stage 7
- **Tests failed AND iteration < 5** → retry with failing tasks only
- **Tests failed AND iteration >= 5** → return MAX_RETRIES_EXHAUSTED, proceed to Stage 7
- **Output**: `output/bench/[feature-name]/loop-a-summary.md`

### Stage 7: Performance Analysis & Loop B Decision

**Orchestrator** analyzes Stage 6 outcomes:

1. Reads final test report from Loop A
2. Compares performance results against spec targets
3. Checks Loop B iteration count (max 3)
4. Decides next action:

**Decision Logic**:
```
if all_performance_targets_met:
    return SUCCESS ✓
    
elif loop_b_iteration >= 3:
    return MAX_LOOP_B_ITERATIONS_REACHED
    
elif plateau_detected AND performance_gap_small (<10%):
    return ACCEPTABLE_PERFORMANCE (close enough)
    
else:
    # Re-run Stages 1-6 with refinement
    loop_b_iteration += 1
    focus_areas = extract_bottlenecks(test_report)
    GOTO Stage 1 with focus_areas context
```

**Loop B Re-invocation Changes**:
- **Stage 1 (Research)**: Focuses on measured bottlenecks from test report
- **Stage 2 (Constitution)**: Strengthens optimization rules for weak areas
- **Stage 3 (Spec/Tests)**: Adjusts performance thresholds based on actual results
- **Stages 4-6**: Execute with updated artifacts

**Loop B State Tracking**: Updates `output/bench/[feature-name]/loop-b-state.json`

```json
{
  "iteration": 2,
  "max_iterations": 3,
  "performance_history": [
    {
      "iteration": 0,
      "throughput_mb_s": 85.2,
      "latency_p99_ms": 12.3,
      "memory_mb": 45.7
    },
    {
      "iteration": 1,
      "throughput_mb_s": 95.3,
      "latency_p99_ms": 9.8,
      "memory_mb": 42.1,
      "improvement_percent": 11.9
    },
    {
      "iteration": 2,
      "throughput_mb_s": 98.1,
      "latency_p99_ms": 9.5,
      "memory_mb": 41.8,
      "improvement_percent": 2.9
    }
  ],
  "status": "plateau_detected"
}
```

## Feedback Loops

### Loop A: Correctness Loop (Inner)

**Purpose**: Ensure all tests pass through iterative implementation refinement

**Scope**: Within Stage 6 (Implementation)

**Controller**: `perf.loop-controller`

**Participants**: `perf.implementer`, `perf.test-runner`

**Max Iterations**: 5

**Exit Conditions**:
- ✓ All tests pass → proceed to Stage 7
- ✗ Max retries exhausted → proceed to Stage 7 with partial success

**Retry Strategy**:
- Iteration 0: Implement all tasks
- Iteration 1+: Fix only failing tasks (scope narrowing)
- Iteration 3+: Include previous error context for alternative approaches

**Key Features**:
- Incremental fixes (no rewrites of passing code)
- Error-driven refinement (detailed stack traces)
- Task-level granularity (fix specific failing tasks)

### Loop B: Performance Loop (Outer)

**Purpose**: Iteratively improve performance through research refinement and optimization

**Scope**: Entire pipeline (Stages 1-7)

**Controller**: `perf.orchestrator`

**Participants**: All 8 subagents (re-invoked with updated context)

**Max Iterations**: 3

**Exit Conditions**:
- ✓ All performance targets met → SUCCESS
- ✓ Plateau detected with acceptable gap (<10%) → ACCEPTABLE
- ✗ Max iterations reached → PERFORMANCE_LIMIT_REACHED

**Loop B Triggers**:
- Performance targets not met after successful Loop A
- Improvement potential detected (not plateaued)
- Iteration count < 3

**Context Passed Forward**:
- Bottleneck analysis from test report
- Performance history across iterations
- Previous research/constitution/spec for refinement

**Plateau Detection**:
- All metrics improved <2% from previous iteration
- Prevents infinite optimization attempts
- Triggered by `perf.test-runner` comparison logic

## Artifacts & Provenance

The workflow produces comprehensive documentation and artifacts:

### Planning Artifacts (`.perf/[feature-name]/`)

| File | Stage | Purpose |
|------|-------|---------|
| `performance-research-report.md` | 1 | Algorithm research, optimization strategies, benchmarking approaches |
| `constitution.md` | 2 | Enforceable coding rules, performance principles, anti-patterns |
| `spec.md` | 3 | Formal specification with functional/non-functional requirements |
| `tdd-plan.md` | 4 | Test-driven implementation plan with build order |
| `task-graph.json` | 5 | Atomic task DAG for implementation |

### Execution Artifacts (`output/`)

| File | Purpose |
|------|---------|
| `output/tests/[feature-name]/test-report.json` | Structured test results with pass/fail, performance metrics, error details |
| `output/bench/[feature-name]/loop-a-summary.md` | Loop A execution summary (retry history, fixes applied) |
| `output/bench/[feature-name]/loop-b-state.json` | Loop B tracking (iteration count, performance history, plateau detection) |
| `output/bench/[feature-name]/implementation-log.md` | Task completion log, constitution compliance, issues encountered |

### Deliverables

| Output | Location | Description |
|--------|----------|-------------|
| **Source Code** | `src/` | High-performance implementation following constitution |
| **Test Suite** | `tests/` | Comprehensive correctness + performance tests |
| **Documentation** | `.perf/` | Complete provenance trail from research to code |

## Usage Examples

### Example 1: CSV Parser with Throughput Target

**User Request**:
```
Generate a high-performance CSV parser in Python 3.12 that can process 
100 MB/s on typical hardware. Support RFC 4180 quoting, handle edge cases 
like empty fields and escaped quotes, and include comprehensive tests.
```

**Invocation**:
```
@perf.orchestrator Generate a CSV parser with 100 MB/s throughput target in Python 3.12
```

**Expected Workflow**:
1. **Stage 1**: Research Python CSV parsing strategies (compare csv module, pandas, custom parser)
2. **Stage 2**: Create constitution mandating `memoryview` for zero-copy, prohibiting string methods in hot paths
3. **Stage 3**: Write spec with FR-01 (parse valid CSV), EDGE-01 (empty fields), benchmark tests with 100 MB/s threshold
4. **Stage 4**: Plan TDD steps (data structure → basic parsing → quoting → edge cases)
5. **Stage 5**: Decompose into 35 atomic tasks
6. **Stage 6**: Implement + test loop (may retry 1-2 times for edge case fixes)
7. **Stage 7**: If throughput is 85 MB/s, Loop B iteration focuses on byte-level optimizations

**Outputs**:
- `src/csv_parser.py` (optimized parser implementation)
- `tests/test_correctness.py`, `tests/test_performance.py`, `tests/test_property.py`
- Full `.perf/csv-parser/` documentation trail

### Example 2: Matrix Multiplication with Memory Constraints

**User Request**:
```
Implement fast matrix multiplication in Rust 1.75 for f64 matrices. 
Target 50 GFLOPS on single-threaded execution. Memory usage must not 
exceed 2x input size.
```

**Invocation**:
```
@perf.orchestrator Implement matrix multiplication in Rust with 50 GFLOPS target and 2x memory limit
```

**Expected Workflow**:
1. **Stage 1**: Research blocked algorithms, SIMD intrinsics, cache-oblivious designs
2. **Stage 2**: Constitution mandates cache blocking, AVX2 intrinsics for inner loop
3. **Stage 3**: Spec includes memory allocation tests, GFLOPS benchmarks across matrix sizes
4. **Stage 6**: Loop A may iterate 2-3 times to fix SIMD alignment issues
5. **Stage 7**: If GFLOPS is 42, Loop B iteration tightens blocking parameters

**Loop B Progression**:
- Iteration 0: 42 GFLOPS (naive blocked algorithm)
- Iteration 1: 48 GFLOPS (added SIMD to hot path)
- Iteration 2: 51 GFLOPS (optimized block size based on L2 cache) ✓

### Example 3: JSON Parser with Latency Requirements

**User Request**:
```
Create a zero-allocation JSON parser in Go 1.21 for real-time systems. 
Parse latency must be under 5ms p99 for documents up to 100KB. 
Support streaming mode.
```

**Invocation**:
```
@perf.orchestrator Build Go JSON parser with <5ms p99 latency for 100KB docs
```

**Key Constitution Rules** (Stage 2):
- `[ALGO-01] Use single-pass recursive descent parser with look-ahead`
- `[DATA-01] Pre-allocate token buffer for expected document size`
- `[OPT-01] Use unsafe.Pointer for zero-copy string extraction`
- `[BAN-01] NEVER use reflect package in hot path`

**Performance Testing** (Stage 3):
- Latency benchmarks: p50, p90, p99 at 1KB, 10KB, 100KB
- Streaming throughput test: 1MB document
- Memory allocation test: must allocate exactly once

### Example 4: Loop B Refinement - Sorting Algorithm

**Initial Implementation** (Loop B Iteration 0):
- Throughput: 250 MB/s (target: 400 MB/s)
- Algorithm: Standard quicksort

**Loop B Iteration 1**:
- **Research focus**: "Why is quicksort underperforming? Alternative sorting for this data pattern?"
- **Constitution update**: `[ALGO-02] Use hybrid TimSort+Radix for partially sorted data`
- **Result**: 380 MB/s (improvement: 52%)

**Loop B Iteration 2**:
- **Research focus**: "Micro-optimizations for sorting hot path"
- **Constitution update**: `[OPT-03] Use SIMD for comparison operations in inner loop`
- **Result**: 405 MB/s (improvement: 6.6%) ✓ Target met

## Best Practices

### When to Use This Workflow

✅ **Good Fit**:
- Performance-critical components (parsers, encoders, algorithms)
- Library development with quantified performance goals
- Migrating slow implementations to high-performance versions
- Code that will be benchmarked or profiled
- Situations where correctness AND performance are both critical

❌ **Not Recommended**:
- Quick prototypes without performance requirements
- UI components or business logic (use standard development)
- One-off scripts or tools
- When performance is "nice to have" but not measured

### Maximizing Success

1. **Provide Clear Performance Targets**: Quantify throughput, latency, memory with units
2. **Specify Scale**: Mention expected input sizes (KB, MB, GB, record counts)
3. **Mention Constraints**: Real-time requirements, memory limits, platform specifics
4. **Include Context**: "This will process log files" helps research focus

**Good Request**:
```
Generate a log parser in Python 3.12 that processes 200 MB/s for 
1-10 MB files typical of application logs. Support JSON and plaintext 
formats. Memory usage under 50 MB.
```

**Poor Request**:
```
Write a fast log parser.
```

### Understanding Loop Outcomes

**Loop A Outcomes**:
- ✓ **Success (most common)**: Tests pass within 1-3 iterations
- ⚠ **Partial success**: Some tests pass, but max retries exhausted (usually property-based edge cases)
- ✗ **Failure**: Rare if task decomposition is sound

**Loop B Outcomes**:
- ✓ **Targets met**: Performance goals achieved
- ✓ **Acceptable plateau**: Within 10% of targets, improvement <2% per iteration
- ⚠ **Iteration limit**: 3 iterations exhausted, didn't reach targets (may need higher-level redesign)

### Handling Edge Cases

**If Loop A fails repeatedly**:
- Check task decomposition quality (may need manual task graph adjustment)
- Verify test correctness (tests may be too strict or have bugs)
- Review constitution for contradictory rules

**If Loop B plateaus**:
- Performance target may be unrealistic for the algorithm class
- Consider algorithmic redesign (may need to manually update constitution)
- Hardware/platform limitations may be reached

**If constitution rules conflict**:
- Use research report to arbitrate (cite performance data)
- Prioritize correctness over performance (establish in constitution testing philosophy)

## Extensibility & Customization

### Adding New Agents

The workflow supports extending with domain-specific agents:

**Example: Adding a Security Auditor**:
```markdown
---
name: perf.security-auditor
description: "Audits generated code for security vulnerabilities..."
model: sonnet
readonly: true
---
```

Insert between Stage 6 and Stage 7 in orchestrator pipeline.

### Custom Test Frameworks

The `perf.test-runner` supports language-specific test frameworks:

- **Python**: pytest, pytest-benchmark, hypothesis
- **Rust**: cargo test, criterion
- **Go**: go test, testing/quick
- **JavaScript**: jest, vitest

Extend by modifying test command patterns in the test-runner agent.

### Alternative Loop Strategies

**Modify Loop A**:
- Increase max iterations from 5 to 10 for complex algorithms
- Add intermediate checkpoints (e.g., run property tests only after unit tests pass)

**Modify Loop B**:
- Increase max iterations from 3 to 5 for heavily optimized code
- Add plateau threshold customization (2% default)

### Domain-Specific Constitutions

Create reusable constitution templates:

**Example: HPC Constitution Template**:
```markdown
## Performance Principles
- [PERF-01] Cache-oblivious algorithms mandatory for large data
- [PERF-02] NUMA awareness required for multi-socket systems
...
```

Pass as seed to `perf.constitution-writer` in Stage 2.

## Technical Specifications

### Execution Environment

**Required Tools**:
- Target language runtime (Python 3.9+, Rust 1.70+, Go 1.20+, etc.)
- Testing framework (pytest, cargo test, etc.)
- Benchmarking tools (pytest-benchmark, criterion, etc.)

**Disk Space**: ~50 MB per feature (including all artifacts)

**Execution Time**:
- Small feature (100-300 lines): 10-20 minutes
- Medium feature (500-1000 lines): 30-60 minutes
- Large feature (1000+ lines): 1-3 hours
- Loop B iterations add 50-75% to base time

### File Naming Conventions

- Feature name: Kebab-case (e.g., `csv-parser`, `matrix-multiply`)
- Test files: `test_<category>.py` (e.g., `test_correctness.py`, `test_performance.py`)
- Source files: Follow language conventions (e.g., `snake_case.py`, `kebab-case.rs`)

### Absolute Path Requirements

All file paths in agent handoffs must be absolute paths for reliable cross-agent communication.

## Limitations & Known Issues

### Current Limitations

1. **Language Support**: Optimized for Python, Rust, Go, JavaScript/TypeScript. Other languages require test framework customization.
2. **Loop A Complexity**: Tasks exceeding 30 lines may need manual splitting.
3. **Property-Based Test Generation**: May miss domain-specific invariants (manual test authoring may be needed).
4. **Loop B Plateau Detection**: 2% threshold may be too strict for noisy benchmarks.

### Known Issues

1. **Stack Depth in Recursive Algorithms**: Task decomposition may struggle with deeply recursive implementations.
   - **Workaround**: Manually specify iterative approach in constitution.

2. **Cross-File Dependencies**: Tasks modifying multiple files simultaneously are not supported.
   - **Workaround**: Split into sequential tasks (file A → file B).

3. **Non-Deterministic Benchmarks**: Tests may be flaky if system load varies.
   - **Workaround**: Run benchmarks in isolated environment; increase iteration count for statistical significance.

## Future Enhancements

### Roadmap

**Phase 1** (Current):
- ✓ Core 9-agent pipeline
- ✓ Dual feedback loops
- ✓ Python/Rust/Go/JS support

**Phase 2** (Planned):
- [ ] Parallel task execution (independent tasks in task graph)
- [ ] GPU optimization support (CUDA, Metal)
- [ ] Distributed benchmarking (multi-node performance tests)
- [ ] Cost-aware optimization (balance performance vs. resource cost)

**Phase 3** (Future):
- [ ] Auto-tuning (genetic algorithms for constitution parameter optimization)
- [ ] Profiler integration (real-world profiling data feeding back to Loop B)
- [ ] Cross-language optimization (polyglot systems)

### Community Contributions

Contributions are welcome in these areas:
- Additional language support (C++, Java, C#, etc.)
- Domain-specific constitution templates (web servers, ML inference, crypto)
- Alternative benchmarking strategies (energy efficiency, carbon footprint)

## References

### Related Workflows

- **builder**: Workflow for creating new multi-agent workflows (meta-workflow)
- **prodify**: React prototype to production-grade app transformation

### External Resources

- [TDD Best Practices](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- [Performance Engineering Guide](https://easyperf.net/blog/)
- [Hypothesis (Property-Based Testing)](https://hypothesis.readthedocs.io/)
- [pytest-benchmark Documentation](https://pytest-benchmark.readthedocs.io/)

### Agent Implementations

All agent source files: `workflows/perf/agents/*.md`

### Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-25 | Initial specification |

---

**Maintained by**: AI Workflow Kit Project  
**License**: See LICENSE file  
**Support**: Open an issue on GitHub for questions or bug reports
