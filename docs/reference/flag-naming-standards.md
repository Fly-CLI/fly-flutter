# CLI Flag Naming Standards

This document defines the standardized naming conventions for CLI flags used across all Fly CLI commands.

## Overview

The Fly CLI follows consistent flag naming patterns to improve user experience, reduce confusion, and ensure maintainability across all commands.

## Global Flags

Global flags apply to all commands and are available at both the top-level and within individual commands.

### Format Flags

- **`--format`** / **`-f`** - Output format specification
  - Allowed values: `human`, `json`, `ai`
  - Default: `human`
  - Examples:
    ```bash
    fly create my_app --format=json
    fly schema --format=ai
    ```

### Verbosity Flags

- **`--verbose`** / **`-v`** - Enable verbose output
  - Boolean flag (negatable: false)
  - Shows detailed execution information
  - Example: `fly create my_app --verbose`

- **`--quiet`** / **`-q`** - Suppress output
  - Boolean flag (negatable: false)
  - Reduces output to minimal messages
  - Example: `fly create my_app --quiet`

- **`--debug`** / **`-d`** - Enable debug mode
  - Boolean flag
  - Shows debug-level information and stack traces
  - Example: `fly create my_app --debug`

### Execution Flags

- **`--plan`** - Run in plan mode (dry-run)
  - Boolean flag (negatable: false)
  - Shows execution plan without making changes
  - Example: `fly create my_app --plan`

### Logging Flags

- **`--log-level`** - Logging level specification
  - Allowed values: `trace`, `debug`, `info`, `warn`, `error`, `fatal`
  - Example: `fly create my_app --log-level=debug`

- **`--log-format`** - Logging format
  - Allowed values: `human`, `json`
  - Example: `fly create my_app --log-format=json`

- **`--log-file`** - Write logs to file
  - Takes a file path as value
  - Example: `fly create my_app --log-file=logs.txt`

- **`--trace`** - Enable extra diagnostic tracing
  - Boolean flag (negatable: false)
  - Example: `fly create my_app --trace`

### Output Control Flags

- **`--no-color`** - Disable color output
  - Boolean flag (negatable: false)
  - Useful for automated environments
  - Example: `fly create my_app --no-color`

## Input/Output Path Flags

Standard flags for specifying input and output paths.

### Input Paths

- **`--input-file`** - Path to an input file
  - Takes a file path as value
  - Example: `fly template validate --input-file=template.yaml`

- **`--input-dir`** - Path to an input directory
  - Takes a directory path as value
  - Example: `fly analyze --input-dir=src/`

### Output Paths

- **`--output-file`** / **`-o`** - Path to an output file
  - Takes a file path as value
  - Abbreviation `-o` is reserved for output files
  - Example:
    ```bash
    fly schema --output-file=schema.json
    fly context --output-file=.ai/context.md
    ```

- **`--output-dir`** - Path to an output directory
  - Takes a directory path as value
  - No abbreviation (to avoid conflicts)
  - Example:
    ```bash
    fly create my_app --output-dir=/tmp/projects
    fly add screen login --output-dir=lib/features/auth
    ```

## Naming Conventions

### General Rules

1. **Kebab-case for multi-word flags**: Use hyphens to separate words
   - ✅ Good: `--output-file`, `--log-level`, `--input-dir`
   - ❌ Bad: `--outputFile`, `--output_file`, `--logLevel`

2. **Single words for simple concepts**: Use single words when appropriate
   - ✅ Good: `--verbose`, `--debug`, `--plan`
   - ❌ Bad: `--be-verbose`, `--enable-debug`

3. **Consistent prefixes**: Use consistent prefixes for related flags
   - Input: `--input-file`, `--input-dir`
   - Output: `--output-file`, `--output-dir`
   - Log: `--log-level`, `--log-format`, `--log-file`

### Abbreviation Rules

1. **Reserve common abbreviations for standard flags**:
   - `-v` → `--verbose`
   - `-q` → `--quiet`
   - `-d` → `--debug`
   - `-f` → `--format`
   - `-o` → `--output-file` (reserved globally for output files)

2. **Avoid conflicts**: Do not use reserved abbreviations for command-specific flags
   - ❌ Bad: `--organization -o` (conflicts with `--output-file -o`)
   - ✅ Good: `--organization` (no abbreviation) or `--org` with different abbreviation

3. **Single-letter abbreviations only**: Use single letters for abbreviations
   - ✅ Good: `-v`, `-f`, `-o`
   - ❌ Bad: `-vf`, `-out`

### Flag Types

1. **Boolean flags**: Use `addFlag()` for true/false values
   - No value required
   - Use `negatable: false` for flags that shouldn't be negated
   - Example: `--verbose`, `--quiet`, `--plan`

2. **Value flags**: Use `addOption()` for flags that take a value
   - Specify `allowed` values when restricted
   - Provide `defaultsTo` when appropriate
   - Example: `--format`, `--log-level`

3. **Multi-value flags**: Use `addMultiOption()` for flags that accept multiple values
   - Example: `--platforms`, `--features`

## Standard Flags

All Fly CLI commands use standardized flag names. The following flags are consistently used across all commands:

- **`--format`** / **`-f`** - Output format (replaces legacy `--output`)
- **`--output-file`** / **`-o`** - Output file path (replaces legacy `--file`)
- **`--output-dir`** - Output directory path

## Examples

### Basic Command Usage

```bash
# Create project with JSON output
fly create my_app --format=json --verbose

# Export schema to file
fly schema --output-file=schema.json --format=json

# Add screen with custom output directory
fly add screen login --output-dir=lib/features/auth --plan

# Context export with AI format
fly context --output-file=.ai/context.md --format=ai
```

### Debug and Troubleshooting

```bash
# Debug mode with verbose output
fly create my_app --debug --verbose

# Trace logging to file
fly doctor --trace --log-file=doctor.log --log-level=trace
```

## Command-Specific Flags

While global and input/output flags follow strict standards, command-specific flags have more flexibility:

1. Use descriptive names that match the command's domain
2. Follow kebab-case convention
3. Avoid conflicts with global flags
4. Document in command help text

### Examples of Good Command-Specific Flags

```bash
# Create command
--template, --organization, --platforms, --from-manifest

# Add screen command
--feature, --type, --with-viewmodel, --with-tests

# Schema command
--format (export format: json-schema, openapi, cli-spec)
--command (filter specific command)
--include-examples, --include-validation
```

## Testing Flag Naming

When adding new flags, ensure:

1. Flag name follows kebab-case
2. Abbreviation doesn't conflict with global flags
3. Help text is clear and descriptive
4. Flag works with both long and short forms
5. Integration tests verify flag behavior

## References

- [Args Package Documentation](https://pub.dev/packages/args)
- [Command System Architecture](../architecture/command-system.md)
- [Command Workflow](../architecture/command-workflow.md)

