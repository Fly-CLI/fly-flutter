# Fly CLI Development Workflow

This guide explains the development workflow for the Fly CLI, including when to use compiled
binaries vs. `dart run`, and best practices for efficient development.

---

## Quick Start

### For Regular Development

Use `dart run` for fast iteration—no compilation needed:

```bash
# Run any command directly
dart run packages/fly_cli/bin/fly.dart --version
dart run packages/fly_cli/bin/fly.dart generate project my_app
dart run packages/fly_cli/bin/fly.dart generate feature home
```

**Benefits**:

- ✅ No compilation step required
- ✅ Always uses latest code
- ✅ Fast iteration cycle
- ✅ Perfect for active development

### For Performance Testing

Compile the binary when you need to measure actual performance:

```bash
# Compile the CLI
./scripts/development/build-cli.sh

# Use compiled binary
packages/fly_cli/bin/fly --version
```

**Benefits**:

- ✅ 37x faster startup (0.6s vs 20-26s)
- ✅ Accurate performance measurements
- ✅ Production-like execution

---

## Development Modes

### Mode 1: Active Development (Recommended)

**When**: Writing code, debugging, testing features

**Command**:

```bash
dart run packages/fly_cli/bin/fly.dart <command>
```

**Workflow**:

1. Make code changes
2. Run command directly with `dart run`
3. See results immediately
4. Repeat

**Example**:

```bash
# Edit code in template_manager.dart
vim packages/fly_cli/lib/src/core/scaffolding/template_manager.dart

# Test immediately
dart run packages/fly_cli/bin/fly.dart --version

# Make more changes
# Test again
dart run packages/fly_cli/bin/fly.dart generate project test
```

### Mode 2: Performance Testing

**When**: Measuring performance, running benchmarks, CI/CD

**Command**:

```bash
# Compile first
./scripts/development/build-cli.sh

# Then use binary
packages/fly_cli/bin/fly <command>
```

**Workflow**:

1. Compile binary: `./scripts/development/build-cli.sh`
2. Run performance tests
3. Measure results
4. Recompile if code changes

**Example**:

```bash
# Compile
./scripts/development/build-cli.sh

# Benchmark
time packages/fly_cli/bin/fly --version

# Run integration tests
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh
```

### Mode 3: Integration Tests

**When**: Running integration test suite

**Command**:

```bash
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh
```

**Behavior**:

- Script automatically detects compiled binary
- Uses binary if available (fast)
- Falls back to `dart run` if binary missing (convenient)

**Example**:

```bash
# Option 1: With compiled binary (recommended for CI)
./scripts/development/build-cli.sh
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh

# Option 2: Without binary (convenient for development)
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh
```

---

## Build Script

### Compiling the CLI

Use the build script to compile the CLI to a native binary:

```bash
./scripts/development/build-cli.sh
```

**Options**:

```bash
# Basic compilation
./scripts/development/build-cli.sh

# Force recompilation
./scripts/development/build-cli.sh --force

# Verbose output
./scripts/development/build-cli.sh --verbose

# Help
./scripts/development/build-cli.sh --help
```

**Output**:

- Binary: `packages/fly_cli/bin/fly` (Unix) or `bin/fly.exe` (Windows)
- Size: ~15-20 MB (platform-dependent)
- Git-ignored: Binary is excluded from version control

### When to Recompile

Recompile the binary when:

- ✅ Before running performance benchmarks
- ✅ Before running integration tests (for speed)
- ✅ Before CI/CD pipeline execution
- ✅ Before production releases
- ✅ After significant code changes (if using binary)

**Don't recompile**:

- ❌ During active development (use `dart run` instead)
- ❌ For every small code change
- ❌ When just testing features

---

## Common Workflows

### Workflow 1: Feature Development

```bash
# 1. Make code changes
vim packages/fly_cli/lib/src/core/scaffolding/template_manager.dart

# 2. Test with dart run (fast iteration)
dart run packages/fly_cli/bin/fly.dart generate project test_app

# 3. Make more changes
# 4. Test again
dart run packages/fly_cli/bin/fly.dart generate project test_app2

# 5. When feature is complete, compile and test
./scripts/development/build-cli.sh
packages/fly_cli/bin/fly generate project final_test
```

