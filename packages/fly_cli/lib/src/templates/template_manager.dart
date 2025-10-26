import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../cache/template_cache.dart';
import '../cache/cache_models.dart';
import 'models/template_info.dart';
import 'models/template_variable.dart';

/// Template management system for Fly CLI
/// 
/// Handles template discovery, validation, and generation using Mason bricks.
/// Integrates with template caching for offline support and performance.
class TemplateManager {
  TemplateManager({
    required this.templatesDirectory,
    required this.logger,
    TemplateCacheManager? cacheManager,
  }) : _cacheManager = cacheManager ?? TemplateCacheManager(logger: logger);

  final String templatesDirectory;
  final Logger logger;
  final TemplateCacheManager _cacheManager;
  
  /// Get all available templates
  Future<List<TemplateInfo>> getAvailableTemplates() async {
    final templates = <TemplateInfo>[];
    
    try {
      final dir = Directory(templatesDirectory);
      if (!await dir.exists()) {
        logger.warn('Templates directory does not exist: $templatesDirectory');
        return templates;
      }
      
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final templateInfo = await _loadTemplateInfo(entity.path);
          if (templateInfo != null) {
            templates.add(templateInfo);
          }
        }
      }
    } catch (e) {
      logger.err('Error loading templates: $e');
    }
    
    return templates;
  }

  /// Get template by name with caching support
  Future<TemplateInfo?> getTemplate(String name) async {
    try {
      // Initialize cache if not already done
      await _cacheManager.initialize();

      // Try cache first
      final cacheResult = await _cacheManager.getTemplate(name);

      if (cacheResult is CacheSuccess) {
        logger.info('Using cached template: $name');
        return _templateFromCache(cacheResult.template);
      } else if (cacheResult is CacheExpired) {
        logger.info('Cached template $name expired, reloading from source');
      } else if (cacheResult is CacheCorrupted) {
        logger.warn('Cached template $name corrupted, reloading from source');
      }

      // Load from source
      final templatePath = path.join(templatesDirectory, name);
      final template = await _loadTemplateInfo(templatePath);

      // Cache for future use
      if (template != null) {
        try {
          await _cacheManager.cacheTemplate(name, template.toJson());
          logger.info('Cached template: $name');
        } catch (e) {
          logger.warn('Failed to cache template $name: $e');
          // Don't fail the operation if caching fails
        }
      }

      return template;
    } catch (e) {
      logger.err('Error getting template $name: $e');
      return null;
    }
  }

  /// Convert cached template data back to TemplateInfo
  TemplateInfo _templateFromCache(CachedTemplate cachedTemplate) {
    final data = cachedTemplate.templateData;
    return TemplateInfo(
      name: data['name'] as String,
      version: data['version'] as String,
      description: data['description'] as String,
      path: data['path'] as String,
      minFlutterSdk: data['minFlutterSdk'] as String,
      minDartSdk: data['minDartSdk'] as String,
      variables: (data['variables'] as List?)?.map((v) => TemplateVariable.fromJson(v as Map<String, dynamic>)).toList() ?? [],
      features: List<String>.from(data['features'] as List),
      packages: List<String>.from(data['packages'] as List),
    );
  }

  /// Generate project from template
  Future<TemplateGenerationResult> generateProject({
    required String templateName,
    required String projectName,
    required String outputDirectory,
    required TemplateVariables variables,
    bool dryRun = false,
  }) async {
    try {
      final template = await getTemplate(templateName);
      if (template == null) {
        return TemplateGenerationResult.failure(
          'Template "$templateName" not found',
        );
      }
      
      final brickPath = path.join(templatesDirectory, templateName, '__brick__');
      final brick = Brick.path(brickPath);
      
      // Debug output to stderr (not affected by JSON output mode)
      stderr.writeln('DEBUG: Loading brick from: $brickPath');
      stderr.writeln('DEBUG: Brick exists: ${await Directory(brickPath).exists()}');
      
      final targetDirectory = path.join(outputDirectory, projectName);
      
      if (dryRun) {
        return TemplateGenerationResult.dryRun(
          template: template,
          targetDirectory: targetDirectory,
          variables: variables,
        );
      }
      
      // Check if directory already exists
      if (await Directory(targetDirectory).exists()) {
        return TemplateGenerationResult.failure(
          'Directory "$projectName" already exists',
        );
      }
      
      // Run pre-generation hooks
      await _runPreGenerationHooks(template, variables);
      
      // Generate the project using simple file copying instead of Mason
      stderr.writeln('DEBUG: Using simple file copying instead of Mason');
      stderr.writeln('DEBUG: Variables: ${variables.toMasonVars()}');
      stderr.writeln('DEBUG: Target directory: $targetDirectory');
      
      final result = await _generateProjectFiles(
        brickPath,
        targetDirectory,
        variables.toMasonVars(),
      );
      
      stderr.writeln('DEBUG: File generation result: ${result.length} files generated');
      
      // Run post-generation hooks
      await _runPostGenerationHooks(template, targetDirectory, variables);
      
      return TemplateGenerationResult.success(
        template: template,
        targetDirectory: targetDirectory,
        filesGenerated: result.length,
        duration: Duration.zero, // Mason doesn't provide duration in this API
      );
    } catch (e) {
      return TemplateGenerationResult.failure('Generation failed: $e');
    }
  }
  
  /// Validate template
  Future<TemplateValidationResult> validateTemplate(String templateName) async {
    try {
      final template = await getTemplate(templateName);
      if (template == null) {
        return TemplateValidationResult.failure(
          'Template "$templateName" not found',
        );
      }
      
      final brick = Brick.path(path.join(templatesDirectory, templateName, '__brick__'));
      
      // Validate brick structure
      final issues = <String>[];
      
      // Check required files
      // TODO: Fix brick.files access - need to check Mason API
      // if (!brick.files.any((file) => file.path == 'pubspec.yaml')) {
      //   issues.add('Missing pubspec.yaml');
      // }
      
      // if (!brick.files.any((file) => file.path == 'lib/main.dart')) {
      //   issues.add('Missing lib/main.dart');
      // }
      
      // Check template metadata
      if (template.description.isEmpty) {
        issues.add('Missing template description');
      }
      
      if (template.version.isEmpty) {
        issues.add('Missing template version');
      }
      
      return TemplateValidationResult(
        isValid: issues.isEmpty,
        issues: issues,
        template: template,
      );
    } catch (e) {
      return TemplateValidationResult.failure('Validation failed: $e');
    }
  }
  
  /// Load template information from directory
  Future<TemplateInfo?> _loadTemplateInfo(String templatePath) async {
    try {
      // Check for template.yaml in the template directory
      final templateYamlPath = path.join(templatePath, 'template.yaml');
      final templateYamlFile = File(templateYamlPath);
      
      if (!await templateYamlFile.exists()) {
        logger.warn('Missing template.yaml in $templatePath');
        return null;
      }
      
      final yamlContent = await templateYamlFile.readAsString();
      final yaml = loadYaml(yamlContent) as Map<dynamic, dynamic>;
      
      // Use the __brick__ subdirectory as the actual template path
      final brickPath = path.join(templatePath, '__brick__');
      return TemplateInfo.fromYaml(yaml, brickPath);
    } catch (e) {
      logger.warn('Error loading template info from $templatePath: $e');
      return null;
    }
  }
  
  /// Run pre-generation hooks
  Future<void> _runPreGenerationHooks(
    TemplateInfo template,
    TemplateVariables variables,
  ) async {
    final hooksDir = path.join(template.path, 'hooks');
    final preGenFile = File(path.join(hooksDir, 'pre_gen.dart'));
    
    if (await preGenFile.exists()) {
      try {
        // Execute pre-generation hook
        final result = await Process.run('dart', [preGenFile.path]);
        if (result.exitCode != 0) {
          logger.warn('Pre-generation hook failed: ${result.stderr}');
        }
      } catch (e) {
        logger.warn('Error running pre-generation hook: $e');
      }
    }
  }
  
  /// Run post-generation hooks
  Future<void> _runPostGenerationHooks(
    TemplateInfo template,
    String targetDirectory,
    TemplateVariables variables,
  ) async {
    final hooksDir = path.join(template.path, 'hooks');
    final postGenFile = File(path.join(hooksDir, 'post_gen.dart'));
    
    if (await postGenFile.exists()) {
      try {
        // Execute post-generation hook
        final result = await Process.run(
          'dart',
          [postGenFile.path],
          workingDirectory: targetDirectory,
        );
        if (result.exitCode != 0) {
          logger.warn('Post-generation hook failed: ${result.stderr}');
        }
      } catch (e) {
        logger.warn('Error running post-generation hook: $e');
      }
    }
  }

  /// Generate project files using simple file copying
  Future<List<GeneratedFile>> _generateProjectFiles(
    String brickPath,
    String targetDirectory,
    Map<String, dynamic> variables,
  ) async {
    final generatedFiles = <GeneratedFile>[];
    final brickDir = Directory(brickPath);
    
    if (!await brickDir.exists()) {
      throw Exception('Brick directory does not exist: $brickPath');
    }
    
    // Create target directory
    await Directory(targetDirectory).create(recursive: true);
    
    // Copy files recursively
    await for (final entity in brickDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: brickPath);
        final targetPath = path.join(targetDirectory, relativePath);
        
        // Process template variables in file content
        final content = await entity.readAsString();
        final processedContent = _processTemplate(content, variables);
        
        // Create target file
        final targetFile = File(targetPath);
        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsString(processedContent);
        
        generatedFiles.add(GeneratedFile(targetPath, content: processedContent));
      }
    }
    
    return generatedFiles;
  }

  /// Process template variables in content
  String _processTemplate(String content, Map<String, dynamic> variables) {
    String result = content;
    
    for (final entry in variables.entries) {
      final placeholder = '{{${entry.key}}}';
      result = result.replaceAll(placeholder, entry.value.toString());
    }
    
    return result;
  }
}



