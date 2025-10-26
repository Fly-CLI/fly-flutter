import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';
import 'package:fly_cli/src/core/plugins/domain/plugin_interface.dart';
import 'package:path/path.dart' as path;

/// Registry for managing plugins
class PluginRegistry {
  PluginRegistry();

  final Map<String, FlyPlugin> _plugins = {};
  final Map<String, PluginConfig> _configs = {};
  bool _initialized = false;

  /// Initialize the plugin registry
  Future<void> initialize() async {
    if (_initialized) return;

    await _loadPluginConfigs();
    await _discoverPlugins();
    await _resolveDependencies();
    await _initializePlugins();

    _initialized = true;
  }

  /// Load plugin configurations
  Future<void> _loadPluginConfigs() async {
    final configFile = File(_getPluginConfigPath());
    if (!configFile.existsSync()) return;

    try {
      final content = await configFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final plugins = json['plugins'] as List<dynamic>? ?? [];

      for (final pluginJson in plugins) {
        final config = PluginConfig.fromJson(pluginJson as Map<String, dynamic>);
        _configs[config.name] = config;
      }
    } catch (e) {
      // Log error but continue
      print('Warning: Failed to load plugin config: $e');
    }
  }

  /// Discover available plugins
  Future<void> _discoverPlugins() async {
    final pluginDirs = [
      _getUserPluginDirectory(),
      _getSystemPluginDirectory(),
    ];

    for (final dir in pluginDirs) {
      await _scanDirectoryForPlugins(dir);
    }
  }

  /// Scan directory for plugins
  Future<void> _scanDirectoryForPlugins(String directory) async {
    final dir = Directory(directory);
    if (!dir.existsSync()) return;

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        await _loadPluginFromDirectory(entity.path);
      }
    }
  }

  /// Load plugin from directory
  Future<void> _loadPluginFromDirectory(String pluginPath) async {
    try {
      final pubspecFile = File(path.join(pluginPath, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) return;

      // Read plugin metadata from pubspec.yaml
      final content = await pubspecFile.readAsString();
      final lines = content.split('\n');
      
      String? name;
      String? version;
      
      for (final line in lines) {
        if (line.startsWith('name:')) {
          name = line.split(':')[1].trim();
        } else if (line.startsWith('version:')) {
          version = line.split(':')[1].trim();
        }
      }

      if (name == null || version == null) return;

      // Check if plugin is enabled
      final config = _configs[name];
      if (config != null && !config.enabled) return;

      // Load the plugin class (simplified - in production, use proper reflection)
      final plugin = await _instantiatePlugin(pluginPath, name, version);
      if (plugin != null) {
        _plugins[name] = plugin;
      }
    } catch (e) {
      // Log error but continue
      print('Warning: Failed to load plugin from $pluginPath: $e');
    }
  }

  /// Instantiate plugin (simplified implementation)
  Future<FlyPlugin?> _instantiatePlugin(String pluginPath, String name, String version) async {
    // This is a simplified implementation
    // In production, you would use reflection or dynamic loading
    // For now, we'll return null to indicate this needs proper implementation
    return null;
  }

  /// Resolve plugin dependencies
  Future<void> _resolveDependencies() async {
    final resolved = <String>{};
    final resolving = <String>{};

    for (final plugin in _plugins.values) {
      await _resolvePluginDependencies(plugin, resolved, resolving);
    }
  }

  /// Resolve dependencies for a single plugin
  Future<void> _resolvePluginDependencies(
    FlyPlugin plugin,
    Set<String> resolved,
    Set<String> resolving,
  ) async {
    if (resolved.contains(plugin.name)) return;
    if (resolving.contains(plugin.name)) {
      throw Exception('Circular dependency detected for plugin ${plugin.name}');
    }

    resolving.add(plugin.name);

    for (final dependency in plugin.dependencies) {
      if (!_plugins.containsKey(dependency)) {
        throw Exception('Plugin ${plugin.name} depends on missing plugin $dependency');
      }
      await _resolvePluginDependencies(_plugins[dependency]!, resolved, resolving);
    }

    resolving.remove(plugin.name);
    resolved.add(plugin.name);
  }

  /// Initialize all plugins
  Future<void> _initializePlugins() async {
    final context = PluginContext(
      serviceContainer: null, // Would be injected in real implementation
      config: {},
      environment: Platform.environment,
    );

    for (final plugin in _plugins.values) {
      try {
        await plugin.initialize(context);
      } catch (e) {
        print('Warning: Failed to initialize plugin ${plugin.name}: $e');
      }
    }
  }

  /// Get all registered plugins
  Map<String, FlyPlugin> get plugins => Map.unmodifiable(_plugins);

  /// Get plugin by name
  FlyPlugin? getPlugin(String name) => _plugins[name];

  /// Check if plugin is registered
  bool hasPlugin(String name) => _plugins.containsKey(name);

  /// Get all commands from plugins
  List<Command<int>> getAllPluginCommands() {
    final commands = <Command<int>>[];
    for (final plugin in _plugins.values) {
      commands.addAll(plugin.registerCommands());
    }
    return commands;
  }

  /// Get all middleware from plugins
  List<CommandMiddleware> getAllPluginMiddleware() {
    final middleware = <CommandMiddleware>[];
    for (final plugin in _plugins.values) {
      middleware.addAll(plugin.registerMiddleware());
    }
    return middleware;
  }

  /// Dispose all plugins
  Future<void> dispose() async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.dispose();
      } catch (e) {
        print('Warning: Error disposing plugin ${plugin.name}: $e');
      }
    }
    _plugins.clear();
    _configs.clear();
    _initialized = false;
  }

  /// Get user plugin directory
  String _getUserPluginDirectory() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    return path.join(home, '.fly', 'plugins');
  }

  /// Get system plugin directory
  String _getSystemPluginDirectory() => path.join(Directory.current.path, 'plugins');

  /// Get plugin config path
  String _getPluginConfigPath() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    return path.join(home, '.fly', 'plugin_config.json');
  }
}
