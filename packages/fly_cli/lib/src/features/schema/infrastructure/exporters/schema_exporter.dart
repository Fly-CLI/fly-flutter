import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/features/schema/domain/export_format.dart';

/// Configuration for schema export
class ExportConfig {
  const ExportConfig({
    this.format = ExportFormat.jsonSchema,
    this.commandFilter,
    this.includeExamples = true,
    this.includeValidation = true,
    this.includeGlobalOptions = true,
    this.prettyPrint = true,
  });

  /// The export format to use
  final ExportFormat format;

  /// Optional command name filter (export only this command)
  final String? commandFilter;

  /// Whether to include command examples
  final bool includeExamples;

  /// Whether to include validation rules
  final bool includeValidation;

  /// Whether to include global options
  final bool includeGlobalOptions;

  /// Whether to pretty print the output
  final bool prettyPrint;

  /// Create a copy with modified fields
  ExportConfig copyWith({
    ExportFormat? format,
    String? commandFilter,
    bool? includeExamples,
    bool? includeValidation,
    bool? includeGlobalOptions,
    bool? prettyPrint,
  }) => ExportConfig(
      format: format ?? this.format,
      commandFilter: commandFilter ?? this.commandFilter,
      includeExamples: includeExamples ?? this.includeExamples,
      includeValidation: includeValidation ?? this.includeValidation,
      includeGlobalOptions: includeGlobalOptions ?? this.includeGlobalOptions,
      prettyPrint: prettyPrint ?? this.prettyPrint,
    );
}

/// Abstract base class for schema exporters
abstract class SchemaExporter {
  /// The format this exporter handles
  ExportFormat get format;

  /// Export metadata to the specified format
  String export(CommandMetadataRegistry registry, ExportConfig config);

  /// Export a single command to the specified format
  String exportCommand(CommandDefinition command, ExportConfig config);

  /// Get the content type for the exported format
  String get contentType;
}

/// Schema export utilities
class SchemaExportUtils {
  /// Filter commands based on configuration
  static Map<String, CommandDefinition> filterCommands(
    CommandMetadataRegistry registry,
    ExportConfig config,
  ) {
    final allCommands = registry.getAllCommands();
    
    if (config.commandFilter != null) {
      final filteredCommand = allCommands[config.commandFilter!];
      if (filteredCommand != null) {
        return {config.commandFilter!: filteredCommand};
      }
      return {};
    }
    
    return allCommands;
  }

  /// Get global options if enabled in config
  static List<OptionDefinition> getGlobalOptions(
    CommandMetadataRegistry registry,
    ExportConfig config,
  ) {
    if (!config.includeGlobalOptions) {
      return [];
    }
    return registry.getGlobalOptions();
  }

  /// Format JSON with proper indentation
  static String formatJson(Map<String, dynamic> json, {bool prettyPrint = true}) {
    if (!prettyPrint) {
      return json.toString();
    }
    
    // Simple JSON formatting - in a real implementation, you'd use dart:convert
    final buffer = StringBuffer();
    _formatJsonValue(json, buffer, 0);
    return buffer.toString();
  }

  static void _formatJsonValue(value, StringBuffer buffer, int indent) {
    if (value is Map<String, dynamic>) {
      buffer.writeln('{');
      final entries = value.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer.write('  ' * (indent + 1));
        buffer.write('"${entry.key}": ');
        _formatJsonValue(entry.value, buffer, indent + 1);
        if (i < entries.length - 1) {
          buffer.write(',');
        }
        buffer.writeln();
      }
      buffer.write('  ' * indent);
      buffer.write('}');
    } else if (value is List) {
      buffer.writeln('[');
      for (var i = 0; i < value.length; i++) {
        buffer.write('  ' * (indent + 1));
        _formatJsonValue(value[i], buffer, indent + 1);
        if (i < value.length - 1) {
          buffer.write(',');
        }
        buffer.writeln();
      }
      buffer.write('  ' * indent);
      buffer.write(']');
    } else if (value is String) {
      buffer.write('"$value"');
    } else {
      buffer.write(value.toString());
    }
  }
}