/// Template variables container
class TemplateVariables {
  const TemplateVariables({
    required this.projectName,
    required this.organization,
    required this.platforms,
    this.description = '',
    this.features = const [],
  });
  
  final String projectName;
  final String organization;
  final List<String> platforms;
  final String description;
  final List<String> features;
  
  Map<String, dynamic> toMasonVars() {
    return {
      'project_name': projectName,
      'organization': organization,
      'platforms': platforms,
      'description': description,
      'features': features,
      'project_name_snake': projectName.toLowerCase().replaceAll(' ', '_'),
      'project_name_camel': _toCamelCase(projectName),
      'project_name_pascal': _toPascalCase(projectName),
    };
  }

  /// Create TemplateVariables from JSON
  factory TemplateVariables.fromJson(Map<String, dynamic> json) {
    return TemplateVariables(
      projectName: json['projectName'] as String,
      organization: json['organization'] as String,
      platforms: (json['platforms'] as List).cast<String>(),
      description: json['description'] as String? ?? '',
      features: (json['features'] as List?)?.cast<String>() ?? const [],
    );
  }
  
  String _toCamelCase(String input) {
    final words = input.toLowerCase().split(' ');
    if (words.isEmpty) return input;
    
    final firstWord = words.first;
    final otherWords = words.skip(1).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    });
    
    return '$firstWord${otherWords.join()}';
  }
  
  String _toPascalCase(String input) {
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join('');
  }
}

