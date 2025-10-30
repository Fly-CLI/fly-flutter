import 'dart:io';
import 'package:mustache_template/mustache.dart';
import 'package:yaml/yaml.dart';

/// Wrapper for mustache_template that implements Mustache syntax for prompt templates
/// 
/// This class provides an interface for rendering Mustache templates,
/// delegating to the official mustache_template package maintained by the Flutter team.
/// 
/// Supports full Mustache spec:
/// - Variable substitution: {{variable}}
/// - Sections: {{#variable}}...{{/variable}} and {{^variable}}...{{/variable}}
/// - Lists: {{#list}}...{{/list}} with {{.}} for current item
class PromptTemplateEngine {
  /// Renders a template string with the given variables
  /// 
  /// [template] - The template string with Mustache syntax
  /// [variables] - Map of variable names to values
  /// Returns the rendered template string
  static String render(String template, Map<String, dynamic> variables) {
    try {
      // Create a Template instance from the source string
      final t = Template(template, lenient: true);
      
      // Render the template with the provided variables
      return t.renderString(variables);
    } on TemplateException catch (e) {
      // Provide better error messages for template rendering issues
      throw StateError(
        'Template rendering error: ${e.message}\n'
        'At line ${e.line}, column ${e.column}',
      );
    }
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

