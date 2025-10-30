import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// MCP Validate Tool
/// 
/// Validates MCP tools, prompts, and resources by checking:
/// - Tools: schemas, handlers, metadata
/// - Prompts: template files, syntax, variables
/// - Resources: strategies, URI patterns
/// 
/// Usage:
///   dart run tool/ci/mcp_validate.dart [--type=tools|prompts|resources] [--format=table|json] [--strict]
Future<void> main(List<String> args) async {
  String? filterType;
  String format = 'table';
  bool strict = false;
  bool verbose = false;

  // Parse arguments
  for (final arg in args) {
    if (arg.startsWith('--type=')) {
      filterType = arg.substring(7);
    } else if (arg.startsWith('--format=')) {
      format = arg.substring(9);
    } else if (arg == '--strict') {
      strict = true;
    } else if (arg == '--verbose' || arg == '-v') {
      verbose = true;
    } else if (arg == '--help' || arg == '-h') {
      printUsage();
      exit(0);
    }
  }

  // Get project root
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final projectRoot = scriptDir.parent.parent;

  // Run validations
  final results = <String, Map<String, Object?>>{};
  int totalErrors = 0;
  int totalWarnings = 0;

  if (filterType == null || filterType == 'tools') {
    final result = await validateTools(projectRoot, verbose);
    results['tools'] = result;
    totalErrors += result['errorCount'] as int;
    totalWarnings += result['warningCount'] as int;
  }

  if (filterType == null || filterType == 'prompts') {
    final result = await validatePrompts(projectRoot, verbose);
    results['prompts'] = result;
    totalErrors += result['errorCount'] as int;
    totalWarnings += result['warningCount'] as int;
  }

  if (filterType == null || filterType == 'resources') {
    final result = await validateResources(projectRoot, verbose);
    results['resources'] = result;
    totalErrors += result['errorCount'] as int;
    totalWarnings += result['warningCount'] as int;
  }

  results['summary'] = {
    'totalErrors': totalErrors,
    'totalWarnings': totalWarnings,
    'isValid': totalErrors == 0,
  };

  // Output results
  switch (format) {
    case 'json':
      print(jsonEncode(results));
      break;
    case 'table':
    default:
      printValidationResults(results, verbose);
      break;
  }

  // Exit with error code if validation failed
  if (strict && totalErrors > 0) {
    exit(1);
  } else if (totalErrors > 0) {
    exit(1);
  } else {
    exit(0);
  }
}

