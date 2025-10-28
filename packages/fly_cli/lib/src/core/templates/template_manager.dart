import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'package:fly_cli/src/core/cache/brick_cache_manager.dart';
import 'package:fly_cli/src/core/cache/cache_models.dart';
import 'package:fly_cli/src/core/cache/template_cache.dart';
import 'brick_registry.dart';
import 'generation_preview.dart';
import 'models/brick_info.dart';
import 'models/template_info.dart';
import 'models/template_variable.dart';

/// Enhanced template management system for Fly CLI
/// 
/// Handles template discovery, validation, and generation using Mason bricks.
/// Integrates with brick registry, caching, and comprehensive error handling.
class TemplateManager {
  TemplateManager({
    required this.templatesDirectory,
    required this.logger,
    TemplateCacheManager? cacheManager,
    BrickCacheManager? brickCacheManager,
  })  : _cacheManager = cacheManager ?? TemplateCacheManager(logger: logger),
        _brickCacheManager =
            brickCacheManager ?? BrickCacheManager(logger: logger),
        _brickRegistry = BrickRegistry(logger: logger),
        _previewService = GenerationPreviewService(logger: logger);

  final String templatesDirectory;
  final Logger logger;
  final TemplateCacheManager _cacheManager;
  final BrickCacheManager _brickCacheManager;
  final BrickRegistry _brickRegistry;
  final GenerationPreviewService _previewService;

  /// Get all available bricks from registry
  Future<List<BrickInfo>> getAvailableBricks({BrickType? filterByType}) async {
    try {
      final bricks = await _brickRegistry.discoverBricks();

      if (filterByType != null) {
        return bricks.where((brick) => brick.type == filterByType).toList();
      }

      return bricks;
    } catch (e) {
      logger.err('Error discovering bricks: $e');
      return [];
    }
  }

  /// Get brick by name
  Future<BrickInfo?> getBrick(String name) async {
    try {
      return await _brickRegistry.getBrick(name);
    } catch (e) {
      logger.err('Error getting brick $name: $e');
      return null;
    }
  }

  /// Get project bricks
  Future<List<BrickInfo>> getProjectBricks() async => await _brickRegistry.getProjectBricks();

  /// Get screen bricks
  Future<List<BrickInfo>> getScreenBricks() async => await _brickRegistry.getScreenBricks();

  /// Get service bricks
  Future<List<BrickInfo>> getServiceBricks() async => await _brickRegistry.getServiceBricks();

  /// Validate brick
  Future<BrickValidationResult> validateBrick(String brickName) async {
    try {
      return await _brickRegistry.validateBrickByName(brickName);
    } catch (e) {
      logger.err('Error validating brick $brickName: $e');
      return BrickValidationResult.failure(['Validation error: $e']);
    }
  }

  /// Generate from any brick type
  Future<TemplateGenerationResult> generateFromBrick({
    required String brickName,
    required BrickType brickType,
    required String outputDirectory,
    required Map<String, dynamic> variables,
    bool dryRun = false,
  }) async {
    try {
      // Get brick info
      final brick = await getBrick(brickName);
      if (brick == null) {
        return TemplateGenerationResult.failure('Brick "$brickName" not found');
      }

      if (brick.type != brickType) {
        return TemplateGenerationResult.failure(
          'Brick "$brickName" is of type ${brick.type.name}, expected ${brickType.name}',
        );
      }

      // Validate variables
      final validationErrors = await _validateVariables(brick, variables);
      if (validationErrors.isNotEmpty) {
        return TemplateGenerationResult.failure(
          'Variable validation failed: ${validationErrors.join(', ')}',
        );
      }

      // Generate preview if dry run
      if (dryRun) {
        logger.detail('Generating dry run preview for brick: $brickName');
        final preview = await _previewService.generatePreview(
          brickName: brickName,
          brickType: brickType,
          outputDirectory: outputDirectory,
          variables: variables,
        );

        return TemplateGenerationResult.dryRun(
          template: _brickToTemplateInfo(brick),
          targetDirectory: preview.targetDirectory,
          variables: TemplateVariables.fromJson(variables),
        );
      }

      // Perform actual generation
      return await _performGeneration(brick, outputDirectory, variables);
    } catch (e) {
      return TemplateGenerationResult.failure(
        'Generation failed: ${e.toString()}',
      );
    }
  }

