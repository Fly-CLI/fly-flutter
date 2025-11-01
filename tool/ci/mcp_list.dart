import 'dart:convert';
import 'dart:io';

import 'package:fly_cli/src/integrations/mcp/prompts/prompt_template_engine.dart';
import 'package:path/path.dart' as path;

/// MCP List Tool
///
/// Lists all MCP tools, prompts, and resources by inspecting the Dart codebase.
///
/// Usage:
///   dart run tool/ci/mcp_list.dart [--type=tools|prompts|resources] [--format=table|json|yaml]
Future<void> main(List<String> args) async {
  String? filterType;
  String format = 'table';
  bool verbose = false;
  bool showParsed = false;
  bool parseOnly = false;

  // Parse arguments
  for (final arg in args) {
    if (arg.startsWith('--type=')) {
      filterType = arg.substring(7);
    } else if (arg.startsWith('--format=')) {
      format = arg.substring(9);
    } else if (arg == '--show-parsed') {
      showParsed = true;
    } else if (arg == '--parse-only') {
      parseOnly = true;
      filterType = 'prompts'; // Force prompts type
    } else if (arg == '--verbose' || arg == '-v') {
      verbose = true;
    } else if (arg == '--help' || arg == '-h') {
      printUsage();
      exit(0);
    }
  }

  // Get project root (assuming script is in tool/ci/)
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final projectRoot = scriptDir.parent.parent;

  // Build list data
  final data = <String, Map<String, Object?>>{};

  if (filterType == null || filterType == 'tools') {
    data['tools'] = await listTools(projectRoot, verbose);
  }

  if (filterType == null || filterType == 'prompts') {
    data['prompts'] = await listPrompts(
      projectRoot,
      verbose,
      showParsed: showParsed || parseOnly,
      parseOnly: parseOnly,
    );
  }

  if (filterType == null || filterType == 'resources') {
    data['resources'] = await listResources(projectRoot, verbose);
  }

  // Output in requested format
  switch (format) {
    case 'json':
      print(jsonEncode(data));
      break;
    case 'yaml':
      printYaml(data);
      break;
    case 'table':
    default:
      printTable(data, verbose, showParsed: showParsed || parseOnly);
      break;
  }
}

Future<Map<String, Object?>> listTools(
  Directory projectRoot,
  bool verbose,
) async {
  // Read McpTool enum and extract tool names
  final toolTypeFile = File(
    path.join(
      projectRoot.path,
      'packages',
      'fly_cli',
      'lib',
      'src',
      'core',
      'definitions',
      'mcp_tool.dart',
    ),
  );

  if (!await toolTypeFile.exists()) {
    return {'items': [], 'count': 0};
  }

  final content = await toolTypeFile.readAsString();

  // Extract enum values using regex
  final enumPattern = RegExp(r'enum\s+McpTool\s*\{([^}]+)\}');
  final match = enumPattern.firstMatch(content);

  if (match == null) {
    return {'items': [], 'count': 0};
  }

  final enumBody = match.group(1)!;
  final toolNames = <String>[];

  // Extract enum values (e.g., flyEcho, flutterDoctor)
  final enumValuePattern = RegExp(r'(\w+),?\s*');
  for (final match in enumValuePattern.allMatches(enumBody)) {
    final name = match.group(1);
    if (name != null && name.isNotEmpty) {
      toolNames.add(name);
    }
  }

  // Get tool details from strategy registry
  final items = <Map<String, Object?>>[];

  for (final toolName in toolNames) {
    // Convert enum name to tool name (e.g., flyEcho -> fly.echo)
    final toolId = _enumNameToToolId(toolName);

    // Find strategy file
    final strategyFileName = _enumNameToStrategyFile(toolName);
    final strategyFile = File(
      path.join(
        projectRoot.path,
        'packages',
        'fly_cli',
        'lib',
        'src',
        'features',
        'mcp',
        'tools',
        strategyFileName,
      ),
    );

    final item = <String, Object?>{
      'name': toolId,
      'enumValue': toolName,
    };

    if (await strategyFile.exists()) {
      final strategyContent = await strategyFile.readAsString();

      // Extract description
      final descMatch = RegExp(
        r"String\s+get\s+description\s*=>\s*['"
        "]([^'"
        "]+)['"
        "]",
      ).firstMatch(strategyContent);
      if (descMatch != null) {
        item['description'] = descMatch.group(1)!;
      }

      // Extract metadata
      final readOnlyMatch = RegExp(
        r'bool\s+get\s+readOnly\s*=>\s*(\w+)',
      ).firstMatch(strategyContent);
      if (readOnlyMatch != null) {
        item['readOnly'] = readOnlyMatch.group(1) == 'true';
      }

      final writesToDiskMatch = RegExp(
        r'bool\s+get\s+writesToDisk\s*=>\s*(\w+)',
      ).firstMatch(strategyContent);
      if (writesToDiskMatch != null) {
        item['writesToDisk'] = writesToDiskMatch.group(1) == 'true';
      }

      final idempotentMatch = RegExp(
        r'bool\s+get\s+idempotent\s*=>\s*(\w+)',
      ).firstMatch(strategyContent);
      if (idempotentMatch != null) {
        item['idempotent'] = idempotentMatch.group(1) == 'true';
      }

      if (verbose) {
        item['strategyFile'] = strategyFile.path;
      }
    }

    items.add(item);
  }

  return {'items': items, 'count': items.length};
}

