import 'dart:io';

import 'package:fly_mcp_server/src/config/server_config.dart';
import 'package:fly_mcp_server/src/domain/resource_strategy_registry.dart';
import 'package:fly_mcp_server/src/domain/resource_type.dart';
import 'package:fly_mcp_server/src/domain/strategies/resource/logs_build_resource_strategy.dart';
import 'package:fly_mcp_server/src/domain/strategies/resource/logs_run_resource_strategy.dart';
import 'package:fly_mcp_server/src/domain/strategies/resource/workspace_resource_strategy.dart';
import 'package:fly_mcp_server/src/log_resource_provider.dart';
import 'package:fly_mcp_server/src/path_sandbox.dart';
import 'package:fly_mcp_server/src/registries/registry.dart';

/// Registry for MCP resources
class ResourceRegistry implements IResourceRegistry {
  ResourceRegistry({
    LogResourceProvider? logProvider,
    SecurityConfig? securityConfig,
    String? workspaceRoot,
  })  : _logs = logProvider ?? LogResourceProvider(),
        _securityConfig = securityConfig,
        _workspaceRoot = workspaceRoot ?? Directory.current.path;

  final LogResourceProvider _logs;
  final SecurityConfig? _securityConfig;
  final String _workspaceRoot;
  bool _strategiesInitialized = false;

  /// Initialize resource strategies with dependencies
  void _initializeStrategies() {
    if (_strategiesInitialized) return;

    // Get strategy instances from registry and inject dependencies
    final runStrategy =
        resourceStrategyRegistry.getStrategy(ResourceType.logsRun)
            as LogsRunResourceStrategy;
    runStrategy.setLogProvider(_logs);

    final buildStrategy =
        resourceStrategyRegistry.getStrategy(ResourceType.logsBuild)
            as LogsBuildResourceStrategy;
    buildStrategy.setLogProvider(_logs);

    // Initialize workspace strategy with path sandbox
    final workspaceStrategy =
        resourceStrategyRegistry.getStrategy(ResourceType.workspace)
            as WorkspaceResourceStrategy;
    
    // Create path sandbox with security config (always required)
    final pathSandbox = PathSandbox(
      workspaceRoot: _workspaceRoot,
      securityConfig: _securityConfig,
    );
    workspaceStrategy.setPathSandbox(pathSandbox);

    _strategiesInitialized = true;
  }

  @override
  Map<String, Object?> list(Map<String, Object?> params) {
    _initializeStrategies();

    final uriPrefix = params['uri'] as String?;

    // Determine resource type from URI prefix
    if (uriPrefix != null) {
      if (uriPrefix.startsWith('logs://run/')) {
        return ResourceType.logsRun.strategy.list(params);
      } else if (uriPrefix.startsWith('logs://build/')) {
        return ResourceType.logsBuild.strategy.list(params);
      }
    }

    // Default to workspace
    return ResourceType.workspace.strategy.list(params);
  }

  @override
  Map<String, Object?> read(Map<String, Object?> params) {
    _initializeStrategies();

    final uri = params['uri'] as String?;
    if (uri == null) {
      throw StateError('Missing required parameter: uri');
    }

    // Determine resource type from URI
    if (uri.startsWith('logs://run/')) {
      return ResourceType.logsRun.strategy.read(params);
    } else if (uri.startsWith('logs://build/')) {
      return ResourceType.logsBuild.strategy.read(params);
    } else if (uri.startsWith('workspace://')) {
      return ResourceType.workspace.strategy.read(params);
    }

    throw StateError('Invalid or unsupported resource URI: $uri');
  }

  /// Get log provider for storing logs (used by tools)
  LogResourceProvider get logProvider => _logs;
}