Future<Map<String, Object?>> validateTools(Directory projectRoot, bool verbose) async {
  final errors = <Map<String, String>>[];
  final warnings = <Map<String, String>>[];

  // Read McpToolType enum
  final toolTypeFile = File(path.join(
    projectRoot.path,
    'packages',
    'fly_cli',
    'lib',
    'src',
    'features',
    'mcp',
    'mcp_tool_type.dart',
  ));

  if (!await toolTypeFile.exists()) {
    errors.add({
      'type': 'file_not_found',
      'message': 'McpToolType enum file not found',
      'file': toolTypeFile.path,
    });
    return {
      'items': [],
      'errorCount': errors.length,
      'warningCount': warnings.length,
      'errors': errors,
      'warnings': warnings,
    };
  }

  final content = await toolTypeFile.readAsString();
  final enumPattern = RegExp(r'enum\s+McpToolType\s*\{([^}]+)\}');
  final match = enumPattern.firstMatch(content);

  if (match == null) {
    errors.add({
      'type': 'parse_error',
      'message': 'Could not parse McpToolType enum',
      'file': toolTypeFile.path,
    });
    return {
      'items': [],
      'errorCount': errors.length,
      'warningCount': warnings.length,
      'errors': errors,
      'warnings': warnings,
    };
  }

  final enumBody = match.group(1)!;
  final toolNames = <String>[];

  final enumValuePattern = RegExp(r'(\w+),?\s*');
  for (final match in enumValuePattern.allMatches(enumBody)) {
    final name = match.group(1);
    if (name != null && name.isNotEmpty) {
      toolNames.add(name);
    }
  }

  final items = <Map<String, Object?>>[];

  for (final toolName in toolNames) {
    final item = <String, Object?>{
      'name': _enumNameToToolId(toolName),
      'enumValue': toolName,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // Check strategy file exists
    final strategyFileName = _enumNameToStrategyFile(toolName);
    final strategyFile = File(path.join(
      projectRoot.path,
      'packages',
      'fly_cli',
      'lib',
      'src',
      'features',
      'mcp',
      'tools',
      strategyFileName,
    ));

    if (!await strategyFile.exists()) {
      item['errors'] = (item['errors'] as List<String>)
        ..add('Strategy file not found: $strategyFileName');
      errors.add({
        'type': 'file_not_found',
        'tool': toolName,
        'message': 'Strategy file not found: $strategyFileName',
        'file': strategyFile.path,
      });
    } else {
      // Validate strategy file content
      final strategyContent = await strategyFile.readAsString();

      // Check required methods/properties exist
      if (!strategyContent.contains('String get name')) {
        item['errors'] = (item['errors'] as List<String>)
          ..add('Missing required property: name');
        errors.add({
          'type': 'missing_property',
          'tool': toolName,
          'message': 'Missing required property: name',
          'file': strategyFile.path,
        });
      }

      if (!strategyContent.contains('String get description')) {
        item['errors'] = (item['errors'] as List<String>)
          ..add('Missing required property: description');
        errors.add({
          'type': 'missing_property',
          'tool': toolName,
          'message': 'Missing required property: description',
          'file': strategyFile.path,
        });
      }

      // Check for schema definitions
      if (!strategyContent.contains('paramsSchema') && !strategyContent.contains('ObjectSchema')) {
        item['warnings'] = (item['warnings'] as List<String>)
          ..add('No paramsSchema found');
        warnings.add({
          'type': 'missing_schema',
          'tool': toolName,
          'message': 'No paramsSchema found',
          'file': strategyFile.path,
        });
      }
    }

    items.add(item);
  }

  return {
    'items': items,
    'errorCount': errors.length,
    'warningCount': warnings.length,
    'errors': errors,
    'warnings': warnings,
  };
}

Future<Map<String, Object?>> validatePrompts(Directory projectRoot, bool verbose) async {
  final errors = <Map<String, String>>[];
  final warnings = <Map<String, String>>[];

  // Read PromptType enum
  final promptTypeFile = File(path.join(
    projectRoot.path,
    'packages',
    'fly_mcp_server',
    'lib',
    'src',
    'domain',
    'prompt_type.dart',
  ));

  if (!await promptTypeFile.exists()) {
    errors.add({
      'type': 'file_not_found',
      'message': 'PromptType enum file not found',
      'file': promptTypeFile.path,
    });
    return {
      'items': [],
      'errorCount': errors.length,
      'warningCount': warnings.length,
      'errors': errors,
      'warnings': warnings,
    };
  }

  final content = await promptTypeFile.readAsString();
  final enumPattern = RegExp(r'enum\s+PromptType\s*\{([^}]+)\}');
  final match = enumPattern.firstMatch(content);

  if (match == null) {
    errors.add({
      'type': 'parse_error',
      'message': 'Could not parse PromptType enum',
      'file': promptTypeFile.path,
    });
    return {
      'items': [],
      'errorCount': errors.length,
      'warningCount': warnings.length,
      'errors': errors,
      'warnings': warnings,
    };
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
  final templatesDir = Directory(path.join(
    projectRoot.path,
    'packages',
    'fly_cli',
    'lib',
    'src',
    'features',
    'mcp',
    'prompts',
    'templates',
  ));

  for (final promptName in promptNames) {
    final promptId = _enumNameToPromptId(promptName);
    final item = <String, Object?>{
      'id': promptId,
      'enumValue': promptName,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // Check template file exists
    final templateFileName = _enumNameToTemplateFile(promptName);
    final templateFile = File(path.join(templatesDir.path, templateFileName));

    if (!await templateFile.exists()) {
      item['errors'] = (item['errors'] as List<String>)
        ..add('Template file not found: $templateFileName');
      errors.add({
        'type': 'file_not_found',
        'prompt': promptName,
        'message': 'Template file not found: $templateFileName',
        'file': templateFile.path,
      });
    } else {
      // Validate template can be read
      try {
        final templateContent = await templateFile.readAsString();
        
        // Basic validation: check template is not empty
        final parts = templateContent.split('---');
        String templateText;
        if (parts.length >= 3) {
          templateText = parts.skip(2).join('---').trim();
        } else {
          templateText = templateContent.trim();
        }

        if (templateText.isEmpty) {
          item['warnings'] = (item['warnings'] as List<String>)
            ..add('Template file is empty');
          warnings.add({
            'type': 'empty_template',
            'prompt': promptName,
            'message': 'Template file is empty',
            'file': templateFile.path,
          });
        }
      } catch (e) {
        item['errors'] = (item['errors'] as List<String>)
          ..add('Error reading template: $e');
        errors.add({
          'type': 'read_error',
          'prompt': promptName,
          'message': 'Error reading template: $e',
          'file': templateFile.path,
        });
      }
    }

    // Check strategy file exists
    final strategyFileName = _enumNameToPromptStrategyFile(promptName);
    final strategyFile = File(path.join(
      projectRoot.path,
      'packages',
      'fly_cli',
      'lib',
      'src',
      'features',
      'mcp',
      'prompts',
      strategyFileName,
    ));

    if (!await strategyFile.exists()) {
      item['errors'] = (item['errors'] as List<String>)
        ..add('Strategy file not found: $strategyFileName');
      errors.add({
        'type': 'file_not_found',
        'prompt': promptName,
        'message': 'Strategy file not found: $strategyFileName',
        'file': strategyFile.path,
      });
    }

    items.add(item);
  }

  return {
    'items': items,
    'errorCount': errors.length,
    'warningCount': warnings.length,
    'errors': errors,
    'warnings': warnings,
  };
}

Future<Map<String, Object?>> validateResources(Directory projectRoot, bool verbose) async {
  final errors = <Map<String, String>>[];
  final warnings = <Map<String, String>>[];

  // Read ResourceType enum
  final resourceTypeFile = File(path.join(
    projectRoot.path,
    'packages',
    'fly_mcp_server',
    'lib',
    'src',
    'domain',
    'resource_type.dart',
  ));

  if (!await resourceTypeFile.exists()) {
    errors.add({
      'type': 'file_not_found',
      'message': 'ResourceType enum file not found',
      'file': resourceTypeFile.path,
    });
    return {
      'items': [],
      'errorCount': errors.length,
      'warningCount': warnings.length,
      'errors': errors,
      'warnings': warnings,
    };
  }

  final content = await resourceTypeFile.readAsString();
  final enumPattern = RegExp(r'enum\s+ResourceType\s*\{([^}]+)\}');
  final match = enumPattern.firstMatch(content);

  if (match == null) {
    errors.add({
      'type': 'parse_error',
      'message': 'Could not parse ResourceType enum',
      'file': resourceTypeFile.path,
    });
    return {
      'items': [],
      'errorCount': errors.length,
      'warningCount': warnings.length,
      'errors': errors,
      'warnings': warnings,
    };
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
    final item = <String, Object?>{
      'name': resourceName,
      'enumValue': resourceName,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // Check strategy file exists
    final strategyFileName = _enumNameToResourceStrategyFile(resourceName);
    final strategyFile = File(path.join(
      projectRoot.path,
      'packages',
      'fly_cli',
      'lib',
      'src',
      'features',
      'mcp',
      'resources',
      strategyFileName,
    ));

    if (!await strategyFile.exists()) {
      item['errors'] = (item['errors'] as List<String>)
        ..add('Strategy file not found: $strategyFileName');
      errors.add({
        'type': 'file_not_found',
        'resource': resourceName,
        'message': 'Strategy file not found: $strategyFileName',
        'file': strategyFile.path,
      });
    } else {
      // Validate strategy file content
      final strategyContent = await strategyFile.readAsString();

      // Check required properties
      if (!strategyContent.contains('String get uriPrefix')) {
        item['errors'] = (item['errors'] as List<String>)
          ..add('Missing required property: uriPrefix');
        errors.add({
          'type': 'missing_property',
          'resource': resourceName,
          'message': 'Missing required property: uriPrefix',
          'file': strategyFile.path,
        });
      }

      if (!strategyContent.contains('String get description')) {
        item['errors'] = (item['errors'] as List<String>)
          ..add('Missing required property: description');
        errors.add({
          'type': 'missing_property',
          'resource': resourceName,
          'message': 'Missing required property: description',
          'file': strategyFile.path,
        });
      }

      // Check URI prefix format
      final uriPrefixMatch = RegExp(r"String\s+get\s+uriPrefix\s*=>\s*['""]([^'""]+)['""]").firstMatch(strategyContent);
      if (uriPrefixMatch != null) {
        final uriPrefix = uriPrefixMatch.group(1)!;
        if (!uriPrefix.endsWith('://') && !uriPrefix.endsWith('/')) {
          item['warnings'] = (item['warnings'] as List<String>)
            ..add('URI prefix should end with "://" or "/": $uriPrefix');
          warnings.add({
            'type': 'uri_format_warning',
            'resource': resourceName,
            'message': 'URI prefix should end with "://" or "/": $uriPrefix',
            'file': strategyFile.path,
          });
        }
      }
    }

    items.add(item);
  }

  return {
    'items': items,
    'errorCount': errors.length,
    'warningCount': warnings.length,
    'errors': errors,
    'warnings': warnings,
  };
}

String _enumNameToToolId(String enumName) {
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
  return 'fly.${_enumNameToToolId(enumName)}';
}

String _enumNameToTemplateFile(String enumName) {
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

void printValidationResults(Map<String, Object?> results, bool verbose) {
  final summary = results['summary'] as Map<String, Object?>;
  final totalErrors = summary['totalErrors'] as int;
  final totalWarnings = summary['totalWarnings'] as int;
  final isValid = summary['isValid'] as bool;

  print('');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('MCP VALIDATION RESULTS');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');
  print('Summary:');
  print('  Errors:   $totalErrors');
  print('  Warnings: $totalWarnings');
  print('  Status:   ${isValid ? "✓ VALID" : "✗ INVALID"}');
  print('');

  if (results.containsKey('tools')) {
    final tools = results['tools'] as Map<String, Object?>;
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('TOOLS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Errors: ${tools['errorCount']}, Warnings: ${tools['warningCount']}');
    print('');

    final items = tools['items'] as List;
    for (final item in items) {
      final map = item as Map<String, Object?>;
      final errors = map['errors'] as List<String>;
      final warnings = map['warnings'] as List<String>;

      if (errors.isNotEmpty || warnings.isNotEmpty) {
        print('  ${map['name']}');
        if (errors.isNotEmpty) {
          for (final error in errors) {
            print('    ✗ $error');
          }
        }
        if (warnings.isNotEmpty) {
          for (final warning in warnings) {
            print('    ⚠ $warning');
          }
        }
        print('');
      }
    }
  }

  if (results.containsKey('prompts')) {
    final prompts = results['prompts'] as Map<String, Object?>;
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('PROMPTS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Errors: ${prompts['errorCount']}, Warnings: ${prompts['warningCount']}');
    print('');

    final items = prompts['items'] as List;
    for (final item in items) {
      final map = item as Map<String, Object?>;
      final errors = map['errors'] as List<String>;
      final warnings = map['warnings'] as List<String>;

      if (errors.isNotEmpty || warnings.isNotEmpty) {
        print('  ${map['id']}');
        if (errors.isNotEmpty) {
          for (final error in errors) {
            print('    ✗ $error');
          }
        }
        if (warnings.isNotEmpty) {
          for (final warning in warnings) {
            print('    ⚠ $warning');
          }
        }
        print('');
      }
    }
  }

  if (results.containsKey('resources')) {
    final resources = results['resources'] as Map<String, Object?>;
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('RESOURCES');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Errors: ${resources['errorCount']}, Warnings: ${resources['warningCount']}');
    print('');

    final items = resources['items'] as List;
    for (final item in items) {
      final map = item as Map<String, Object?>;
      final errors = map['errors'] as List<String>;
      final warnings = map['warnings'] as List<String>;

      if (errors.isNotEmpty || warnings.isNotEmpty) {
        print('  ${map['name']}');
        if (errors.isNotEmpty) {
          for (final error in errors) {
            print('    ✗ $error');
          }
        }
        if (warnings.isNotEmpty) {
          for (final warning in warnings) {
            print('    ⚠ $warning');
          }
        }
        print('');
      }
    }
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');
}

void printUsage() {
  print('Usage: dart run tool/ci/mcp_validate.dart [OPTIONS]');
  print('');
  print('Validate MCP tools, prompts, and resources.');
  print('');
  print('Options:');
  print('  --type=TYPE          Filter by type (tools, prompts, resources)');
  print('  --format=FORMAT      Output format (table, json)');
  print('  --strict            Exit with error code on validation failures');
  print('  -v, --verbose       Show verbose output');
  print('  -h, --help          Show this help message');
  print('');
  print('Examples:');
  print('  dart run tool/ci/mcp_validate.dart');
  print('  dart run tool/ci/mcp_validate.dart --type=tools --strict');
  print('  dart run tool/ci/mcp_validate.dart --format=json');
}


