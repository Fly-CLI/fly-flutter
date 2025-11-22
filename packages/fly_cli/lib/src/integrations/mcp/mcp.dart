/// MCP (Model Context Protocol) feature for Fly CLI
library;

// Error handling exports
export 'errors/mcp_error.dart';
export 'errors/mcp_error_hints.dart';
// Application layer exports
export 'mcp_doctor_command.dart';
export 'mcp_serve_command.dart';
// Domain layer exports
export 'mcp_tool_strategy.dart';
export 'mcp_tool_strategy_registry.dart';
// Prompt exports
export 'prompts/prompt_error.dart';
export 'prompts/prompt_validator.dart';
// Resource exports
export 'resources/resource_error.dart';
export 'tools/fly_completion_strategy.dart';
export 'tools/fly_context_export_strategy.dart';
export 'tools/fly_doctor_strategy.dart';
export 'tools/fly_echo_strategy.dart';
// Tool strategy exports
export 'tools/fly_generate_feature_strategy.dart';
export 'tools/fly_generate_service_strategy.dart';
export 'tools/fly_schema_export_strategy.dart';
export 'tools/fly_template_apply_strategy.dart';
export 'tools/fly_version_strategy.dart';
export 'tools/types/fly_template_list_strategy.dart';
// Utility exports
export 'utils/progress_helpers.dart';
export 'utils/tool_logger.dart';
// Validation exports
export 'validation/structured_schema_validator.dart';
