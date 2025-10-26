import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'core/command_foundation/domain/command_context.dart';
import 'core/command_foundation/domain/command_result.dart';
import 'core/command_foundation/infrastructure/command_context_impl.dart';
import 'core/dependency_injection/application/command_factory.dart';
import 'core/dependency_injection/domain/service_container.dart';
import 'core/performance/performance_optimizer.dart';
import 'core/plugins/application/plugin_registry.dart';
import 'core/templates/template_manager.dart';
import 'core/utils/interactive_prompt.dart';
import 'features/completion/application/completion_command.dart';
import 'features/context/application/context_command.dart';
// Import commands
import 'features/create/application/create_command.dart';
import 'features/doctor/application/doctor_command.dart';
import 'features/doctor/domain/system_checker.dart';
import 'features/schema/application/schema_command.dart';
import 'features/screen/application/add_screen_command.dart';
import 'features/service/application/add_service_command.dart';
import 'features/version/application/version_command.dart';

/// Enhanced Fly CLI Command Runner with dependency injection and plugin support
class FlyCommandRunner extends CommandRunner<int> {
  FlyCommandRunner() : super('fly', 'AI-native Flutter CLI tool') {
    _initializeServices();
    _registerGlobalOptions();
    _registerCommands();
    _initializePlugins();
  }

  late final ServiceContainer _services;
  late final CommandFactory _factory;
  late final PluginRegistry _pluginRegistry;
  late final CommandPerformanceOptimizer _optimizer;

  /// Initialize service container and dependencies
  void _initializeServices() {
    _services = ServiceContainer()
      ..registerSingleton<Logger>(Logger())
      ..registerSingleton<TemplateManager>(TemplateManager(
        templatesDirectory: _findTemplatesDirectory(),
        logger: Logger(),
      ))
      ..registerSingleton<SystemChecker>(SystemChecker(logger: Logger()))
      ..registerSingleton<InteractivePrompt>(InteractivePrompt(Logger()))
      ..register<CommandContext>((container) => _createCommandContext());

    _factory = CommandFactory(_services);
    _optimizer = CommandPerformanceOptimizer();
  }

  /// Create command context with current environmentt
  CommandContext _createCommandContext() => CommandContextImpl(
    argResults: ArgParser().parse([]),
    // Will be updated later
    logger: _services.get<Logger>(),
    templateManager: _services.get<TemplateManager>(),
    systemChecker: _services.get<SystemChecker>(),
    interactivePrompt: _services.get<InteractivePrompt>(),
    config: _getConfig(),
    environment: Environment.current(),
    workingDirectory: Directory.current.path,
    verbose: false,
    // Will be set from args
    quiet: false, // Will be set from args
  );

  /// Get configuration from various sources
  Map<String, dynamic> _getConfig() =>
      {
        'cli_version': '0.1.0',
        'templates_directory': _findTemplatesDirectory(),
        'plugins_enabled': true,
      };