/// Template generation result
sealed class TemplateGenerationResult {
  const TemplateGenerationResult();
  
  const factory TemplateGenerationResult.success({
    required TemplateInfo template,
    required String targetDirectory,
    required int filesGenerated,
    required Duration duration,
  }) = TemplateGenerationSuccess;
  
  const factory TemplateGenerationResult.failure(String error) = TemplateGenerationFailure;
  
  const factory TemplateGenerationResult.dryRun({
    required TemplateInfo template,
    required String targetDirectory,
    required TemplateVariables variables,
  }) = TemplateGenerationDryRun;

  /// Create TemplateGenerationResult from JSON
  factory TemplateGenerationResult.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'success':
        return TemplateGenerationSuccess.fromJson(json);
      case 'failure':
        return TemplateGenerationFailure.fromJson(json);
      case 'dryRun':
        return TemplateGenerationDryRun.fromJson(json);
      default:
        throw ArgumentError('Unknown TemplateGenerationResult type: $type');
    }
  }
}

class TemplateGenerationSuccess extends TemplateGenerationResult {
  const TemplateGenerationSuccess({
    required this.template,
    required this.targetDirectory,
    required this.filesGenerated,
    required this.duration,
  });
  
  final TemplateInfo template;
  final String targetDirectory;
  final int filesGenerated;
  final Duration duration;

  /// Create TemplateGenerationSuccess from JSON
  factory TemplateGenerationSuccess.fromJson(Map<String, dynamic> json) {
    return TemplateGenerationSuccess(
      template: TemplateInfo.fromJson(json['template'] as Map<String, dynamic>),
      targetDirectory: json['targetDirectory'] as String,
      filesGenerated: json['filesGenerated'] as int,
      duration: Duration(milliseconds: json['duration'] as int),
    );
  }
}

class TemplateGenerationFailure extends TemplateGenerationResult {
  const TemplateGenerationFailure(this.error);
  
  final String error;

  /// Create TemplateGenerationFailure from JSON
  factory TemplateGenerationFailure.fromJson(Map<String, dynamic> json) {
    return TemplateGenerationFailure(json['error'] as String);
  }
}

class TemplateGenerationDryRun extends TemplateGenerationResult {
  const TemplateGenerationDryRun({
    required this.template,
    required this.targetDirectory,
    required this.variables,
  });
  
  final TemplateInfo template;
  final String targetDirectory;
  final TemplateVariables variables;

  /// Create TemplateGenerationDryRun from JSON
  factory TemplateGenerationDryRun.fromJson(Map<String, dynamic> json) {
    return TemplateGenerationDryRun(
      template: TemplateInfo.fromJson(json['template'] as Map<String, dynamic>),
      targetDirectory: json['targetDirectory'] as String,
      variables: TemplateVariables.fromJson(json['variables'] as Map<String, dynamic>),
    );
  }
}

/// Template validation result
class TemplateValidationResult {
  const TemplateValidationResult({
    required this.isValid,
    required this.issues,
    this.template,
  });

  factory TemplateValidationResult.failure(String error) {
    return TemplateValidationResult(
      isValid: false,
      issues: [error],
    );
  }
  
  final bool isValid;
  final List<String> issues;
  final TemplateInfo? template;
}

/// Generated file model
class GeneratedFile {
  const GeneratedFile(this.path, {this.content});
  
  final String path;
  final String? content;
}