Future<Map<String, Object?>> listPrompts(
  Directory projectRoot,
  bool verbose, {
  bool showParsed = false,
  bool parseOnly = false,
}) async {
  // Read PromptType enum
  final promptTypeFile = File(
    path.join(
      projectRoot.path,
      'packages',
      'fly_mcp_server',
      'lib',
      'src',
      'domain',
      'prompt_type.dart',
    ),
  );

  if (!await promptTypeFile.exists()) {
    return {'items': [], 'count': 0};
  }

  final content = await promptTypeFile.readAsString();
  final enumPattern = RegExp(r'enum\s+PromptType\s*\{([^}]+)\}');
  final match = enumPattern.firstMatch(content);

  if (match == null) {
    return {'items': [], 'count': 0};
  }

  final enumBody = match.group(1)!;
  final promptNames = <String>[];

  final enumValuePattern = RegExp(r'(\w+),?\s*');
  for (final match in enumValuePattern.allMatches(enumBody)) {
    final name = match.group(1);
    if (name != null && name.isNotEmpty) {
      promptNames.add(name);
    }
  }

  final items = <Map<String, Object?>>[];
  final templatesDir = Directory(
    path.join(
      projectRoot.path,
      'packages',
      'fly_cli',
      'lib',
      'src',
      'features',
      'mcp',
      'prompts',
      'templates',
    ),
  );

  for (final promptName in promptNames) {
    final promptId = _enumNameToPromptId(promptName);
    final templateFileName = _enumNameToTemplateFile(promptName);
    final templateFile = File(path.join(templatesDir.path, templateFileName));

    final item = <String, Object?>{
      'id': promptId,
      'enumValue': promptName,
      'templateFile': templateFile.path,
      'templateExists': await templateFile.exists(),
    };

    // Find strategy file
    final strategyFileName = _enumNameToPromptStrategyFile(promptName);
    final strategyFile = File(
      path.join(
        projectRoot.path,
        'packages',
        'fly_cli',
        'lib',
        'src',
        'features',
        'mcp',
        'prompts',
        strategyFileName,
      ),
    );

    if (await strategyFile.exists()) {
      final strategyContent = await strategyFile.readAsString();

      // Extract title
      final titleMatch = RegExp(
        r"String\s+get\s+title\s*=>\s*['"
        "]([^'"
        "]+)['"
        "]",
      ).firstMatch(strategyContent);
      if (titleMatch != null) {
        item['title'] = titleMatch.group(1)!;
      }

      // Extract description
      final descMatch = RegExp(
        r"String\s+get\s+description\s*=>\s*['"
        "]([^'"
        "]+)['"
        "]",
      ).firstMatch(strategyContent);
      if (descMatch != null) {
        item['description'] = descMatch.group(1)!;
      }

      if (verbose) {
        item['strategyFile'] = strategyFile.path;
      }
    }

    // Parse template if requested
    if ((showParsed || parseOnly) && await templateFile.exists()) {
      try {
        final parsed = await parsePromptTemplate(templateFile);
        if (parsed != null) {
          item['metadata'] = parsed['metadata'];
          item['template'] = parsed['template'];
          item['variables'] = parsed['variables'];
          if (parsed.containsKey('parseError')) {
            item['parseError'] = parsed['parseError'];
          }
        }
      } catch (e) {
        item['parseError'] = 'Failed to parse template: $e';
      }
    }

    items.add(item);
  }

  return {'items': items, 'count': items.length};
}