  /// Generate component (screen/service)
  Future<TemplateGenerationResult> generateComponent({
    required String componentName,
    required BrickType componentType,
    required Map<String, dynamic> config,
    String? targetPath,
  }) async {
    try {
      // Determine brick name based on component type
      String brickName;
      switch (componentType) {
        case BrickType.screen:
          brickName = 'fly_screen';

        case BrickType.service:
          brickName = 'fly_service';

        case BrickType.project:
        case BrickType.component:
        case BrickType.custom:
          return TemplateGenerationResult.failure(
            'Unsupported component type: ${componentType.name}',
          );
      }

      // Get target path
      final outputDir = targetPath ?? Directory.current.path;

      // Generate using the appropriate brick
      return await generateFromBrick(
        brickName: brickName,
        brickType: componentType,
        outputDirectory: outputDir,
        variables: config,
      );
    } catch (e) {
      return TemplateGenerationResult.failure(
        'Component generation failed: ${e.toString()}',
      );
    }
  }

  /// Generate preview for brick generation
  Future<GenerationPreview> generatePreview({
    required String brickName,
    required BrickType brickType,
    required String outputDirectory,
    required Map<String, dynamic> variables,
    String? projectName,
  }) async => _previewService.generatePreview(
      brickName: brickName,
      brickType: brickType,
      outputDirectory: outputDirectory,
      variables: variables,
    );

  /// Generate project using enhanced brick system
  Future<TemplateGenerationResult> generateProject({
    required String templateName,
    required String projectName,
    required String outputDirectory,
    required TemplateVariables variables,
    bool dryRun = false,
  }) async {
    try {
      // Convert TemplateVariables to Map
      final variablesMap = variables.toMasonVars();

      // Use the new generateFromBrick method
      return await generateFromBrick(
        brickName: templateName,
        brickType: BrickType.project,
        outputDirectory: outputDirectory,
        variables: variablesMap,
        dryRun: dryRun,
      );
    } catch (e) {
      return TemplateGenerationResult.failure(
        'Project generation failed: ${e.toString()}',
      );
    }
  }

  /// Validate variables against brick requirements
  Future<List<String>> _validateVariables(
      BrickInfo brick, Map<String, dynamic> variables) async {
    final errors = <String>[];

    // Check required variables
    for (final requiredVar in brick.requiredVariables) {
      if (!variables.containsKey(requiredVar.name)) {
        errors.add('Required variable "${requiredVar.name}" is missing');
      }
    }

    // Validate variable types and values
    for (final entry in variables.entries) {
      final variableName = entry.key;
      final value = entry.value;
      final brickVar = brick.getVariable(variableName);

      if (brickVar != null) {
        // Check if value matches expected type
        if (brickVar.type == 'list' && value is! List) {
          errors.add('Variable "$variableName" should be a list');
        } else if (brickVar.type == 'bool' && value is! bool) {
          errors.add('Variable "$variableName" should be a boolean');
        } else if (brickVar.type == 'string' && value is! String) {
          errors.add('Variable "$variableName" should be a string');
        }

        // Check choices if specified
        if (brickVar.choices != null && brickVar.choices!.isNotEmpty) {
          if (value is String && !brickVar.choices!.contains(value)) {
            errors.add(
                'Variable "$variableName" value "$value" is not in allowed choices: ${brickVar.choices!.join(', ')}');
          }
        }
      }
    }

    return errors;
  }

