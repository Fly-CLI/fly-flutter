import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Simple Mustache-style template engine for prompt templates
/// 
/// Supports:
/// - Variable substitution: {{variable}}
/// - Conditionals: {{#if condition}}...{{/if}} and {{#if condition}}...{{else}}...{{/if}}
/// - Loops: {{#each list}}...{{/each}} with access to {{item}} and {{index}}
/// - Inverse conditionals: {{^condition}}...{{/condition}}
class PromptTemplateEngine {
  /// Renders a template string with the given variables
  /// 
  /// [template] - The template string with Mustache syntax
  /// [variables] - Map of variable names to values
  /// Returns the rendered template string
  static String render(String template, Map<String, dynamic> variables) {
    var result = template;

    // Handle conditionals and loops first
    result = _processSections(result, variables);

    // Handle simple variable substitution
    for (final entry in variables.entries) {
      final placeholder = '{{${entry.key}}}';
      final value = _formatValue(entry.value);
      result = result.replaceAll(placeholder, value);
    }

    return result;
  }

  /// Processes Mustache sections (conditionals, loops)
  static String _processSections(String template, Map<String, dynamic> variables) {
    var result = template;

    // Process each sections
    final sectionPattern = RegExp(
      r'\{\{#(\w+)\}\}(.*?)\{\{/\1\}\}',
      dotAll: true,
    );

    while (sectionPattern.hasMatch(result)) {
      result = result.replaceAllMapped(sectionPattern, (match) {
        final sectionType = match.group(1) as String;
        final sectionContent = match.group(2) as String;
        final fullMatch = match.group(0) as String;

        // Check if it's an inverse section ({{^condition}})
        if (result.contains('{{^$sectionType}}')) {
          return _processInverseSection(
            result,
            sectionType,
            sectionContent,
            variables,
          );
        }

        // Handle each loops
        if (sectionType == 'each') {
          return _processEachLoop(sectionContent, variables);
        }

        // Handle if conditionals
        return _processIfConditional(
          fullMatch,
          sectionType,
          sectionContent,
          variables,
        );
      });
    }

    // Process else blocks in conditionals
    result = _processElseBlocks(result, variables);

    // Process inverse sections ({{^condition}})
    result = _processInverseSections(result, variables);

    return result;
  }

  /// Processes {{#each}} loops
  static String _processEachLoop(String content, Map<String, dynamic> variables) {
    // Find the each block pattern: {{#each listName}}...{{/each}}
    final eachPattern = RegExp(
      r'\{\{#each\s+(\w+)\}\}(.*?)\{\{/each\}\}',
      dotAll: true,
    );

    String result = content;
    
    while (eachPattern.hasMatch(result)) {
      result = result.replaceAllMapped(eachPattern, (match) {
        final listName = match.group(1) as String;
        final loopContent = match.group(2) as String;
        final list = variables[listName] as List?;

        if (list == null || list.isEmpty) {
          return '';
        }

        final buffer = StringBuffer();
        for (int i = 0; i < list.length; i++) {
          final item = list[i];
          var itemContent = loopContent;

          // Replace {{this}} or {{.}} with the item
          itemContent = itemContent.replaceAll('{{this}}', _formatValue(item));
          itemContent = itemContent.replaceAll('{{.}}', _formatValue(item));

          // Replace {{item}} with the item
          itemContent = itemContent.replaceAll('{{item}}', _formatValue(item));

          // Replace {{index}} with the index
          itemContent = itemContent.replaceAll('{{index}}', i.toString());

          // Process nested sections in the loop content
          itemContent = _processSections(itemContent, {
            ...variables,
            'this': item,
            '.': item,
            'item': item,
            'index': i,
          });

          buffer.writeln(itemContent.trim());
        }

        return buffer.toString();
      });
    }

    return result;
  }

