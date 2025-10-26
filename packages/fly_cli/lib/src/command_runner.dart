import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:fly_cli/src/commands/create_command.dart';
import 'package:fly_cli/src/commands/doctor_command.dart';
import 'package:fly_cli/src/commands/schema_command.dart';
import 'package:fly_cli/src/commands/version_command.dart';
import 'package:fly_cli/src/commands/add_screen_command.dart';
import 'package:fly_cli/src/commands/add_service_command.dart';
import 'package:fly_cli/src/commands/context_export_command.dart';

/// Fly CLI Command Runner
/// 
/// Main orchestrator for all Fly CLI commands with AI-native features.
class FlyCommandRunner extends CommandRunner<int> {
  FlyCommandRunner() : super('fly', 'AI-native Flutter CLI tool') {
    // Global options
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
      ..addOption(
        'output',
        abbr: 'f',
        allowed: ['human', 'json'],
        defaultsTo: 'human',
        help: 'Output format (human or json)',
      );

    // Add subcommands for 'add' command
    final addCmd = _AddCommand();
    addCmd.addSubcommand(AddScreenCommand());
    addCmd.addSubcommand(AddServiceCommand());
    
    // Add commands
    addCommand(CreateCommand());
    addCommand(DoctorCommand());
    addCommand(SchemaCommand());
    addCommand(VersionCommand());
    addCommand(ContextExportCommand());
    addCommand(addCmd);
    
    // Add semantic aliases for AI integration
    addCommand(_AliasCommand('generate', CreateCommand()));
    addCommand(_AliasCommand('scaffold', CreateCommand()));
    addCommand(_AliasCommand('new', CreateCommand()));
    addCommand(_AliasCommand('init', CreateCommand()));

    // Set up logger
    _setupLogger();
  }

  void _setupLogger() {
    // Logger setup will be handled in the run method after argResults is available
  }

  @override
  Future<int> run(Iterable<String> args) async {
    // Parse arguments to check for global flags
    try {
      final parsedArgs = argParser.parse(args);
      
      // Handle version flag
      if (parsedArgs['version'] == true) {
        final outputFormat = parsedArgs['output'] as String? ?? 'human';
        final versionCommand = VersionCommand();
        
        // Create a custom argResults that includes the output format
        final customArgs = ['version', '--output=$outputFormat'];
        final customParsedArgs = versionCommand.argParser.parse(customArgs);
        
        // Use reflection or a different approach to set argResults
        // For now, let's create a simple version output
        if (outputFormat == 'json') {
          final versionInfo = {
            'version': '0.1.0',
            'build_number': null,
            'git_commit': '3eaaea7',
            'build_date': DateTime.now().toIso8601String(),
          };
          
          final result = {
            'success': true,
            'command': 'version',
            'message': 'Version information retrieved',
            'data': versionInfo,
            'metadata': {
              'cli_version': '0.1.0',
              'timestamp': DateTime.now().toIso8601String(),
            },
          };
          
          print(json.encode(result));
          exit(0);
        } else {
          // Human-readable output
          print('Fly CLI 0.1.0');
          print('Commit: 3eaaea7');
          print('Built: ${DateTime.now().toIso8601String()}');
          print('✅ Version information displayed');
          exit(0);
        }
      }
    } catch (e) {
      // If parsing fails, continue with normal command processing
    }

    try {
      final result = await super.run(args);
      print('DEBUG: CommandRunner.run() returned: $result');
      exit(result ?? 1);
    } catch (e) {
      if (args.contains('--output=json')) {
        print('{"success":false,"command":"error","message":"$e","metadata":{"cli_version":"0.1.0","timestamp":"${DateTime.now().toIso8601String()}"}}');
      } else {
        print('Error: $e');
      }
      exit(1);
    }
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
  final Command _targetCommand;
  final String _aliasName;
  
  _AliasCommand(String aliasName, this._targetCommand) : _aliasName = aliasName, super();
  
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