Future<Map<String, Object?>> listResources(
  Directory projectRoot,
  bool verbose,
) async {
  // Read ResourceType enum
  final resourceTypeFile = File(
    path.join(
      projectRoot.path,
      'packages',
      'fly_mcp_server',
      'lib',
      'src',
      'domain',
      'resource_type.dart',
    ),
  );

  if (!await resourceTypeFile.exists()) {
    return {'items': [], 'count': 0};
  }

  final content = await resourceTypeFile.readAsString();
  final enumPattern = RegExp(r'enum\s+ResourceType\s*\{([^}]+)\}');
  final match = enumPattern.firstMatch(content);

  if (match == null) {
    return {'items': [], 'count': 0};
  }

  final enumBody = match.group(1)!;
  final resourceNames = <String>[];

  final enumValuePattern = RegExp(r'(\w+),?\s*');
  for (final match in enumValuePattern.allMatches(enumBody)) {
    final name = match.group(1);
    if (name != null && name.isNotEmpty) {
      resourceNames.add(name);
    }
  }

  final items = <Map<String, Object?>>[];

  for (final resourceName in resourceNames) {
    // Find strategy file
    final strategyFileName = _enumNameToResourceStrategyFile(resourceName);
    final strategyFile = File(
      path.join(
        projectRoot.path,
        'packages',
        'fly_cli',
        'lib',
        'src',
        'features',
        'mcp',
        'resources',
        strategyFileName,
      ),
    );

    final item = <String, Object?>{
      'name': resourceName,
      'enumValue': resourceName,
      'strategyFile': strategyFile.path,
      'strategyExists': await strategyFile.exists(),
    };

    if (await strategyFile.exists()) {
      final strategyContent = await strategyFile.readAsString();

      // Extract URI prefix
      final uriPrefixMatch = RegExp(
        r"String\s+get\s+uriPrefix\s*=>\s*['"
        "]([^'"
        "]+)['"
        "]",
      ).firstMatch(strategyContent);
      if (uriPrefixMatch != null) {
        item['uriPrefix'] = uriPrefixMatch.group(1)!;
      }

      // Extract description
      final descMatch = RegExp(
        r"String\s+get\s+description\s*=>\s*['"
        "]([^'"
        "]+)['"
        "]",
      ).firstMatch(strategyContent);
      if (descMatch != null) {
        item['description'] = descMatch.group(1)!;
      }

      // Check read-only
      final readOnlyMatch = RegExp(
        r'bool\s+get\s+readOnly\s*=>\s*(\w+)',
      ).firstMatch(strategyContent);
      if (readOnlyMatch != null) {
        item['readOnly'] = readOnlyMatch.group(1) == 'true';
      }
    }

    items.add(item);
  }

  return {'items': items, 'count': items.length};
}

String _enumNameToToolId(String enumName) {
  // Convert camelCase to dot notation (e.g., flyEcho -> fly.echo)
  final buffer = StringBuffer();
  for (int i = 0; i < enumName.length; i++) {
    final char = enumName[i];
    if (char == char.toUpperCase() && i > 0) {
      buffer.write('.');
      buffer.write(char.toLowerCase());
    } else {
      buffer.write(char.toLowerCase());
    }
  }
  return buffer.toString();
}