  /// Register global options
  void _registerGlobalOptions() {
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose output',
        negatable: false,
      )
      ..addFlag(
        'quiet',
        abbr: 'q',
        help: 'Suppress output',
        negatable: false,
      )
      ..addFlag(
        'version',
        help: 'Show version information',
        negatable: false,
      )
      ..addFlag(
        'plan',
        help: 'Show execution plan without running',
        negatable: false,
      )
      ..addOption(
        'output',
        abbr: 'f',
        allowed: ['human', 'json', 'ai'],
        defaultsTo: 'human',
        help: 'Output format (human, json, or ai)',
      );
  }

  /// Register all commands
  void _registerCommands() {
    // Create command context for command registration
    final context = _createCommandContext();

    // Register commands
    addCommand(CreateCommand(context));
    addCommand(DoctorCommand(context));
    addCommand(SchemaCommand(context));
    addCommand(VersionCommand(context));
    addCommand(ContextCommand(context));
    addCommand(CompletionCommand(context));

    // Add subcommands for 'add' command
    final addCmd = _AddCommand();
    addCmd.addSubcommand(AddScreenCommand(context));
    addCmd.addSubcommand(AddServiceCommand(context));
    addCommand(addCmd);

    // Add semantic aliases for AI integration
    addCommand(_AliasCommand('generate', CreateCommand(context)));
    addCommand(_AliasCommand('scaffold', CreateCommand(context)));
    addCommand(_AliasCommand('new', CreateCommand(context)));
    addCommand(_AliasCommand('init', CreateCommand(context)));
  }

  /// Initialize plugin system
  void _initializePlugins() {
    _pluginRegistry = PluginRegistry();
    // Plugin initialization will be async, so we'll do it in run()
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      // Initialize plugins if not already done
      try {
        await _pluginRegistry.initialize();
        _registerPluginCommands();
      } catch (e) {
        // Plugin initialization failed, continue without plugins
        // logger.detail('Plugin initialization failed: $e');
      }

      // Parse arguments to check for global flags
      final parsedArgs = argParser.parse(args);

      // Handle version flag
      if (parsedArgs['version'] == true) {
        return _handleVersionFlag(parsedArgs['output'] as String? ?? 'human');
      }

      // Update command context with parsed arguments
      _updateCommandContext(parsedArgs);

      // Preload critical services for performance
      await _optimizer.preloadCriticalServices();

      // Run the command
      final result = await super.run(args);
      return result ?? 1;
    } catch (e, stackTrace) {
      final outputFormat = args.contains('--output=json') ? 'json' : 
                          args.contains('--output=ai') ? 'ai' : 'human';
      
      final errorResult = CommandResult.error(
        message: e.toString(),
        suggestion: 'Check your command syntax and try again',
        metadata: {
          'cli_version': '0.1.0',
          'timestamp': DateTime.now().toIso8601String(),
          'verbose': args.contains('--verbose'),
        },
      );

      // Use CommandResult's built-in output handling
      if (outputFormat == 'json') {
        print(json.encode(errorResult.toJson()));
      } else if (outputFormat == 'ai') {
        print(json.encode(errorResult.toAiJson()));
      } else {
        errorResult.displayHuman();
        if (args.contains('--verbose')) {
          print('Stack trace: $stackTrace');
        }
      }
      return errorResult.exitCode;
    }
  }

  /// Handle version flag using CommandResult for consistency
  int _handleVersionFlag(String outputFormat) {
    final versionInfo = {
      'version': '0.1.0',
      'build_number': null,
      'git_commit': '3eaaea7',
      'build_date': DateTime.now().toIso8601String(),
    };

    final result = CommandResult.success(
      command: 'version',
      message: 'Version information retrieved',
      data: versionInfo,
      metadata: {
        'cli_version': '0.1.0',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Use CommandResult's built-in output handling
    if (outputFormat == 'json') {
      print(json.encode(result.toJson()));
    } else if (outputFormat == 'ai') {
      print(json.encode(result.toAiJson()));
    } else {
      result.displayHuman();
    }
    return result.exitCode;
  }

  /// Update command context with parsed arguments
  void _updateCommandContext(ArgResults parsedArgs) {
    // Update context with current argument values
    final config = _getConfig();
    config['args'] = {
      'verbose': parsedArgs['verbose'] as bool? ?? false,
      'quiet': parsedArgs['quiet'] as bool? ?? false,
      'output': parsedArgs['output'] as String? ?? 'human',
      'plan': parsedArgs['plan'] as bool? ?? false,
    };

    // Re-register context with updated config
    _services.register<CommandContext>((container) => CommandContextImpl(
      argResults: parsedArgs,
      logger: _services.get<Logger>(),
      templateManager: _services.get<TemplateManager>(),
      systemChecker: _services.get<SystemChecker>(),
      interactivePrompt: _services.get<InteractivePrompt>(),
      config: config,
      environment: Environment.current(),
      workingDirectory: Directory.current.path,
      verbose: parsedArgs['verbose'] as bool? ?? false,
      quiet: parsedArgs['quiet'] as bool? ?? false,
    ));
  }

  /// Register commands from plugins
  void _registerPluginCommands() {
    final pluginCommands = _pluginRegistry.getAllPluginCommands();
    for (final command in pluginCommands) {
      addCommand(command);
    }
  }

  /// Find templates directory
  String _findTemplatesDirectory() {
    final possiblePaths = [
      'templates',
      '../templates',
      '../../templates',
      Directory.current.path + '/templates',
    ];

    for (final templatePath in possiblePaths) {
      final dir = Directory(templatePath);
      if (dir.existsSync()) {
        return templatePath;
      }
    }

    return 'templates';
  }

  @override
  String get usage => '''
$description

Usage: fly <command> [arguments]

Global options:
${argParser.usage}

Available commands:
${commands.keys.map((name) => '  $name').join('\n')}

Run "fly help <command>" for more information about a command.
''';
}

/// Internal command class for 'add' command
class _AddCommand extends Command<int> {
  _AddCommand() : super();

  @override
  String get name => 'add';

  @override
  String get description => 'Add components to your project';

  @override
  Future<int> run() async {
    // This is handled by subcommands
    return 0;
  }
}

/// Internal command class for aliases
class _AliasCommand extends Command<int> {

  _AliasCommand(String aliasName, this._targetCommand) : _aliasName = aliasName, super();
  final Command _targetCommand;
  final String _aliasName;

  @override
  String get name => _aliasName;

  @override
  String get description => _targetCommand.description;

  @override
  Future<int> run() async {
    final result = await _targetCommand.run();
    return result is int ? result : 1;
  }
}