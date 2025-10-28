import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_type.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/command_context_impl.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/core/dependency_injection/domain/service_container.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/core/performance/performance_optimizer.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/features/schema/domain/command_registry.dart';
import 'package:mason_logger/mason_logger.dart';

/// Enhanced Fly CLI Command Runner with simplified dependency injection
class FlyCommandRunner extends CommandRunner<int> {
  FlyCommandRunner() : super('fly', 'AI-native Flutter CLI tool') {
    _initializeServices();
    _registerGlobalOptions();
    _registerCommands();
  }

  late final ServiceContainer _services;
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
      ..registerSingleton<InteractivePrompt>(InteractivePrompt(Logger()));

    _optimizer = CommandPerformanceOptimizer();
  }

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

  /// Register all commands using enum-based architecture
  void _registerCommands() {
    // Create a temporary context for command registration
    final tempArgs = ArgParser()
    ..addFlag('verbose', negatable: false)
    ..addFlag('quiet', negatable: false);
    final context = _createContext(tempArgs.parse([]));

    // Register all commands using enum-based iteration
    for (final commandType in FlyCommandType.values) {
      if (commandType.isTopLevel) {
        // Create command instance once
        final commandInstance = commandType.createInstance(context);
        
        // Register top-level commands
        addCommand(commandInstance);
        
        // Register aliases for top-level commands
        for (final alias in commandType.aliases) {
          addCommand(_AliasCommand(alias, commandInstance));
        }
      }
    }

    // Manually create the 'add' command group for screen and service commands
    final addCmd = _GroupCommand('add')
    ..addSubcommand(FlyCommandType.screen.createInstance(context))
    ..addSubcommand(FlyCommandType.service.createInstance(context));
    addCommand(addCmd);

    // Set metadata provider for lazy initialization (metadata extracted only when needed)
    CommandMetadataRegistry.instance.setProvider(
      _CommandRunnerMetadataProvider(this),
    );
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      // Parse arguments to check for global flags
      final parsedArgs = argParser.parse(args);

      // Handle version flag
      if (parsedArgs['version'] == true) {
        return _handleVersionFlag(parsedArgs['output'] as String? ?? 'human');
      }

      // Preload critical services for performance
      await _optimizer.preloadCriticalServices();

      // Run the command
      final result = await super.run(args);
      return result ?? 1;
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, args);
    }
  }

  /// Create a command context with services
  CommandContext _createContext(ArgResults args) {
    return CommandContextImpl(
      argResults: args,
      logger: _services.get<Logger>(),
      templateManager: _services.get<TemplateManager>(),
      systemChecker: _services.get<SystemChecker>(),
      interactivePrompt: _services.get<InteractivePrompt>(),
      config: _getConfig(),
      environment: Environment.current(),
      workingDirectory: Directory.current.path,
      verbose: args['verbose'] as bool? ?? false,
      quiet: args['quiet'] as bool? ?? false,
    );
  }

  /// Get configuration
  Map<String, dynamic> _getConfig() => {
    'cli_version': '0.1.0',
    'templates_directory': _findTemplatesDirectory(),
    'plugins_enabled': true,
  };

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

  /// Handle errors with proper error handling
  int _handleError(Object e, StackTrace stackTrace, Iterable<String> args) {
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

/// Internal command class for grouping subcommands
class _GroupCommand extends Command<int> {
  _GroupCommand(this.groupName) : super();

  final String groupName;

  @override
  String get name => groupName;

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
  
  final Command<int> _targetCommand;
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

/// CommandMetadataProvider implementation for CommandRunner
class _CommandRunnerMetadataProvider implements CommandMetadataProvider {
  _CommandRunnerMetadataProvider(this._runner);

  final CommandRunner<int> _runner;

  @override
  ArgParser getGlobalOptionsParser() => _runner.argParser;

  @override
  Map<String, Command<int>> getCommands() => _runner.commands;
}