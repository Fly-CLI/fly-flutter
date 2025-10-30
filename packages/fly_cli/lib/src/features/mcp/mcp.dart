/// MCP (Model Context Protocol) feature for Fly CLI
library mcp;

// Application layer exports
export 'application/mcp_doctor_command.dart';
export 'application/mcp_serve_command.dart';

// Domain layer exports
export 'domain/mcp_tool_strategy.dart';
export 'domain/mcp_tool_strategy_registry.dart';
export 'domain/mcp_tool_type.dart';
export 'domain/strategies/flutter_build_strategy.dart';
export 'domain/strategies/flutter_create_strategy.dart';
export 'domain/strategies/flutter_doctor_strategy.dart';
export 'domain/strategies/flutter_run_strategy.dart';
export 'domain/strategies/fly_echo_strategy.dart';
export 'domain/strategies/fly_template_apply_strategy.dart';
export 'domain/strategies/fly_template_list_strategy.dart';

