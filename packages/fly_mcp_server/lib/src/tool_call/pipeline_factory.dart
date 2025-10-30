import 'package:fly_mcp_server/fly_mcp_server.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/concurrency_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/confirmation_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/error_handling_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/execution_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/logging_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/result_conversion_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/setup_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/timeout_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/validation_middleware.dart';

/// Function type for creating a tool call pipeline from context.
///
/// Pipeline factories receive a context with all dependencies and
/// return a configured pipeline with middleware added.
typedef ToolCallPipelineFactory = ToolCallPipeline Function(
  ToolCallPipelineContext context,
);

/// Default pipeline factory that creates the standard middleware pipeline.
///
/// This factory creates the same pipeline that was previously hardcoded
/// in `_configureToolCallPipeline`, preserving backward compatibility.
class DefaultPipelineFactory {
  /// Creates the default pipeline with all standard middleware.
  ///
  /// Middleware order (by priority):
  /// - ValidationMiddleware (10)
  /// - ConfirmationMiddleware (20)
  /// - SetupMiddleware (30)
  /// - ConcurrencyMiddleware (40)
  /// - TimeoutMiddleware (50)
  /// - ExecutionMiddleware (60)
  /// - ResultConversionMiddleware (70)
  /// - LoggingMiddleware (80)
  /// - ErrorHandlingMiddleware (90)
  static ToolCallPipeline create(ToolCallPipelineContext context) {
    final pipeline = ToolCallPipeline();

    // Add middleware in priority order (lower = earlier)
    pipeline
      ..add(
        ValidationMiddleware(
          toolRegistry: context.toolRegistry,
          sizeValidator: context.sizeValidator,
        ),
      )
      ..add(ConfirmationMiddleware())
      ..add(SetupMiddleware(
        server: context.server,
        defaultTimeout: context.defaultTimeout,
        perToolTimeouts: context.perToolTimeouts,
      ))
      ..add(ConcurrencyMiddleware(
        concurrencyLimiter: context.concurrencyLimiter,
      ))
      ..add(TimeoutMiddleware())
      ..add(ExecutionMiddleware(
        toolRegistry: context.toolRegistry,
        sizeValidator: context.sizeValidator,
      ))
      ..add(ResultConversionMiddleware())
      ..add(LoggingMiddleware(logger: context.logger))
      ..add(ErrorHandlingMiddleware(logger: context.logger));

    return pipeline;
  }
}

/// Minimal pipeline factory that creates a basic pipeline with essential middleware only.
///
/// Includes only:
/// - ValidationMiddleware
/// - ExecutionMiddleware
/// - ResultConversionMiddleware
/// - ErrorHandlingMiddleware
///
/// Useful for testing or minimal deployments.
class MinimalPipelineFactory {
  /// Creates a minimal pipeline with essential middleware only.
  static ToolCallPipeline create(ToolCallPipelineContext context) {
    final pipeline = ToolCallPipeline();

    pipeline
      ..add(
        ValidationMiddleware(
          toolRegistry: context.toolRegistry,
          sizeValidator: context.sizeValidator,
        ),
      )
      ..add(ExecutionMiddleware(
        toolRegistry: context.toolRegistry,
        sizeValidator: context.sizeValidator,
      ))
      ..add(ResultConversionMiddleware())
      ..add(ErrorHandlingMiddleware(logger: context.logger));

    return pipeline;
  }
}

/// Helper class for customizing the default pipeline with a fluent API.
///
/// Provides convenient methods for common customization operations like
/// adding middleware before/after specific types, replacing middleware,
/// or removing middleware.
///
/// Example:
/// ```dart
/// final pipeline = CustomPipelineFactory(context)
///     .addAfter<SetupMiddleware>(MyCustomMiddleware())
///     .replace<LoggingMiddleware>(CustomLoggingMiddleware())
///     .build();
/// ```
class CustomPipelineFactory {
  /// Creates a custom pipeline factory starting with the default pipeline.
  CustomPipelineFactory(ToolCallPipelineContext context)
      : _context = context,
        _pipeline = DefaultPipelineFactory.create(context);

  final ToolCallPipelineContext _context;
  final ToolCallPipeline _pipeline;

  /// Finds the Type of the first middleware matching type T.
  ///
  /// Uses subtype checking (is T) to find matching middleware,
  /// then returns its exact runtimeType for exact matching.
  Type? _findTypeForGeneric<T extends ToolCallMiddleware>() {
    return _pipeline.findFirstTypeByPredicate((middleware) => middleware is T);
  }

  /// Adds middleware before the specified type.
  ///
  /// The middleware is inserted before the first middleware of type [T].
  /// If [T] is not found, the middleware is added at the end.
  CustomPipelineFactory addBefore<T extends ToolCallMiddleware>(
    ToolCallMiddleware middleware,
  ) {
    // Find the Type of the first middleware matching T
    final targetType = _findTypeForGeneric<T>();
    
    // If no middleware of type T found, append to end as per documentation.
    if (targetType == null) {
      _pipeline.add(middleware);
      return this;
    }
    
    // Find the first index of type T
    final index = _pipeline.findFirstIndexByType(targetType);
    if (index != null) {
      _pipeline.insertAt(index, middleware);
    } else {
      // Shouldn't happen, but fallback to append
      _pipeline.add(middleware);
    }
    return this;
  }

  /// Adds middleware after the specified type.
  ///
  /// The middleware is inserted after the first middleware of type [T].
  /// If [T] is not found, the middleware is added at the end.
  CustomPipelineFactory addAfter<T extends ToolCallMiddleware>(
    ToolCallMiddleware middleware,
  ) {
    // Find the Type of the first middleware matching T
    final targetType = _findTypeForGeneric<T>();
    
    // If no middleware of type T found, append to end as per documentation.
    if (targetType == null) {
      _pipeline.add(middleware);
      return this;
    }
    
    // Find the first index of type T
    final index = _pipeline.findFirstIndexByType(targetType);
    if (index != null) {
      _pipeline.insertAt(index + 1, middleware);
    } else {
      // Shouldn't happen, but fallback to append
      _pipeline.add(middleware);
    }
    return this;
  }

  /// Replaces middleware of the specified type.
  ///
  /// Removes all middleware of type [T] and adds the new middleware.
  /// If [T] is not found, the middleware is added normally.
  CustomPipelineFactory replace<T extends ToolCallMiddleware>(
    ToolCallMiddleware middleware,
  ) {
    // Find the Type of the first middleware matching T
    final targetType = _findTypeForGeneric<T>();
    
    // Remove all middleware of type T
    if (targetType != null) {
      _pipeline.removeByType(targetType);
    }
    
    // Add the new middleware
    _pipeline.add(middleware);
    return this;
  }

  /// Removes middleware of the specified type.
  ///
  /// Removes all middleware of type [T] from the pipeline.
  /// If [T] is not found, no action is taken.
  CustomPipelineFactory remove<T extends ToolCallMiddleware>() {
    // Find the Type of the first middleware matching T
    final targetType = _findTypeForGeneric<T>();
    
    // Remove all middleware of type T
    if (targetType != null) {
      _pipeline.removeByType(targetType);
    }
    
    return this;
  }

  /// Adds a custom middleware to the pipeline.
  ///
  /// The middleware is added to the pipeline. Use [priority] to control ordering.
  CustomPipelineFactory add(ToolCallMiddleware middleware) {
    _pipeline.add(middleware);
    return this;
  }

  /// Builds and returns the configured pipeline.
  ToolCallPipeline build() => _pipeline;
}

