import 'package:args/command_runner.dart';

import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';

/// Context provided to plugins during initialization
class PluginContext {
  const PluginContext({
    required this.serviceContainer,
    required this.config,
    required this.environment,
  });

  /// Service container for dependency injection
  final dynamic serviceContainer;

  /// Plugin configuration
  final Map<String, dynamic> config;

  /// Environment information
  final Map<String, dynamic> environment;
}

/// Base interface for Fly CLI plugins
abstract class FlyPlugin {
  /// Plugin name
  String get name;

  /// Plugin version
  String get version;

  /// Plugin description
  String get description;

  /// Required dependencies (other plugin names)
  List<String> get dependencies => [];

  /// Plugin author
  String get author => 'Unknown';

  /// Plugin homepage URL
  String get homepage => '';

  /// Initialize the plugin
  Future<void> initialize(PluginContext context);

  /// Register commands provided by this plugin
  List<Command<int>> registerCommands();

  /// Register middleware provided by this plugin
  List<CommandMiddleware> registerMiddleware();

  /// Register validators provided by this plugin
  List<dynamic> registerValidators() => [];

  /// Cleanup resources when plugin is disposed
  Future<void> dispose() async {}

  /// Check if plugin is compatible with current CLI version
  bool isCompatible(String cliVersion) => true;

  /// Get plugin metadata
  Map<String, dynamic> getMetadata() => {
    'name': name,
    'version': version,
    'description': description,
    'dependencies': dependencies,
    'author': author,
    'homepage': homepage,
  };
}

/// Plugin configuration
class PluginConfig {
  const PluginConfig({
    required this.name,
    required this.version,
    this.enabled = true,
    this.config = const {},
    this.dependencies = const [],
  });

  final String name;
  final String version;
  final bool enabled;
  final Map<String, dynamic> config;
  final List<String> dependencies;

  factory PluginConfig.fromJson(Map<String, dynamic> json) {
    return PluginConfig(
      name: json['name'] as String,
      version: json['version'] as String,
      enabled: json['enabled'] as bool? ?? true,
      config: json['config'] as Map<String, dynamic>? ?? {},
      dependencies: (json['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'version': version,
    'enabled': enabled,
    'config': config,
    'dependencies': dependencies,
  };
}
