import 'package:fly_cli/src/features/schema/domain/command_definition.dart';
import 'package:fly_cli/src/features/schema/domain/command_registry.dart';
import 'package:fly_cli/src/features/schema/domain/export_format.dart';
import 'schema_exporter.dart';

/// OpenAPI 3.0 inspired exporter
class OpenApiExporter extends SchemaExporter {
  OpenApiExporter();

  @override
  ExportFormat get format => ExportFormat.openApi;

  @override
  String get contentType => 'application/vnd.oai.openapi';

  @override
  String export(CommandMetadataRegistry registry, ExportConfig config) {
    final commands = SchemaExportUtils.filterCommands(registry, config);
    final globalOptions = SchemaExportUtils.getGlobalOptions(registry, config);

    final openApi = <String, dynamic>{
      'openapi': '3.0.0',
      'info': {
        'title': 'Fly CLI API',
        'description': 'Command-line interface for Flutter development',
        'version': '1.0.0',
        'contact': {
          'name': 'Fly CLI',
          'url': 'https://fly-cli.dev',
        },
      },
      'servers': [
        {
          'url': 'cli://fly',
          'description': 'Fly CLI Commands',
        }
      ],
      'paths': <String, dynamic>{},
      'components': {
        'parameters': <String, dynamic>{},
        'schemas': <String, dynamic>{},
      },
    };

    // Add global options as reusable parameters
    if (globalOptions.isNotEmpty) {
      for (final option in globalOptions) {
        openApi['components']['parameters']['Global${option.name}'] = 
            _buildParameterSchema(option, true);
      }
    }

    // Add each command as a path operation
    for (final entry in commands.entries) {
      final commandName = entry.key;
      final command = entry.value;
      
      openApi['paths']['/$commandName'] = _buildCommandPath(command, config);
    }

    return _formatYaml(openApi, config.prettyPrint);
  }

  @override
  String exportCommand(CommandDefinition command, ExportConfig config) {
    final openApi = <String, dynamic>{
      'openapi': '3.0.0',
      'info': {
        'title': 'Fly CLI - ${command.name}',
        'description': command.description,
        'version': '1.0.0',
      },
      'paths': {
        '/${command.name}': _buildCommandPath(command, config),
      },
    };

    return _formatYaml(openApi, config.prettyPrint);
  }

  /// Build OpenAPI path for a command
  Map<String, dynamic> _buildCommandPath(CommandDefinition command, ExportConfig config) => {
      'post': {
        'summary': command.description,
        'description': command.description,
        'operationId': command.name,
        'parameters': _buildParameters(command, config),
        'requestBody': _buildRequestBody(command),
        'responses': {
          '200': {
            'description': 'Command executed successfully',
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'success': {'type': 'boolean'},
                    'message': {'type': 'string'},
                    'data': {'type': 'object'},
                  },
                },
              },
            },
          },
          '400': {
            'description': 'Invalid command arguments',
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'error': {'type': 'string'},
                    'details': {'type': 'string'},
                  },
                },
              },
            },
          },
        },
      },
    };

  /// Build parameters for a command
  List<Map<String, dynamic>> _buildParameters(CommandDefinition command, ExportConfig config) {
    final parameters = <Map<String, dynamic>>[];

    // Add command-specific options
    for (final option in command.options) {
      parameters.add(_buildParameterSchema(option, false));
    }

    // Add global options if enabled
    if (config.includeGlobalOptions) {
      // Reference global parameters
      for (final option in command.globalOptions) {
        parameters.add({
          r'$ref': '#/components/parameters/Global${option.name}',
        });
      }
    }

    return parameters;
  }

  /// Build parameter schema for an option
  Map<String, dynamic> _buildParameterSchema(OptionDefinition option, bool isGlobal) {
    final schema = <String, dynamic>{
      'name': '--${option.name}',
      'in': 'query',
      'description': option.description,
      'schema': <String, dynamic>{
        'type': _getOpenApiType(option.type),
      },
    };

    if (option.allowedValues != null && option.allowedValues!.isNotEmpty) {
      schema['schema']['enum'] = option.allowedValues;
    }

    if (option.defaultValue != null) {
      schema['schema']['default'] = option.defaultValue.toString();
    }

    if (option.short != null) {
      schema['name'] = '-${option.short}';
      schema['description'] = '${option.description} (short: --${option.name})';
    }

    return schema;
  }

  /// Build request body for command arguments
  Map<String, dynamic>? _buildRequestBody(CommandDefinition command) {
    if (command.arguments.isEmpty) {
      return null;
    }

    final properties = <String, dynamic>{};
    final required = <String>[];

    for (final arg in command.arguments) {
      properties[arg.name] = {
        'type': 'string', // Arguments are always strings
        'description': arg.description,
      };

      if (arg.allowedValues != null && arg.allowedValues!.isNotEmpty) {
        properties[arg.name]['enum'] = arg.allowedValues;
      }

      if (arg.defaultValue != null) {
        properties[arg.name]['default'] = arg.defaultValue;
      }

      if (arg.required) {
        required.add(arg.name);
      }
    }

    return {
      'content': {
        'application/json': {
          'schema': {
            'type': 'object',
            'properties': properties,
            if (required.isNotEmpty) 'required': required,
          },
        },
      },
    };
  }

  /// Convert OptionType to OpenAPI type
  String _getOpenApiType(OptionType type) {
    switch (type) {
      case OptionType.flag:
        return 'boolean';
      case OptionType.value:
        return 'string';
      case OptionType.multiple:
        return 'array';
    }
  }

  /// Convert ArgumentType to OpenAPI type

  /// Simple YAML formatting (in a real implementation, you'd use a YAML library)
  String _formatYaml(Map<String, dynamic> data, bool prettyPrint) {
    if (!prettyPrint) {
      return data.toString();
    }

    final buffer = StringBuffer();
    _formatYamlValue(data, buffer, 0);
    return buffer.toString();
  }

  void _formatYamlValue(value, StringBuffer buffer, int indent) {
    if (value is Map<String, dynamic>) {
      for (final entry in value.entries) {
        buffer.write('  ' * indent);
        buffer.write('${entry.key}:');
        
        if (entry.value is Map || entry.value is List) {
          buffer.writeln();
          _formatYamlValue(entry.value, buffer, indent + 1);
        } else {
          buffer.writeln(' ${entry.value}');
        }
      }
    } else if (value is List) {
      for (final item in value) {
        buffer.write('  ' * indent);
        buffer.write('- ');
        if (item is Map || item is List) {
          buffer.writeln();
          _formatYamlValue(item, buffer, indent + 1);
        } else {
          buffer.writeln(item.toString());
        }
      }
    } else {
      buffer.write(value.toString());
    }
  }
}