String _enumNameToStrategyFile(String enumName) {
  // Convert camelCase to snake_case (e.g., flyEcho -> fly_echo_strategy.dart)
  final buffer = StringBuffer();
  for (int i = 0; i < enumName.length; i++) {
    final char = enumName[i];
    if (char == char.toUpperCase() && i > 0) {
      buffer.write('_');
      buffer.write(char.toLowerCase());
    } else {
      buffer.write(char.toLowerCase());
    }
  }
  buffer.write('_strategy.dart');
  return buffer.toString();
}

String _enumNameToPromptId(String enumName) {
  // Convert camelCase to dot notation (e.g., scaffoldPage -> fly.scaffold.page)
  return 'fly.${_enumNameToToolId(enumName)}';
}

String _enumNameToTemplateFile(String enumName) {
  // Convert camelCase to snake_case (e.g., scaffoldPage -> scaffold_page.prompt)
  final buffer = StringBuffer();
  for (int i = 0; i < enumName.length; i++) {
    final char = enumName[i];
    if (char == char.toUpperCase() && i > 0) {
      buffer.write('_');
      buffer.write(char.toLowerCase());
    } else {
      buffer.write(char.toLowerCase());
    }
  }
  buffer.write('.prompt');
  return buffer.toString();
}

String _enumNameToPromptStrategyFile(String enumName) {
  // Convert camelCase to snake_case (e.g., scaffoldPage -> scaffold_page_prompt_strategy.dart)
  final buffer = StringBuffer();
  for (int i = 0; i < enumName.length; i++) {
    final char = enumName[i];
    if (char == char.toUpperCase() && i > 0) {
      buffer.write('_');
      buffer.write(char.toLowerCase());
    } else {
      buffer.write(char.toLowerCase());
    }
  }
  buffer.write('_prompt_strategy.dart');
  return buffer.toString();
}

String _enumNameToResourceStrategyFile(String resourceName) {
  // Convert camelCase to snake_case (e.g., logsRun -> logs_run_resource_strategy.dart)
  final buffer = StringBuffer();
  for (int i = 0; i < resourceName.length; i++) {
    final char = resourceName[i];
    if (char == char.toUpperCase() && i > 0) {
      buffer.write('_');
      buffer.write(char.toLowerCase());
    } else {
      buffer.write(char.toLowerCase());
    }
  }
  buffer.write('_resource_strategy.dart');
  return buffer.toString();
}

/// Parse a prompt template file, extracting YAML metadata and template content
/// Uses PromptTemplateParser from prompt_template_engine.dart
Future<Map<String, Object?>?> parsePromptTemplate(File templateFile) async {
  try {
    // Use PromptTemplateParser to parse metadata
    Map<String, dynamic> metadata;
    String? parseError;

    try {
      metadata = await PromptTemplateParser.parseMetadata(templateFile.path);
    } catch (e) {
      parseError = 'YAML parse error: $e';
      metadata = <String, dynamic>{};
    }

    // Use PromptTemplateParser to extract template content
    String templateContent;
    try {
      templateContent = await PromptTemplateParser.parseTemplateFile(
        templateFile.path,
      );
    } catch (e) {
      if (parseError == null) {
        parseError = 'Template parse error: $e';
      }
      templateContent = '';
    }

    // Extract Mustache variables from template
    final variables = extractMustacheVariables(templateContent);

    final result = <String, Object?>{
      'metadata': metadata,
      'template': templateContent,
      'variables': variables,
    };

    if (parseError != null) {
      result['parseError'] = parseError;
    }

    return result;
  } catch (e) {
    return {
      'metadata': <String, dynamic>{},
      'template': '',
      'variables': <String>[],
      'parseError': 'Error reading template: $e',
    };
  }
}

