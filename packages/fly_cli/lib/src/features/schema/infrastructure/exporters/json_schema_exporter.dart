import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/features/schema/domain/export_format.dart';
import 'schema_exporter.dart';

/// JSON Schema Draft 7 exporter
class JsonSchemaExporter extends SchemaExporter {
  JsonSchemaExporter();

  @override
  ExportFormat get format => ExportFormat.jsonSchema;

  @override
  String get contentType => 'application/schema+json';

  @override
  String export(CommandMetadataRegistry registry, ExportConfig config) {
    final commands = SchemaExportUtils.filterCommands(registry, config);
    final globalOptions = SchemaExportUtils.getGlobalOptions(registry, config);

    final schema = <String, dynamic>{
      r'$schema': 'http://json-schema.org/draft-07/schema#',
      r'$id': 'https://fly-cli.dev/schema.json',
      'title': 'Fly CLI Command Schema',
      'description': 'Schema for Fly CLI commands and options',
      'type': 'object',
      'properties': <String, dynamic>{},
      'definitions': <String, dynamic>{},
    };

    // Add global options as a reusable definition
    if (globalOptions.isNotEmpty) {
      schema['definitions']['GlobalOptions'] = _buildOptionsSchema(globalOptions);
    }

    // Add each command as a property
    for (final entry in commands.entries) {
      final commandName = entry.key;
      final command = entry.value;
      
      schema['properties'][commandName] = _buildCommandSchema(command, config);
    }

    return SchemaExportUtils.formatJson(schema, prettyPrint: config.prettyPrint);
  }

  @override
  String exportCommand(CommandDefinition command, ExportConfig config) {
    final schema = _buildCommandSchema(command, config);
    return SchemaExportUtils.formatJson(schema, prettyPrint: config.prettyPrint);
  }

  /// Build JSON Schema for a single command
  Map<String, dynamic> _buildCommandSchema(CommandDefinition command, ExportConfig config) {
    final schema = <String, dynamic>{
      'type': 'object',
      'title': command.name,
      'description': command.description,
      'properties': <String, dynamic>{},
    };

    // Add arguments as required properties
    if (command.arguments.isNotEmpty) {
      final required = <String>[];
      for (final arg in command.arguments) {
        schema['properties'][arg.name] = _buildArgumentSchema(arg);
        if (arg.required) {
          required.add(arg.name);
        }
      }
      if (required.isNotEmpty) {
        schema['required'] = required;
      }
    }

    // Add options as optional properties
    if (command.options.isNotEmpty) {
      final optionsSchema = _buildOptionsSchema(command.options);
      schema['properties'].addAll(optionsSchema['properties'] as Map<String, dynamic>);
    }

    // Add global options reference
    if (config.includeGlobalOptions) {
      schema['allOf'] = [
        {r'$ref': '#/definitions/GlobalOptions'},
      ];
    }

    // Add examples if enabled
    if (config.includeExamples && command.examples.isNotEmpty) {
      schema['examples'] = command.examples.map((e) => {
        'command': e.command,
        'description': e.description,
      },).toList();
    }

    // Add subcommands if present
    if (command.subcommands.isNotEmpty) {
      schema['properties']['subcommand'] = {
        'type': 'string',
        'enum': command.subcommands.map((s) => s.name).toList(),
        'description': 'Available subcommands',
      };
    }

    return schema;
  }

  /// Build JSON Schema for an argument
  Map<String, dynamic> _buildArgumentSchema(ArgumentDefinition arg) {
    final schema = <String, dynamic>{
        'type': 'string', // Arguments are always strings
      'description': arg.description,
    };

    if (arg.allowedValues != null && arg.allowedValues!.isNotEmpty) {
      schema['enum'] = arg.allowedValues;
    }

    if (arg.defaultValue != null) {
      schema['default'] = arg.defaultValue;
    }

    return schema;
  }

  /// Build JSON Schema for options
  Map<String, dynamic> _buildOptionsSchema(List<OptionDefinition> options) {
    final schema = <String, dynamic>{
      'properties': <String, dynamic>{},
    };

    for (final option in options) {
      final optionSchema = <String, dynamic>{
        'type': _getJsonSchemaType(option.type),
        'description': option.description,
      };

      if (option.allowedValues != null && option.allowedValues!.isNotEmpty) {
        optionSchema['enum'] = option.allowedValues;
      }

      if (option.defaultValue != null) {
        optionSchema['default'] = option.defaultValue;
      }

      // Add short option as alternative
      if (option.short != null) {
        optionSchema['aliases'] = ['-${option.short}'];
      }

      schema['properties']['--${option.name}'] = optionSchema;
    }

    return schema;
  }

  /// Convert OptionType to JSON Schema type
  String _getJsonSchemaType(OptionType type) {
    switch (type) {
      case OptionType.flag:
        return 'boolean';
      case OptionType.value:
        return 'string';
      case OptionType.multiple:
        return 'array';
    }
  }

  /// Convert ArgumentType to JSON Schema type
}
