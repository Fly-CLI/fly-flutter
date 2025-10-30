/// MCP (Model Context Protocol) feature for Fly CLI
library mcp;

// Application layer exports
export 'mcp_doctor_command.dart';
export 'mcp_serve_command.dart';

// Domain layer exports
export 'mcp_tool_strategy.dart';
export 'mcp_tool_strategy_registry.dart';
export 'mcp_tool_type.dart';
export 'tools/flutter_build_strategy.dart';
export 'tools/flutter_create_strategy.dart';
export 'tools/flutter_doctor_strategy.dart';
export 'tools/flutter_run_strategy.dart';
export 'tools/fly_echo_strategy.dart';
export 'tools/fly_template_apply_strategy.dart';
export 'tools/types/fly_template_list_strategy.dart';