### Workflow 2: Performance Optimization

```bash
# 1. Compile binary
./scripts/development/build-cli.sh

# 2. Benchmark current performance
time packages/fly_cli/bin/fly --version

# 3. Make optimizations
vim packages/fly_cli/lib/src/core/scaffolding/template_manager.dart

# 4. Recompile
./scripts/development/build-cli.sh --force

# 5. Benchmark again
time packages/fly_cli/bin/fly --version

# 6. Compare results
```

### Workflow 3: Integration Testing

```bash
# Option A: With compiled binary (faster)
./scripts/development/build-cli.sh
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh

# Option B: Without binary (convenient)
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh
```

### Workflow 4: CI/CD Pipeline

```bash
# In CI script
./scripts/development/build-cli.sh
packages/fly_cli/bin/fly --version
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh
```

---

## Performance Comparison

### Startup Time

| Method          | Time   | Use Case                            |
|-----------------|--------|-------------------------------------|
| `dart run`      | 20-26s | Development, iteration              |
| Compiled binary | 0.6s   | Performance testing, CI, production |

### Integration Tests (14 scenarios)

| Method          | Time            | Use Case                |
|-----------------|-----------------|-------------------------|
| `dart run`      | ~336s (5.6 min) | Development             |
| Compiled binary | ~21s            | CI, performance testing |

---

## Best Practices

### ✅ Do

- Use `dart run` during active development
- Compile binary before performance testing
- Compile binary before CI/CD runs
- Recompile after significant code changes (if using binary)
- Let integration script auto-detect binary

### ❌ Don't

- Don't recompile for every small change
- Don't use binary during active development (slower iteration)
- Don't commit compiled binary (it's git-ignored)
- Don't worry about binary being out of date (script handles it)

---

## Troubleshooting

### Binary Not Found

If the integration script can't find the binary:

```bash
# Compile it
./scripts/development/build-cli.sh

# Or use dart run directly
dart run packages/fly_cli/bin/fly.dart <command>
```

### Binary Out of Date

If you suspect the binary is outdated:

```bash
# Force recompilation
./scripts/development/build-cli.sh --force
```

### Performance Issues

If `dart run` is slow (expected):

```bash
# This is normal - use compiled binary for performance testing
./scripts/development/build-cli.sh
packages/fly_cli/bin/fly <command>
```

---

## Script Reference

### Build Script

**Location**: `scripts/development/build-cli.sh`

**Usage**:

```bash
./scripts/development/build-cli.sh [OPTIONS]
```

**Options**:

- `-v, --verbose`: Enable verbose output
- `-f, --force`: Force recompilation even if binary exists
- `-h, --help`: Show help message

**Output**:

- Creates `packages/fly_cli/bin/fly` (Unix) or `bin/fly.exe` (Windows)
- Binary is executable and ready to use

### Integration Test Script

**Location**: `packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh`

**Usage**:

```bash
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh
```

**Behavior**:

- Automatically detects compiled binary
- Uses binary if available (fast)
- Falls back to `dart run` if binary missing

---

## Summary

| Scenario              | Command                                                                      | When to Use              |
|-----------------------|------------------------------------------------------------------------------|--------------------------|
| **Development**       | `dart run packages/fly_cli/bin/fly.dart`                                     | Active coding, debugging |
| **Performance**       | `./scripts/development/build-cli.sh && packages/fly_cli/bin/fly`             | Benchmarks, measurements |
| **Integration Tests** | `./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh` | Test suite execution     |
| **CI/CD**             | Compile + use binary                                                         | Automated pipelines      |

**Key Principle**: Use `dart run` for development speed, compile binary for performance.

---

## Related Documentation

- [Performance Improvements](./PERFORMANCE_IMPROVEMENTS.md) - Detailed performance analysis
- [Performance Analysis Report](./PERFORMANCE_ANALYSIS_REPORT.md) - Original analysis
- [Build Script](../../scripts/development/build-cli.sh) - Compilation script

---

**Last Updated**: November 20, 2024

