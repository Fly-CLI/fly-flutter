<!-- 0491ed5a-57e3-4bc8-985e-74ab91732a4c 10711b5f-ea3a-4ac7-bd91-8bcc09420e20 -->
# Standardize CLI Command Workflow

## Current State Analysis

### Current Command Flow

**Execution Sequence:**

1. `CommandRunner.run()` - Entry point, parses args
2. `FlyCommand.run()` - Main execution loop:

- Context update (argResults sync)
- Validation phase (priority-ordered validators)
- Lifecycle: `onBeforeExecute()`
- Middleware pipeline (DryRun → Logging → Metrics → optional → execute())
- Lifecycle: `onAfterExecute()`
- Result formatting/output
- Error handling: `onError()` with classification

**Strengths:**

- ✅ Command Design Pattern implemented
- ✅ Middleware pipeline (Express.js/Koa.js pattern)
- ✅ Validation chain with priorities
- ✅ Lifecycle hooks for extensibility
- ✅ Standardized CommandResult structure
- ✅ Factory pattern for command creation
- ✅ Dependency injection via ServiceContainer

**Gaps Identified:**

1. **Missing Progress Indicators** - No feedback for long-running operations
2. **No Async Execution Support** - Commands can't run in background
3. **Inconsistent Flag Naming** - Mixed patterns (--output-dir vs --output-dir vs --output)
4. **Limited Error Recovery** - No retry mechanisms or recovery strategies
5. **No Command Execution Context** - Missing execution metadata (start time, duration tracking)
6. **Validation Order** - Stop on first failure, but should collect all validation errors
7. **Missing Cancellation Support** - No way to cancel long-running commands
8. **No Command Hooks/Plugins** - Limited extensibility beyond lifecycle
9. **Result Handling** - Mixed responsibilities (formatting in command_base.dart)
10. **Command Discovery** - Enum-based, but no dynamic plugin system

## Industry Standards Analysis

### Industry Standards (GitHub CLI, AWS CLI, kubectl, Docker CLI)

**Command Structure:**

- ✅ Verb-noun pattern (already follows this)
- ✅ Consistent flag naming conventions
- ✅ Global vs command-specific flags
- ✅ Subcommand grouping

**Execution Patterns:**

- ✅ Middleware/interceptors (Chain of Responsibility)
- ✅ Validation pipelines
- ⚠️ Progress indicators (missing)
- ⚠️ Async execution flags (missing)
- ⚠️ Cancellation support (missing)

**Error Handling:**

- ✅ Structured error codes (partially implemented)
- ✅ Error suggestions/help
- ⚠️ Retry mechanisms (missing)
- ⚠️ Error recovery strategies (missing)

**User Experience:**

- ✅ JSON output for automation (implemented)
- ✅ Help system (via args package)
- ⚠️ Progress bars/spinners (missing)
- ⚠️ Command completion (basic, needs enhancement)

## Implementation Plan

### Phase 1: Enhance Command Execution Context

**1.1 Create Execution Context**

- Add `CommandExecutionContext` to track execution state
- Include start time, duration, progress tracking
- Support cancellation tokens
- Track execution phase (validation, middleware, execution)

**Location:** `core/command/foundation/domain/command_execution_context.dart`

**1.2 Enhance CommandResult**

- Add execution metadata (duration, phase)
- Support partial results (for long-running commands)
- Add progress information
- Support cancellation status

### Phase 2: Standardize Flag Naming

**2.1 Create Flag Naming Standards**

- Define consistent patterns:
- `--input-file`, `--input-dir` for inputs
- `--output-file`, `--output-dir` for outputs
- `--format` for output format (instead of --output)
- Global flags: `--verbose`, `--quiet`, `--debug`, `--format`
- Document naming conventions

**2.2 Refactor Existing Flags**

- Update commands to use standard flags
- Maintain backward compatibility during transition
- Add deprecation warnings for old flags

### Phase 3: Progress Indicators

**3.1 Create Progress Indicator System**

- Abstract `ProgressIndicator` interface
- Implementations: `SpinnerProgressIndicator`, `BarProgressIndicator`, `SilentProgressIndicator`
- Integrate with CommandExecutionContext
- Support for nested operations

**Location:** `core/progress/domain/progress_indicator.dart`
**Location:** `core/progress/infrastructure/`

**3.2 Add Progress Middleware**

- Optional middleware for commands that need progress
- Integrate with metrics collection
- Support async progress updates

