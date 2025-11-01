library fly_mcp;

// Re-export dart_mcp for compatibility (hide ValidationError to avoid conflict)
export 'package:dart_mcp/server.dart' hide ValidationError, ValidationErrorType;

// Core exports (from fly_mcp_core)
export 'src/core/json_rpc/connection.dart';
export 'src/core/json_rpc/model.dart';
export 'src/core/json_rpc/stdio_transport.dart';
export 'src/core/mcp/error_codes.dart';
export 'src/core/mcp/schema_validator.dart';
// Note: ValidationError from core/validation is hidden to avoid conflict with server_errors ValidationError
// Use the fully qualified path if you need the core ValidationError: package:fly_mcp/src/core/validation/validation_error.dart
export 'src/core/validation/validation_error.dart'
    hide ValidationError, ValidationErrorType;
// Server exports (from fly_mcp_server)
export 'src/server/cancellation.dart';
export 'src/server/concurrency_limiter.dart';
export 'src/server/config/server_config.dart';
export 'src/server/config/size_limits_config.dart';
export 'src/server/domain/prompt_strategy.dart';
export 'src/server/domain/prompt_strategy_registry_provider.dart';
export 'src/server/domain/prompt_type.dart';
export 'src/server/domain/resource_strategy.dart';
export 'src/server/domain/resource_type.dart';
export 'src/server/errors/error_converter.dart' hide JsonRpcError;
export 'src/server/errors/server_errors.dart';
export 'src/server/log_resource_provider.dart';
export 'src/server/logger.dart';
export 'src/server/path_sandbox.dart';
export 'src/server/progress.dart';
export 'src/server/registries.dart';
export 'src/server/server.dart';
export 'src/server/server_builder.dart';
export 'src/server/timeout_manager.dart';
export 'src/server/tool_call/middleware/concurrency_middleware.dart';
export 'src/server/tool_call/middleware/confirmation_middleware.dart';
export 'src/server/tool_call/middleware/error_handling_middleware.dart';
export 'src/server/tool_call/middleware/execution_middleware.dart';
export 'src/server/tool_call/middleware/logging_middleware.dart';
export 'src/server/tool_call/middleware/result_conversion_middleware.dart';
export 'src/server/tool_call/middleware/setup_middleware.dart';
export 'src/server/tool_call/middleware/timeout_middleware.dart';
export 'src/server/tool_call/middleware/validation_middleware.dart';
export 'src/server/tool_call/pipeline_context.dart';
export 'src/server/tool_call/pipeline_factory.dart';
export 'src/server/tool_call/tool_call_context.dart';
export 'src/server/tool_call/tool_call_middleware.dart';
export 'src/server/tool_call/tool_call_pipeline.dart';
export 'src/server/types/tool_parameter.dart';
export 'src/server/types/tool_result.dart';
export 'src/server/types/type_converter.dart';
export 'src/server/validation/protocol_validator.dart';
export 'src/server/validation/schema_converter.dart';
export 'src/server/validation/size_validator.dart';