/// Extract Mustache variables from template content
List<String> extractMustacheVariables(String template) {
  final variables = <String>{};

  // Match Mustache variable patterns: {{variable}}, {{#variable}}, {{/variable}}, etc.
  final pattern = RegExp(r'\{\{([#/^]?)([a-zA-Z_][a-zA-Z0-9_\.]*)([#/])?\}\}');

  for (final match in pattern.allMatches(template)) {
    final variable = match.group(2);
    if (variable != null && variable.isNotEmpty) {
      // Handle nested variables (e.g., "item.name")
      final parts = variable.split('.');
      variables.add(parts[0]); // Add the root variable name
    }
  }

  return variables.toList()..sort();
}

/// Print a YAML map with proper indentation
void printYamlMap(Map map, {int indent = 0}) {
  final prefix = '  ' * indent;
  for (final entry in map.entries) {
    final key = entry.key.toString();
    final value = entry.value;

    if (value is Map) {
      print('$prefix$key:');
      printYamlMap(value, indent: indent + 1);
    } else if (value is List) {
      print('$prefix$key:');
      for (final item in value) {
        if (item is Map) {
          print('${'  ' * (indent + 1)}-');
          printYamlMap(item, indent: indent + 2);
        } else {
          print('${'  ' * (indent + 1)}- $item');
        }
      }
    } else {
      final str = value?.toString() ?? '';
      if (str.contains('\n')) {
        print('$prefix$key: |');
        for (final line in str.split('\n')) {
          print('${'  ' * (indent + 1)}$line');
        }
      } else {
        print('$prefix$key: $str');
      }
    }
  }
}

void printTable(
  Map<String, Map<String, Object?>> data,
  bool verbose, {
  bool showParsed = false,
}) {
  if (data.containsKey('tools')) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('TOOLS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final tools = data['tools']!;
    final items = tools['items'] as List;
    print('Total: ${tools['count']}\n');

    for (final item in items) {
      final map = item as Map<String, Object?>;
      print('  ${map['name']}');
      if (map['description'] != null) {
        print('    Description: ${map['description']}');
      }
      if (map['readOnly'] != null) {
        print('    Read-only: ${map['readOnly']}');
      }
      if (map['writesToDisk'] != null) {
        print('    Writes to disk: ${map['writesToDisk']}');
      }
      if (map['idempotent'] != null) {
        print('    Idempotent: ${map['idempotent']}');
      }
      if (verbose && map['strategyFile'] != null) {
        print('    Strategy: ${map['strategyFile']}');
      }
      print('');
    }
  }

  if (data.containsKey('prompts')) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('PROMPTS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final prompts = data['prompts']!;
    final items = prompts['items'] as List;
    print('Total: ${prompts['count']}\n');

    // Check if we should show parsed templates
    final hasParsedData =
        items.isNotEmpty &&
        (items[0] as Map<String, Object?>).containsKey('metadata');

    for (final item in items) {
      final map = item as Map<String, Object?>;

      // For parse-only mode, skip basic info and only show parsed templates
      if (!showParsed) {
        print('  ${map['id']}');
        if (map['title'] != null) {
          print('    Title: ${map['title']}');
        }
        if (map['description'] != null) {
          print('    Description: ${map['description']}');
        }
        print('    Template: ${map['templateFile']}');
        print('    Template exists: ${map['templateExists']}');
        if (verbose && map['strategyFile'] != null) {
          print('    Strategy: ${map['strategyFile']}');
        }
        print('');
        continue;
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('PROMPT: ${map['id']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');

      // Only show basic info if not parse-only mode
      if (!hasParsedData || !showParsed) {
        if (map['title'] != null) {
          print('Title: ${map['title']}');
        }
        if (map['description'] != null) {
          print('Description: ${map['description']}');
        }
        print('Template File: ${map['templateFile']}');
        print('Template exists: ${map['templateExists']}');

        if (verbose && map['strategyFile'] != null) {
          print('Strategy: ${map['strategyFile']}');
        }
      }

      // Show parsed template information if available
      if (hasParsedData && map.containsKey('metadata')) {
        print('');
        print('YAML Metadata:');
        if (map['parseError'] != null) {
          print('  ⚠ Parse Error: ${map['parseError']}');
        } else if (map['metadata'] != null) {
          final metadataMap = map['metadata'] as Map<dynamic, dynamic>;
          if (metadataMap.isNotEmpty) {
            printYamlMap(metadataMap, indent: 2);
          }
        } else {
          print('  (No YAML front matter)');
        }

        print('');
        print('Template Content:');
        if (map['template'] != null) {
          final template = map['template'] as String;
          if (template.isNotEmpty) {
            // Print template with indentation
            for (final line in template.split('\n')) {
              print('  $line');
            }
          } else {
            print('  (Empty template)');
          }
        }

        if (map['variables'] != null) {
          final variables = map['variables'] as List;
          if (variables.isNotEmpty) {
            print('');
            print('Variables found: ${variables.join(', ')}');
          }
        }
      }

      print('');
    }
  }

  if (data.containsKey('resources')) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('RESOURCES');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final resources = data['resources']!;
    final items = resources['items'] as List;
    print('Total: ${resources['count']}\n');

    for (final item in items) {
      final map = item as Map<String, Object?>;
      print('  ${map['name']}');
      if (map['uriPrefix'] != null) {
        print('    URI prefix: ${map['uriPrefix']}');
      }
      if (map['description'] != null) {
        print('    Description: ${map['description']}');
      }
      if (map['readOnly'] != null) {
        print('    Read-only: ${map['readOnly']}');
      }
      print('    Strategy exists: ${map['strategyExists']}');
      if (verbose) {
        print('    Strategy: ${map['strategyFile']}');
      }
      print('');
    }
  }
}

