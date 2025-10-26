import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:args/args.dart';

import 'package:fly_cli/src/commands/fly_command.dart';

/// Export project context for AI integration
class ContextExportCommand extends FlyCommand {
  @override
  String get name => 'context-export';

  @override
  String get description => 'Export project context for AI integration';

  @override
  ArgParser get argParser {
    final parser = super.argParser
      ..addOption(
        'file',
        abbr: 'o',
        help: 'Output file path (default: stdout)',
      )
      ..addFlag(
        'include-code',
        help: 'Include source code in export',
        negatable: false,
      )
      ..addFlag(
        'include-dependencies',
        help: 'Include dependency information',
        negatable: false,
      );
    return parser;
  }

  @override
  Future<CommandResult> execute() async {
    final outputPath = argResults?['file'] as String?;
    final includeCode = argResults?['include-code'] as bool? ?? false;
    final includeDependencies = argResults?['include-dependencies'] as bool? ?? false;

    if (planMode) {
      return _createPlan(outputPath, includeCode, includeDependencies);
    }

    try {
      logger.info('Exporting project context...');
      
      final context = await _generateContext(includeCode, includeDependencies);
      final jsonContext = json.encode(context);

      if (outputPath != null) {
        // Write to file
        final file = File(outputPath);
        await file.writeAsString(jsonContext);
        logger.info('✅ Context exported to $outputPath');
        
        return CommandResult.success(
          command: 'context-export',
          message: 'Context exported successfully',
          data: {
            'output_file': outputPath,
            'context_size_bytes': jsonContext.length,
            'includes_code': includeCode,
            'includes_dependencies': includeDependencies,
          },
        );
      } else {
        // Output to stdout
        stdout.writeln(jsonContext);
        
        return CommandResult.success(
          command: 'context-export',
          message: 'Context exported to stdout',
          data: {
            'context_size_bytes': jsonContext.length,
            'includes_code': includeCode,
            'includes_dependencies': includeDependencies,
          },
        );
      }
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to export context: $e',
        suggestion: 'Check file permissions and project structure',
      );
    }
  }

  CommandResult _createPlan(String? outputPath, bool includeCode, bool includeDependencies) => CommandResult.success(
      command: 'context-export',
      message: 'Context export plan',
      data: {
        'output_destination': outputPath ?? 'stdout',
        'includes_code': includeCode,
        'includes_dependencies': includeDependencies,
        'estimated_size_bytes': includeCode ? 10000 : 2000,
      },
    );

  Future<Map<String, dynamic>> _generateContext(bool includeCode, bool includeDependencies) async {
    // TODO: Implement actual context generation
    return {
      'project_info': {
        'name': 'flutter_project',
        'type': 'flutter',
        'version': '1.0.0',
      },
      'structure': {
        'lib': ['main.dart', 'app.dart'],
        'test': ['widget_test.dart'],
      },
      if (includeCode) 'code': {
        'main.dart': '// Main entry point',
        'app.dart': '// App configuration',
      },
      if (includeDependencies) 'dependencies': {
        'flutter': 'sdk',
        'cupertino_icons': '^1.0.2',
      },
      'exported_at': DateTime.now().toIso8601String(),
    };
  }
}