  /// Perform actual generation using Mason
  Future<TemplateGenerationResult> _performGeneration(
    BrickInfo brick,
    String outputDirectory,
    Map<String, dynamic> variables,
  ) async {
    try {
      final startTime = DateTime.now();

      logger.info('Generating from brick: ${brick.name}');
      logger.detail('Brick path: ${brick.path}');
      logger.detail('Variables: $variables');

      // Create Brick instance from brick directory
      final brickInstance = Brick.path(brick.path);
      logger.detail('Brick loaded: ${brick.path}');

      // Create MasonGenerator from brick
      final generator = await MasonGenerator.fromBrick(brickInstance);
      logger.detail('Generator created successfully');

      // Create target directory
      final targetDir = Directory(outputDirectory);
      await targetDir.create(recursive: true);
      logger.detail('Target directory created: $outputDirectory');

      // Create DirectoryGeneratorTarget
      final target = DirectoryGeneratorTarget(targetDir);
      logger.detail('Target created: $outputDirectory');

      // Generate using Mason API
      final generatedFiles = await generator.generate(
        target,
        vars: variables,
        logger: logger,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      final fileCount = generatedFiles.length;
      logger.info('✓ Generation successful ($fileCount files generated)');

      // Debug: Log generated files
      if (logger.level == Level.verbose) {
        for (final file in generatedFiles) {
          logger.detail('Generated: ${file.path}');
        }
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      logger.info('Generation completed in ${duration.inMilliseconds}ms');

      return TemplateGenerationResult.success(
        template: _brickToTemplateInfo(brick),
        targetDirectory: outputDirectory,
        filesGenerated: fileCount,
        duration: duration,
      );
    } on MasonException catch (e) {
      logger.err('Mason generation error: $e');
      return TemplateGenerationResult.failure(
          'Mason generation failed: ${e.message}');
    } on FileSystemException catch (e) {
      logger.err('File system error: $e');
      return TemplateGenerationResult.failure(
          'File system error: ${e.message}');
    } catch (e, stackTrace) {
      logger.err('Unexpected error: $e');
      logger.detail(stackTrace.toString());
      return TemplateGenerationResult.failure('Generation failed: $e');
    }
  }

  /// Convert BrickInfo to TemplateInfo for backward compatibility
  TemplateInfo _brickToTemplateInfo(BrickInfo brick) {
    // Convert BrickVariable to TemplateVariable
    final templateVariables = brick.variables.values.map((brickVar) => TemplateVariable(
        name: brickVar.name,
        type: brickVar.type,
        required: brickVar.required,
        defaultValue: brickVar.defaultValue,
        choices: brickVar.choices,
        description: brickVar.description,
      )).toList();

    return TemplateInfo(
      name: brick.name,
      version: brick.version,
      description: brick.description,
      path: brick.path,
      minFlutterSdk: brick.minFlutterSdk,
      minDartSdk: brick.minDartSdk,
      variables: templateVariables,
      features: brick.features,
      packages: brick.packages,
    );
  }

  /// Get all available templates (legacy method for backward compatibility)
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
  
  /// Validate template
  Future<TemplateValidationResult> validateTemplate(String templateName) async {
    try {
      final template = await getTemplate(templateName);
      if (template == null) {
        return TemplateValidationResult.failure(
          'Template "$templateName" not found',
        );
      }
      
      // Validate brick structure
      final issues = <String>[];
      
      // Note: Brick validation will be enhanced once Mason API access to brick files is available
      
      // Check template metadata by reading the original YAML file
      final templatePath = path.join(templatesDirectory, templateName);
      final templateYamlPath = path.join(templatePath, 'template.yaml');
      final templateYamlFile = File(templateYamlPath);
      
      if (await templateYamlFile.exists()) {
        try {
          final yamlContent = await templateYamlFile.readAsString();
          final yaml = loadYaml(yamlContent) as Map<dynamic, dynamic>;
          
          // Check if description is missing or empty in original YAML
          final description = yaml['description'] as String?;
          if (description == null || description.trim().isEmpty) {
            issues.add('Missing template description');
          }
          
          // Check if version is missing or empty in original YAML
          final version = yaml['version'] as String?;
          if (version == null || version.trim().isEmpty) {
            issues.add('Missing template version');
          }
        } catch (e) {
          issues.add('Invalid template.yaml format: $e');
        }
      } else {
        issues.add('template.yaml file not found');
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

  /// Generate project files using fallback method (simple file copying)
  Future<void> _generateProjectFilesFallback(
    String brickPath,
    String targetDirectory,
    Map<String, dynamic> variables,
  ) async {
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
      }
    }
  }

  /// Process template variables in content
  String _processTemplate(String content, Map<String, dynamic> variables) {
    var result = content;
    
    for (final entry in variables.entries) {
      final placeholder = '{{${entry.key}}}';
      // Handle list variables
      if (entry.value is List) {
        result = result.replaceAll(placeholder, (entry.value as List).join(', '));
      } else {
        result = result.replaceAll(placeholder, entry.value.toString());
      }
    }
    
    return result;
  }
  
  /// Clear template cache
  Future<void> clearTemplateCache() async {
    await _cacheManager.clearCache();
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

  /// Create TemplateVariables from JSON
  factory TemplateVariables.fromJson(Map<String, dynamic> json) => TemplateVariables(
      projectName: json['projectName'] as String? ?? json['project_name'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
      platforms: (json['platforms'] as List?)?.cast<String>() ?? const [],
      description: json['description'] as String? ?? '',
      features: (json['features'] as List?)?.cast<String>() ?? const [],
    );
  
  final String projectName;
  final String organization;
  final List<String> platforms;
  final String description;
  final List<String> features;
  
  Map<String, dynamic> toMasonVars() => {
      'project_name': projectName,
      'organization': organization,
      'platforms': platforms,
      'description': description,
      'features': features,
      'project_name_snake': projectName.toLowerCase().replaceAll(' ', '_'),
      'project_name_camel': _toCamelCase(projectName),
      'project_name_pascal': _toPascalCase(projectName),
    };
  
  String _toCamelCase(String input) {
    // Convert to camelCase: "My App" -> "myApp", "test_mason" -> "testMason"
    final words = input.split(RegExp(r'[\s_-]')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return input.toLowerCase();
    
    final firstWord = words.first.toLowerCase();
    final otherWords = words.skip(1).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });
    
    return '$firstWord${otherWords.join()}';
  }
  
  String _toPascalCase(String input) {
    // Convert to PascalCase: "My App" -> "MyApp", "test_mason" -> "TestMason"
    final words = input.split(RegExp(r'[\s_-]')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return input;
    
    return words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();
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

  /// Create TemplateGenerationSuccess from JSON
  factory TemplateGenerationSuccess.fromJson(Map<String, dynamic> json) => TemplateGenerationSuccess(
      template: TemplateInfo.fromJson(json['template'] as Map<String, dynamic>),
      targetDirectory: json['targetDirectory'] as String,
      filesGenerated: json['filesGenerated'] as int,
      duration: Duration(milliseconds: json['duration'] as int),
    );
  
  final TemplateInfo template;
  final String targetDirectory;
  final int filesGenerated;
  final Duration duration;
}

class TemplateGenerationFailure extends TemplateGenerationResult {
  const TemplateGenerationFailure(this.error);

  /// Create TemplateGenerationFailure from JSON
  factory TemplateGenerationFailure.fromJson(Map<String, dynamic> json) => TemplateGenerationFailure(json['error'] as String);
  
  final String error;
}

class TemplateGenerationDryRun extends TemplateGenerationResult {
  const TemplateGenerationDryRun({
    required this.template,
    required this.targetDirectory,
    required this.variables,
  });

  /// Create TemplateGenerationDryRun from JSON
  factory TemplateGenerationDryRun.fromJson(Map<String, dynamic> json) => TemplateGenerationDryRun(
      template: TemplateInfo.fromJson(json['template'] as Map<String, dynamic>),
      targetDirectory: json['targetDirectory'] as String,
      variables: TemplateVariables.fromJson(json['variables'] as Map<String, dynamic>),
    );
  
  final TemplateInfo template;
  final String targetDirectory;
  final TemplateVariables variables;
}

/// Template validation result
class TemplateValidationResult {
  const TemplateValidationResult({
    required this.isValid,
    required this.issues,
    this.template,
  });

  factory TemplateValidationResult.failure(String error) => TemplateValidationResult(
      isValid: false,
      issues: [error],
    );
  
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
