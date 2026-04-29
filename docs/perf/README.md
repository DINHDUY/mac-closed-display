# Performance-First Code Generation

Generate high-performance, correctness-guaranteed code from natural language feature requests using a multi-agent workflow with test-driven development and iterative optimization.

## What It Does

This workflow orchestrates 9 specialized agents through a rigorous pipeline that:

1. **Researches** optimal algorithms, data structures, and language-specific optimizations
2. **Creates** enforceable performance rules and coding standards (constitution)
3. **Authors** comprehensive test suites (correctness + performance benchmarks)
4. **Plans** test-driven implementation with dependency management
5. **Implements** code incrementally following performance best practices
6. **Tests & Refines** through dual feedback loops for correctness and performance

## When to Use

**✓ Good For:**
- Performance-critical components (parsers, encoders, algorithms)
- Library development with quantified performance goals
- Optimizing existing code with measurable targets
- Code that will be benchmarked or profiled

**✗ Not Recommended For:**
- Quick prototypes without performance requirements
- UI components or standard business logic
- One-off scripts or utilities

## How to Use

### Basic Usage

Invoke the orchestrator with a feature request that includes:
- **What** you want to build
- **Target language** and version
- **Performance goals** (throughput, latency, memory) with units
- **Expected scale** (input sizes, data volumes)

**Example 1: CSV Parser**
```
@perf.orchestrator Generate a CSV parser in Python 3.12 that processes 
100 MB/s for typical data files. Support RFC 4180 quoting and handle 
edge cases like empty fields and escaped quotes.
```

**Example 2: Matrix Multiplication**
```
@perf.orchestrator Implement matrix multiplication in Rust 1.75 for f64 
matrices. Target 50 GFLOPS on single-threaded execution. Memory usage 
must not exceed 2x input size.
```

**Example 3: JSON Parser**
```
@perf.orchestrator Create a zero-allocation JSON parser in Go 1.21 for 
real-time systems. Parse latency must be under 5ms p99 for documents 
up to 100KB.
```

### What You Get

The workflow produces:

**Source Code:**
- `src/` - High-performance implementation following research-based best practices
- `tests/` - Comprehensive test suite (correctness + performance + property-based tests)

**Documentation:**
- `.perf/[feature]/performance-research-report.md` - Algorithm research and optimization strategies
- `.perf/[feature]/constitution.md` - Enforceable coding rules and performance principles
- `.perf/[feature]/spec.md` - Formal specification with requirements and acceptance criteria
- `.perf/[feature]/tdd-plan.md` - Test-driven implementation plan
- `.perf/[feature]/task-graph.json` - Atomic task dependency graph

**Results:**
- `output/tests/[feature]/test-report.json` - Test results with performance metrics
- `output/bench/[feature]/` - Benchmark results and optimization history

## How It Works

### Two Feedback Loops

**Loop A (Correctness)** - Inner loop that ensures tests pass:
- Implement code → Run tests → Fix failures → Repeat (max 5 iterations)

**Loop B (Performance)** - Outer loop that optimizes performance:
- If targets not met, refine research and re-run pipeline (max 3 iterations)
- Tracks performance progression and detects plateaus

### Agent Workflow

```
User Request
    ↓
Research Performance → Create Constitution → Write Spec & Tests
    ↓
Plan TDD Steps → Decompose into Tasks → Implement & Test (Loop A)
    ↓
Analyze Performance → Optimize if needed (Loop B) → Done
```

## Tips for Best Results

1. **Be Specific**: Include exact performance targets with units (MB/s, ops/sec, ms latency)
2. **Mention Scale**: Specify expected input sizes (KB, MB, GB, record counts)
3. **State Constraints**: Real-time requirements, memory limits, platform specifics
4. **Provide Context**: "This will process log files" helps focus research

**Good Request:**
> Generate a log parser in Python 3.12 that processes 200 MB/s for 1-10 MB files 
> typical of application logs. Support JSON and plaintext formats. Memory usage under 50 MB.

**Poor Request:**
> Write a fast log parser.

## Requirements

- Target language runtime (Python 3.9+, Rust 1.70+, Go 1.20+, etc.)
- Testing framework (pytest, cargo test, etc.)
- Benchmarking tools (pytest-benchmark, criterion, etc.)

## Execution Time

- Small feature (100-300 lines): 10-20 minutes
- Medium feature (500-1000 lines): 30-60 minutes
- Large feature (1000+ lines): 1-3 hours
- Loop B iterations add 50-75% per iteration

## Documentation

See [perf-spec.md](./perf-spec.md) for complete technical specification including:
- Detailed agent architecture
- Stage-by-stage workflow breakdown
- Advanced usage examples
- Extensibility guide

## Agents

- `perf.orchestrator` - Master coordinator managing the entire pipeline
- `perf.researcher` - Performance research specialist
- `perf.constitution-writer` - Rule codification expert
- `perf.spec-writer` - Specification and test authoring
- `perf.planner` - TDD planning specialist
- `perf.task-decomposer` - Task atomization expert
- `perf.loop-controller` - Inner loop manager (correctness)
- `perf.implementer` - Code generation specialist
- `perf.test-runner` - Test execution and benchmarking

---

**Note:** For complete architecture details, loop mechanics, and advanced customization, refer to [perf-spec.md](./perf-spec.md).
