import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'fly_command.dart';

/// Export CLI schema for AI integration
class SchemaCommand extends FlyCommand {
  @override
  String get name => 'schema';

  @override
  String get description => 'Export CLI schema and command specifications';

  @override
  ArgParser get argParser {
    final parser = super.argParser;
    parser
      ..addOption(
        'file',
        abbr: 'o',
        help: 'Output file path (default: stdout)',
      )
      ..addFlag(
        'include-examples',
        help: 'Include example commands and responses',
        negatable: false,
      );
    return parser;
  }

  @override
  Future<CommandResult> execute() async {
    final outputPath = argResults?['file'] as String?;
    final includeExamples = argResults?['include-examples'] as bool? ?? false;

    if (planMode) {
      return _createPlan(outputPath, includeExamples);
    }

    try {
      final schema = _generateSchema(includeExamples);
      final jsonSchema = json.encode(schema);

      if (outputPath != null) {
        // Write to file
        final file = File(outputPath);
        await file.writeAsString(jsonSchema);
        logger.info('✅ Schema exported to $outputPath');
        
        return CommandResult.success(
          command: 'schema',
          message: 'Schema exported successfully',
          data: {
            'output_file': outputPath,
            'schema_size_bytes': jsonSchema.length,
            'includes_examples': includeExamples,
          },
        );
      } else {
        // Output to stdout
        stdout.writeln(jsonSchema);
        
        return CommandResult.success(
          command: 'schema',
          message: 'Schema exported to stdout',
          data: {
            'schema_size_bytes': jsonSchema.length,
            'includes_examples': includeExamples,
          },
        );
      }
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to export schema: $e',
        suggestion: 'Check file permissions and try again',
      );
    }
  }

  CommandResult _createPlan(String? outputPath, bool includeExamples) {
    return CommandResult.success(
      command: 'schema',
      message: 'Schema export plan',
      data: {
        'output_destination': outputPath ?? 'stdout',
        'includes_examples': includeExamples,
        'estimated_size_bytes': includeExamples ? 5000 : 2000,
      },
    );
  }

  Map<String, dynamic> _generateSchema(bool includeExamples) {
    return {
      'cli_info': {
        'name': 'fly',
        'version': '0.1.0',
        'description': 'AI-native Flutter CLI tool',
        'homepage': 'https://github.com/fly-cli/fly',
      },
      'commands': <String, dynamic>{
        'create': {
          'description': 'Create a new Flutter project',
          'usage': 'fly create <project_name> [options]',
          'options': {
            'template': {
              'type': 'string',
              'description': 'Project template to use',
              'allowed': ['minimal', 'riverpod'],
              'default': 'riverpod',
            },
            'organization': {
              'type': 'string',
              'description': 'Organization identifier',
              'default': 'com.example',
            },
            'platforms': {
              'type': 'array',
              'description': 'Target platforms',
              'allowed': ['ios', 'android', 'web', 'macos', 'windows', 'linux'],
              'default': ['ios', 'android'],
            },
            'interactive': {
              'type': 'boolean',
              'description': 'Run in interactive mode',
              'default': false,
            },
            'from-manifest': {
              'type': 'string',
              'description': 'Create project from manifest file',
            },
          },
          'ai_flags': {
            'output': {
              'type': 'string',
              'description': 'Output format for AI integration',
              'allowed': ['human', 'json'],
              'default': 'human',
            },
            'plan': {
              'type': 'boolean',
              'description': 'Show execution plan without running',
              'default': false,
            },
          },
        },
        'doctor': {
          'description': 'Check system setup and diagnose issues',
          'usage': 'fly doctor [options]',
          'options': {
            'fix': {
              'type': 'boolean',
              'description': 'Attempt to fix common issues',
              'default': false,
            },
          },
          'ai_flags': {
            'output': {
              'type': 'string',
              'description': 'Output format for AI integration',
              'allowed': ['human', 'json'],
              'default': 'human',
            },
            'plan': {
              'type': 'boolean',
              'description': 'Show execution plan without running',
              'default': false,
            },
          },
        },
        'schema': {
          'description': 'Export CLI schema and command specifications',
          'usage': 'fly schema [options]',
          'options': {
            'output': {
              'type': 'string',
              'description': 'Output file path (default: stdout)',
            },
            'include-examples': {
              'type': 'boolean',
              'description': 'Include example commands and responses',
              'default': false,
            },
          },
        },
        'version': {
          'description': 'Show version information',
          'usage': 'fly version',
          'options': {},
        },
      },
      'templates': <String, dynamic>{
        'minimal': {
          'description': 'Bare-bones Flutter structure',
          'features': ['basic_structure', 'minimal_dependencies'],
          'estimated_files': 8,
        },
        'riverpod': {
          'description': 'Production-ready Riverpod architecture',
          'features': ['state_management', 'routing', 'error_handling', 'theming'],
          'estimated_files': 25,
          'dependencies': ['fly_core', 'fly_networking', 'fly_state', 'riverpod'],
        },
      },
      'manifest_format': {
        'description': 'Declarative project specification format',
        'file_extension': '.yaml',
        'schema': {
          'name': {
            'type': 'string',
            'required': true,
            'description': 'Project name',
          },
          'template': {
            'type': 'string',
            'required': true,
            'description': 'Template to use',
            'allowed': ['minimal', 'riverpod'],
          },
          'organization': {
            'type': 'string',
            'description': 'Organization identifier',
            'default': 'com.example',
          },
          'platforms': {
            'type': 'array',
            'description': 'Target platforms',
            'default': ['ios', 'android'],
          },
          'screens': {
            'type': 'array',
            'description': 'Screens to generate',
            'items': {
              'name': {'type': 'string', 'required': true},
              'type': {'type': 'string', 'allowed': ['auth', 'list', 'detail', 'form']},
            },
          },
          'services': {
            'type': 'array',
            'description': 'Services to generate',
            'items': {
              'name': {'type': 'string', 'required': true},
              'api_base': {'type': 'string'},
            },
          },
        },
      },
      'response_format': {
        'description': 'Standard JSON response format for all commands',
        'schema': {
          'success': {'type': 'boolean', 'required': true},
          'command': {'type': 'string', 'required': true},
          'message': {'type': 'string', 'required': true},
          'data': {'type': 'object'},
          'next_steps': {
            'type': 'array',
            'items': {
              'command': {'type': 'string'},
              'description': {'type': 'string'},
            },
          },
          'suggestion': {'type': 'string'},
          'metadata': {
            'type': 'object',
            'properties': {
              'cli_version': {'type': 'string'},
              'timestamp': {'type': 'string'},
            },
          },
        },
      },
      if (includeExamples) ..._getExamples(),
    };
  }

  Map<String, dynamic> _getExamples() {
    return {
      'examples': {
        'create_minimal_project': {
          'command': 'fly create my_app --template=minimal --output=json',
          'response': {
            'success': true,
            'command': 'create',
            'message': 'Project "my_app" created successfully',
            'data': {
              'project_name': 'my_app',
              'template': 'minimal',
              'organization': 'com.example',
              'platforms': ['ios', 'android'],
              'files_created': 8,
              'duration_ms': 15000,
            },
            'next_steps': [
              {'command': 'cd my_app', 'description': 'Navigate to project directory'},
              {'command': 'flutter run', 'description': 'Run the application'},
            ],
            'metadata': {
              'cli_version': '0.1.0',
              'timestamp': '2025-01-15T10:30:00Z',
            },
          },
        },
        'create_from_manifest': {
          'command': 'fly create --from-manifest=project.yaml --output=json',
          'manifest_content': {
            'name': 'my_app',
            'template': 'riverpod',
            'organization': 'com.mycompany',
            'platforms': ['ios', 'android', 'web'],
            'screens': [
              {'name': 'login', 'type': 'auth'},
              {'name': 'home', 'type': 'list'},
            ],
            'services': [
              {'name': 'auth_service', 'api_base': 'https://api.mycompany.com'},
            ],
          },
        },
        'doctor_check': {
          'command': 'fly doctor --output=json',
          'response': {
            'success': true,
            'command': 'doctor',
            'message': 'All system checks passed',
            'data': {
              'total_checks': 5,
              'healthy_checks': 5,
              'issues_found': 0,
            },
            'metadata': {
              'cli_version': '0.1.0',
              'timestamp': '2025-01-15T10:30:00Z',
            },
          },
        },
      },
    };
  }
}