  /// Processes {{#if}} conditionals (non-each sections)
  static String _processIfConditional(
    String fullMatch,
    String conditionName,
    String content,
    Map<String, dynamic> variables,
  ) {
    final value = variables[conditionName];
    final shouldRender = _isTruthy(value);

    if (shouldRender) {
      // Process nested sections in the content
      var processed = _processSections(content, variables);
      // Process simple variables in the processed content
      for (final entry in variables.entries) {
        final placeholder = '{{${entry.key}}}';
        final value = _formatValue(entry.value);
        processed = processed.replaceAll(placeholder, value);
      }
      return processed;
    }

    return '';
  }

  /// Processes else blocks in conditionals
  static String _processElseBlocks(String template, Map<String, dynamic> variables) {
    final elsePattern = RegExp(
      r'\{\{#if\s+(\w+)\}\}(.*?)\{\{else\}\}(.*?)\{\{/if\}\}',
      dotAll: true,
    );

    return template.replaceAllMapped(elsePattern, (match) {
      final conditionName = match.group(1) as String;
      final ifContent = match.group(2) as String;
      final elseContent = match.group(3) as String;
      final value = variables[conditionName];
      final shouldRender = _isTruthy(value);

      if (shouldRender) {
        return _processSections(ifContent, variables);
      } else {
        return _processSections(elseContent, variables);
      }
    });
  }

  /// Processes inverse sections ({{^condition}}...{{/condition}})
  static String _processInverseSections(
    String template,
    Map<String, dynamic> variables,
  ) {
    final inversePattern = RegExp(
      r'\{\{\^(\w+)\}\}(.*?)\{\{/\1\}\}',
      dotAll: true,
    );

    return template.replaceAllMapped(inversePattern, (match) {
      final conditionName = match.group(1) as String;
      final content = match.group(2) as String;
      final value = variables[conditionName];
      final shouldRender = !_isTruthy(value);

      if (shouldRender) {
        return _processSections(content, variables);
      }

      return '';
    });
  }

  /// Processes a single inverse section
  static String _processInverseSection(
    String template,
    String conditionName,
    String content,
    Map<String, dynamic> variables,
  ) {
    final value = variables[conditionName];
    final shouldRender = !_isTruthy(value);

    if (shouldRender) {
      return _processSections(content, variables);
    }

    return '';
  }

  /// Checks if a value is truthy (for conditionals)
  static bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  /// Formats a value for template substitution
  static String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is List) return value.join(', ');
    return value.toString();
  }
}

/// Parses a DotPrompt-style template file
/// 
/// Extracts YAML front matter and template content from .prompt files
class PromptTemplateParser {
  /// Parses a .prompt file and returns the template content (without YAML front matter)
  static Future<String> parseTemplateFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw StateError('Template file not found: $filePath');
    }

    final content = await file.readAsString();
    return parseTemplate(content);
  }

  /// Parses template content and extracts the template (removes YAML front matter)
  static String parseTemplate(String content) {
    // Split by YAML front matter delimiter (---)
    final parts = content.split('---');

    if (parts.length < 3) {
      // No YAML front matter, return content as-is
      return content.trim();
    }

    // Return content after YAML front matter
    return parts.skip(2).join('---').trim();
  }

  /// Parses YAML front matter from a .prompt file
  static Future<Map<String, dynamic>> parseMetadata(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw StateError('Template file not found: $filePath');
    }

    final content = await file.readAsString();
    return parseMetadataFromContent(content);
  }

  /// Parses YAML front matter from template content
  static Map<String, dynamic> parseMetadataFromContent(String content) {
    final parts = content.split('---');

    if (parts.length < 3) {
      // No YAML front matter
      return {};
    }

    final yamlContent = parts[1].trim();
    if (yamlContent.isEmpty) {
      return {};
    }

    try {
      final yaml = loadYaml(yamlContent) as Map?;
      return yaml?.cast<String, dynamic>() ?? {};
    } catch (e) {
      return {};
    }
  }
}

