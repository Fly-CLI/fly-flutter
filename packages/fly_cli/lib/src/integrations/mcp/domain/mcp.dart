/// MCP (Model Context Protocol) feature for Fly CLI
library;

// Application layer exports
export 'package:fly_cli/src/integrations/mcp/application/mcp_doctor_command.dart';
export 'package:fly_cli/src/integrations/mcp/application/mcp_serve_command.dart';
// Domain layer exports
export 'package:fly_cli/src/integrations/mcp/application/mcp_tool_strategy.dart';
export 'package:fly_cli/src/integrations/mcp/application/mcp_tool_strategy_registry.dart';
// Error handling exports
export 'package:fly_cli/src/integrations/mcp/infrastructure/errors/mcp_error.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/errors/mcp_error_hints.dart';
// Prompt exports
export 'package:fly_cli/src/integrations/mcp/infrastructure/prompts/prompt_error.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/prompts/prompt_validator.dart';
// Resource exports
export 'package:fly_cli/src/integrations/mcp/infrastructure/resources/resource_error.dart';
// Tool strategy exports
export 'package:fly_cli/src/integrations/mcp/infrastructure/tools/command_schema_export_strategy.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/tools/diagnostic_echo_strategy.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/tools/generate_flutter_project_strategy.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/tools/generate_screen_strategy.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/tools/generate_service_strategy.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/tools/project_context_export_strategy.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/tools/shell_completion_strategy.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/tools/system_diagnostics_strategy.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/tools/template_apply_strategy.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/template_list_strategy.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/tools/version_info_strategy.dart';
// Utility exports
export 'package:fly_cli/src/integrations/mcp/infrastructure/utils/progress_helpers.dart';
export 'package:fly_cli/src/integrations/mcp/infrastructure/utils/tool_logger.dart';
// Validation exports
export 'package:fly_cli/src/integrations/mcp/infrastructure/validation/structured_schema_validator.dart';