### Phase 4: Async Execution Support

**4.1 Add Async Execution**

- Add `--async` flag support
- Command result tracking for async operations
- Background job system (optional, for future)
- Status checking for async commands

**4.2 Cancellation Support**

- Add `CancellationToken` to CommandExecutionContext
- Support Ctrl+C handling
- Graceful cleanup on cancellation
- Middleware for cancellation propagation

### Phase 5: Enhanced Validation

**5.1 Collect All Validation Errors**

- Change validation to collect all errors (not stop on first)
- Group validation errors by category
- Better error reporting with context

**5.2 Add Validation Middleware**

- Move validation into middleware for consistency
- Support conditional validation
- Integration with CommandExecutionContext

### Phase 6: Error Recovery & Retry

**6.1 Retry Middleware**

- Configurable retry strategies
- Exponential backoff
- Retry conditions (network errors, timeouts)
- Retry metrics collection

**Location:** `core/middleware/infrastructure/optional/retry_middleware.dart`

**6.2 Error Recovery Strategies**

- Define recovery strategies per error type
- Automatic recovery for transient errors
- User-prompted recovery for critical errors

### Phase 7: Command Result Handling Refactoring

**7.1 Extract Result Formatter**

- Separate result formatting from command_base.dart
- Create `CommandResultFormatter` interface
- Implementations: `HumanFormatter`, `JsonFormatter`, `AiFormatter`
- Support streaming results for long operations

**Location:** `core/command/foundation/infrastructure/formatters/`

**7.2 Result Streaming**

- Support partial result output
- Stream progress updates
- Real-time feedback for users

### Phase 8: Command Discovery Enhancement

**8.1 Plugin System (Optional)**

- Define plugin interface for dynamic commands
- Command registry with plugin support
- Lazy loading for performance

**8.2 Command Completion**

- Enhance tab completion
- Auto-complete for flags and values
- Context-aware suggestions

### Phase 9: Testing & Documentation

**9.1 Update Tests**

- Test new execution context
- Test progress indicators
- Test async execution
- Test cancellation

**9.2 Update Documentation**

- Document new flags
- Document execution flow
- Document best practices
- Update architecture docs

## Priority Implementation Order

**High Priority (Phase 1-3):**

1. CommandExecutionContext - Foundation for all enhancements
2. Standardize flags - Improve consistency
3. Progress indicators - Major UX improvement

**Medium Priority (Phase 4-6):**

4. Async execution - Useful for long operations
5. Enhanced validation - Better error messages
6. Error recovery - Improve resilience

**Low Priority (Phase 7-9):**

7. Result handling refactoring - Code quality
8. Command discovery enhancement - Future extensibility
9. Testing & documentation - Maintenance

## Files to Create/Modify

**New Files:**

- `core/command/foundation/domain/command_execution_context.dart`
- `core/progress/domain/progress_indicator.dart`
- `core/progress/infrastructure/spinner_progress_indicator.dart`
- `core/progress/infrastructure/bar_progress_indicator.dart`
- `core/middleware/infrastructure/optional/retry_middleware.dart`
- `core/command/foundation/infrastructure/formatters/command_result_formatter.dart`
- `core/command/foundation/infrastructure/formatters/human_formatter.dart`
- `core/command/foundation/infrastructure/formatters/json_formatter.dart`
- `core/command/foundation/infrastructure/formatters/ai_formatter.dart`

**Modify Files:**

- `command_runner.dart` - Add async support, cancellation
- `command_base.dart` - Use ExecutionContext, progress indicators
- `command_result.dart` - Add execution metadata, progress
- `command_context.dart` - Add cancellation token
- All command files - Standardize flags, add progress

## Benefits

- **Consistency**: Standardized flags and patterns
- **User Experience**: Progress indicators, better feedback
- **Reliability**: Retry mechanisms, error recovery
- **Maintainability**: Clear separation of concerns
- **Extensibility**: Plugin system foundation
- **Industry Alignment**: Matches GitHub CLI, AWS CLI patterns

### To-dos

- [ ] Remove performance_optimizer import and usage from command_runner.dart
- [ ] Add service preloading to ServiceContainer if needed, or remove preloading entirely
- [ ] Update test/examples_test.dart to remove reference to performance_optimizer.dart
- [ ] Delete performance_optimizer.dart file
- [ ] Verify no other files reference performance_optimizer.dart