void printYaml(Map<String, Object?> data) {
  // Simple YAML printer
  void printYamlValue(String key, Object? value, int indent) {
    final prefix = '  ' * indent;
    if (value is Map) {
      print('$prefix$key:');
      for (final entry in value.entries) {
        printYamlValue(entry.key as String, entry.value, indent + 1);
      }
    } else if (value is List) {
      print('$prefix$key:');
      for (final item in value) {
        if (item is Map) {
          print('${'  ' * (indent + 1)}-');
          for (final entry in item.entries) {
            printYamlValue(entry.key as String, entry.value, indent + 2);
          }
        } else {
          print('${'  ' * (indent + 1)}- $item');
        }
      }
    } else {
      final str = value?.toString() ?? '';
      if (str.contains('\n') || str.contains(':') || str.contains('#')) {
        print('$prefix$key: |');
        for (final line in str.split('\n')) {
          print('${'  ' * (indent + 1)}$line');
        }
      } else {
        print('$prefix$key: $str');
      }
    }
  }

  for (final entry in data.entries) {
    printYamlValue(entry.key, entry.value, 0);
  }
}

void printUsage() {
  print('Usage: dart run tool/ci/mcp_list.dart [OPTIONS]');
  print('');
  print('List MCP tools, prompts, and resources.');
  print('');
  print('Options:');
  print('  --type=TYPE          Filter by type (tools, prompts, resources)');
  print('  --format=FORMAT      Output format (table, json, yaml)');
  print(
    '  --show-parsed        When listing prompts, show parsed YAML metadata',
  );
  print('                      and template content');
  print(
    '  --parse-only         Only show parsed template information (for testing)',
  );
  print('                      Only works with --type=prompts');
  print('  -v, --verbose       Show verbose output');
  print('  -h, --help          Show this help message');
  print('');
  print('Examples:');
  print('  dart run tool/ci/mcp_list.dart');
  print('  dart run tool/ci/mcp_list.dart --type=tools --format=json');
  print('  dart run tool/ci/mcp_list.dart --type=prompts --show-parsed');
  print('  dart run tool/ci/mcp_list.dart --type=prompts --parse-only');
  print('  dart run tool/ci/mcp_list.dart --format=yaml --verbose');
}
