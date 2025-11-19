# Fly Foundation Multi-Brick Architecture Differences

This document describes intentional structural and behavioral differences between the legacy
monolithic `fly_foundation` brick and the new multi-brick architecture.

## Overview

The new multi-brick architecture (`fly_foundation_project`, `fly_foundation_feature`,
`fly_foundation_service`) replaces the legacy monolithic brick. While functionally equivalent, there
are intentional improvements and structural changes.

## Classification

Differences are classified as:

- **Purely Structural**: Changes to file organization that don't affect behavior
- **Behaviorally Equivalent**: Different implementation, same end result
- **Behaviorally Improved**: Better behavior than legacy system

## Structural Differences

### 1. No `modes/` Directory Structure

**Legacy:**

```
generated_project/
├── modes/
│   ├── project/
│   ├── feature/
│   └── service/
└── [other files]
```

**New:**

```
generated_project/
└── [files directly in root]
```

**Classification:** Purely Structural

**Reason:** The new architecture only generates files for the active module, eliminating the need
for a `modes/` directory structure and post-generation file reorganization.

**Impact:** Generated projects have a cleaner structure without intermediate directories.

### 2. No Post-Generation Cleanup

**Legacy:**

- Generated all modules regardless of mode
- Post-generation hook (`post_gen.dart`) moved files from `modes/` to root
- Removed inactive module files
- Cleaned up `common/` directories

**New:**

- Only generates files for active module
- No post-generation cleanup needed
- No file reorganization

**Classification:** Behaviorally Improved

**Reason:** The orchestrator only invokes the required brick, so no cleanup is needed. This improves
performance and eliminates potential file operation errors.

**Impact:** Faster generation, no risk of cleanup failures, cleaner output.

### 3. No `common/` Directories

**Legacy:**

- Had `common/services/` directories in templates
- Post-generation hook removed these

**New:**

- No `common/` directories in templates
- All files are module-specific

**Classification:** Purely Structural

**Reason:** With module-specific bricks, there's no need for shared template partials in a `common/`
directory.

**Impact:** Simpler template structure.

## Behavioral Differences

### 1. Module Selection

**Legacy:**

- Generated all modules, then selected active ones via hooks
- Used `ModuleRegistry` to determine active modules
- Post-generation cleanup removed inactive files

**New:**

- Planning library determines which brick to invoke
- Only required brick is executed
- No inactive files generated

**Classification:** Behaviorally Improved

**Reason:** More efficient - only generates what's needed. Reduces generation time and disk I/O.

**Impact:** Faster generation, less disk usage, cleaner output.

### 2. Variable Derivation

**Legacy:**

- Variable derivation in hooks (`hooks/plugins/variables/`)
- Multiple planner classes for different aspects
- Complex composition logic

**New:**

- Variable derivation in planning library (`fly_foundation_planning`)
- Cleaner separation of concerns
- Reusable across CLI and other tools

**Classification:** Behaviorally Equivalent

**Reason:** Better architecture - planning logic is now a reusable library, not tied to Mason hooks.

**Impact:** Planning logic can be used by other tools, easier to test, better maintainability.

### 3. Error Handling

**Legacy:**

- Errors in hooks could leave partial generation
- Post-generation cleanup might fail silently

**New:**

- Orchestrator handles errors at brick level
- No cleanup needed, so no cleanup errors
- Better error messages

**Classification:** Behaviorally Improved

**Reason:** Cleaner error handling without post-generation complications.

**Impact:** Better error messages, no partial cleanup states.

## File Organization Differences

### Project Generation

**Legacy:**

- Files in `modes/project/` moved to root
- Feature files in `modes/feature/` removed if not active
- Service files in `modes/service/` removed if not active

**New:**

- Files generated directly in target directory
- Only project files generated (no feature/service files)

**Classification:** Purely Structural

**Impact:** Same final structure, cleaner generation process.

### Feature Generation

**Legacy:**

- Feature files in `modes/feature/` moved to appropriate locations
- Post-generation cleanup removed inactive modules

**New:**

- Feature files generated directly in target directory
- Only feature files generated

**Classification:** Purely Structural

**Impact:** Same final structure, cleaner generation process.

### Service Generation

**Legacy:**

- Service files in `modes/service/` moved to appropriate locations
- Post-generation cleanup removed inactive modules

**New:**

- Service files generated directly in target directory
- Only service files generated

**Classification:** Purely Structural

**Impact:** Same final structure, cleaner generation process.

## Template Variable Differences

### Variable Names

**Status:** Mostly equivalent, some improvements

**Changes:**

- Some variable names may have been standardized
- Better consistency across modules

**Classification:** Behaviorally Equivalent

**Impact:** Templates may need minor updates if using custom variables.

### Derived Variables

**Status:** Equivalent functionality, better organization

**Changes:**

- Derived variables computed in planning library
- Same variables available, better derivation logic

**Classification:** Behaviorally Equivalent

**Impact:** Same variables available, better maintainability.

## Performance Differences

### Generation Speed

**Legacy:**

- Generated all modules, then cleaned up
- Slower due to unnecessary generation and cleanup

**New:**

- Only generates required module
- Faster due to less work

**Classification:** Behaviorally Improved

**Impact:** Significantly faster generation, especially for feature/service generation.

### Disk I/O

**Legacy:**

- Generated all files, then deleted inactive ones
- More disk I/O

**New:**

- Only generates required files
- Less disk I/O

**Classification:** Behaviorally Improved

**Impact:** Less disk usage, faster generation.

## Testing Differences

### Test Structure

**Legacy:**

- Tests in `hooks/test/`
- Golden files in `test/goldens/`

**New:**

- Planning library tests in `packages/fly_foundation_planning/test/`
- Integration tests in `packages/fly_cli/test/integration/`
- Golden files to be created in brick test directories

**Classification:** Purely Structural

**Impact:** Better test organization, clearer separation of concerns.

## Migration Notes

### For Users

**No action required** - The CLI automatically uses the new architecture. Generated projects have
the same structure and functionality.

### For Developers

1. **Template Updates**: If you have custom templates that reference the legacy structure, update
   them to use the new brick structure.

2. **Test Updates**: Update any tests that reference legacy paths or hook behavior.

3. **Documentation**: Update documentation that references the legacy brick or hooks.

## Summary

| Category            | Legacy                    | New                      | Classification          |
|---------------------|---------------------------|--------------------------|-------------------------|
| File Structure      | `modes/` directory        | Direct generation        | Purely Structural       |
| Post-Generation     | Cleanup required          | No cleanup               | Behaviorally Improved   |
| Module Selection    | Generate all, then filter | Generate only needed     | Behaviorally Improved   |
| Variable Derivation | In hooks                  | In planning library      | Behaviorally Equivalent |
| Error Handling      | Hook-level                | Orchestrator-level       | Behaviorally Improved   |
| Performance         | Slower (generate all)     | Faster (generate needed) | Behaviorally Improved   |
| Test Organization   | In hooks                  | In packages              | Purely Structural       |

## Conclusion

The new multi-brick architecture provides the same functionality as the legacy system with
significant improvements in performance, maintainability, and error handling. All structural
differences are intentional improvements that don't affect the end result for users.

