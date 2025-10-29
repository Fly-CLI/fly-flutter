import 'dart:io';

import 'package:fly_cli/src/core/cache/brick_cache_manager.dart';
import 'package:fly_cli/src/core/cache/cache_models.dart';
import 'package:fly_cli/src/core/cache/template_cache.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'brick_registry.dart';
import 'generation_preview.dart';
import 'models/brick_info.dart';
import 'models/template_info.dart';
import 'models/template_variable.dart';
import 'versioning/models/compatibility_result.dart';
import 'versioning/services/compatibility_checker.dart';
import 'versioning/services/version_registry.dart';
import 'versioning/utils/version_parser.dart';

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

  /// Find templates directory using a single definitive path
  /// 
  /// Calculates the templates directory relative to the package or executable location.
  /// For development: checks for templates in packages/fly_cli/templates
  /// For production: templates are located relative to the executable
  /// 
  /// Returns the absolute path to the templates directory.
  static String findTemplatesDirectory() {
    // Try development path: packages/fly_cli/templates
    // This works when running from the monorepo
    final currentDir = Directory.current.path;
    final devTemplatesPath = path.join(currentDir, 'packages', 'fly_cli', 'templates');
    final devTemplatesDir = Directory(devTemplatesPath);
    if (devTemplatesDir.existsSync()) {
      return path.normalize(devTemplatesPath);
    }

    // Try relative to script location (development)
    final scriptPath = Platform.script.toFilePath();
    final scriptDir = path.dirname(scriptPath);
    
    // Try multiple relative paths for development
    final scriptRelativePaths = [
      path.join(scriptDir, '..', '..', 'templates'), // From packages/fly_cli/bin/
      path.join(scriptDir, '..', '..', '..', 'packages', 'fly_cli', 'templates'), // From test files
      path.join(scriptDir, '..', '..', '..', '..', 'packages', 'fly_cli', 'templates'), // From deeper test files
    ];
    
    for (final scriptRelativePath in scriptRelativePaths) {
      final normalizedPath = path.normalize(scriptRelativePath);
      final scriptRelativeDir = Directory(normalizedPath);
      if (scriptRelativeDir.existsSync()) {
        return normalizedPath;
      }
    }

    // Production path: relative to executable
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);
    
    // Templates are located at: {executable_dir}/../templates
    return path.normalize(
      path.join(executableDir, '..', 'templates'),
    );
  }

  final String templatesDirectory;
  final Logger logger;
  final TemplateCacheManager _cacheManager;
  final BrickCacheManager _brickCacheManager;
  final BrickRegistry _brickRegistry;
  final GenerationPreviewService _previewService;

  // Versioning services (lazy initialized)
  VersionRegistry? _versionRegistry;
  CompatibilityChecker? _compatibilityChecker;

  /// Get version registry (lazy initialized)
  VersionRegistry get _versionRegistryInstance {
    _versionRegistry ??= VersionRegistry(
      templatesDirectory: templatesDirectory,
      logger: logger,
      loadTemplateInfo: _loadTemplateInfo,
    );
    return _versionRegistry!;
  }

  /// Get compatibility checker (lazy initialized)
  Future<CompatibilityChecker> get _compatibilityCheckerInstance async {
    if (_compatibilityChecker != null) return _compatibilityChecker!;

    // Get current versions with validation
    Version cliVersion;
    try {
      final cliVersionStr = VersionUtils.getCurrentVersion();
      cliVersion = Version.parse(cliVersionStr);
    } catch (e) {
      logger.warn('Failed to parse CLI version, using default: $e');
      cliVersion = Version.parse('1.0.0'); // Safe default
    }

    final flutterVersion = await _getFlutterVersion();
    final dartVersion = await _getDartVersion();

    _compatibilityChecker = CompatibilityChecker(
      currentCliVersion: cliVersion,
      currentFlutterVersion: flutterVersion,
      currentDartVersion: dartVersion,
    );

    return _compatibilityChecker!;
  }

  /// Get Flutter SDK version
  /// 
  /// Returns a valid Version object. Falls back to safe default if detection fails.
  Future<Version> _getFlutterVersion() async {
    try {
      final result = await Process.run(
          'flutter', ['--version'], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final match = RegExp(r'Flutter (\d+\.\d+\.\d+)').firstMatch(output);
        if (match != null) {
          final versionStr = match.group(1)!;
          try {
            return Version.parse(versionStr);
          } catch (e) {
            logger.warn('Invalid Flutter version format: $versionStr');
          }
        }
      }
    } catch (e) {
      logger.warn('Failed to detect Flutter version: $e');
    }
    // Safe default
    return Version.parse('3.10.0');
  }

  /// Get Dart SDK version
  /// 
  /// Returns a valid Version object. Falls back to safe default if detection fails.
  Future<Version> _getDartVersion() async {
    try {
      final result = await Process.run('dart', ['--version'], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final match = RegExp(r'Dart SDK version: (\d+\.\d+\.\d+)').firstMatch(
            output);
        if (match != null) {
          final versionStr = match.group(1)!;
          try {
            return Version.parse(versionStr);
          } catch (e) {
            logger.warn('Invalid Dart version format: $versionStr');
          }
        }
      }
    } catch (e) {
      logger.warn('Failed to detect Dart version: $e');
    }
    // Safe default
    return Version.parse('3.0.0');
  }

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
      projectName: projectName,
    );

  /// Generate project using enhanced brick system with compatibility checking
  Future<TemplateGenerationResult> generateProject({
    required String templateName,
    required String projectName,
    required String outputDirectory,
    required TemplateVariables variables,
    bool dryRun = false,
    String? version,
  }) async {
    try {
      // Get template (with optional version)
      final template = await getTemplate(templateName, version: version);
      if (template == null) {
        return TemplateGenerationResult.failure(
          'Template "$templateName"${version != null
              ? "@$version"
              : ""} not found',
        );
      }

      // Check compatibility before generation
      final checker = await _compatibilityCheckerInstance;
      final compatibilityResult = checker.checkTemplateCompatibility(template);

      if (compatibilityResult.isIncompatible) {
        final errorMessage = compatibilityResult.errors.join('\n');
        return TemplateGenerationResult.failure(
          'Template compatibility check failed:\n$errorMessage',
        );
      }

      // Show warnings if any
      for (final warning in compatibilityResult.warnings) {
        logger.warn('⚠️  $warning');
      }

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

  /// Convert BrickInfo to TemplateInfo
  /// 
  /// Creates TemplateInfo from BrickInfo for result types.
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

  /// Get all available templates
  /// 
  /// Discovers and loads all templates from the templates directory.
  /// Searches in projects/ and components/ subdirectories.
  /// Each template includes compatibility data if specified in template.yaml.
  Future<List<TemplateInfo>> getAvailableTemplates() async {
    final templates = <TemplateInfo>[];
    
    try {
      final dir = Directory(templatesDirectory);
      if (!await dir.exists()) {
        logger.warn('Templates directory does not exist: $templatesDirectory');
        return templates;
      }
      
      // Search in projects/ and components/ subdirectories
      final projectsDir = Directory(path.join(templatesDirectory, 'projects'));
      if (await projectsDir.exists()) {
        await for (final entity in projectsDir.list()) {
          if (entity is Directory) {
            final templateInfo = await _loadTemplateInfo(entity.path);
            if (templateInfo != null) {
              templates.add(templateInfo);
            }
          }
        }
      }
      
      final componentsDir = Directory(path.join(templatesDirectory, 'components'));
      if (await componentsDir.exists()) {
        await for (final entity in componentsDir.list()) {
          if (entity is Directory) {
            final templateInfo = await _loadTemplateInfo(entity.path);
            if (templateInfo != null) {
              templates.add(templateInfo);
            }
          }
        }
      }
      
      // Fallback: check flat structure (for test compatibility and backward compatibility)
      // Only check if no subdirectories were found or if subdirectories don't exist
      if (templates.isEmpty || (!await projectsDir.exists() && !await componentsDir.exists())) {
        await for (final entity in dir.list()) {
          if (entity is Directory) {
            final entityName = path.basename(entity.path);
            // Skip known subdirectories to avoid duplicates
            if (entityName != 'projects' && entityName != 'components') {
              final templateInfo = await _loadTemplateInfo(entity.path);
              if (templateInfo != null) {
                templates.add(templateInfo);
              }
            }
          }
        }
      }
    } catch (e) {
      logger.err('Error loading templates: $e');
    }
    
    return templates;
  }

  /// Get template by name and optional version
  /// 
  /// If version is provided, attempts to load that specific version.
  /// Otherwise, loads the default/latest version.
  Future<TemplateInfo?> getTemplate(String name, {String? version}) async {
    try {
      // If version specified, use version registry
      if (version != null) {
        final versionedTemplate = await _versionRegistryInstance
            .getTemplateVersion(name, version);
        if (versionedTemplate != null) {
          return versionedTemplate;
        }
        // Don't fall back silently - this could be confusing
        logger.warn(
          'Template version "$name@$version" not found. '
          'Available versions: ${await _versionRegistryInstance.getVersions(name)}. '
          'Falling back to default template.',
        );
      }

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

      // Load from source - search in subdirectories, then flat structure
      TemplateInfo? template;
      
      // Try projects subdirectory first
      final projectsPath = path.join(templatesDirectory, 'projects', name);
      if (await Directory(projectsPath).exists()) {
        template = await _loadTemplateInfo(projectsPath);
      } else {
        // Try components subdirectory
        final componentsPath = path.join(templatesDirectory, 'components', name);
        if (await Directory(componentsPath).exists()) {
          template = await _loadTemplateInfo(componentsPath);
        } else {
          // Fallback: check flat structure (for test compatibility)
          final directPath = path.join(templatesDirectory, name);
          if (await Directory(directPath).exists()) {
            template = await _loadTemplateInfo(directPath);
          }
        }
      }

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

  /// Load TemplateInfo from cache
  /// 
  /// Deserializes TemplateInfo from cached JSON data.
  /// Compatibility data is automatically loaded if present.
  TemplateInfo _templateFromCache(CachedTemplate cachedTemplate) {
    final data = cachedTemplate.templateData;
    // TemplateInfo.fromJson automatically handles compatibility field if present
    return TemplateInfo.fromJson(data);
  }

  /// Validate template with compatibility checking
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
      
      // Check template metadata by reading the original YAML file
      // template.path points to __brick__ subdirectory, but template.yaml is in parent
      final brickPath = template.path;
      final templatePath = path.dirname(brickPath);
      
      // Try template.yaml in the template directory (parent of __brick__)
      var templateYamlPath = path.join(templatePath, 'template.yaml');
      var templateYamlFile = File(templateYamlPath);
      
      // If not found, try in brick path (for backward compatibility)
      if (!await templateYamlFile.exists()) {
        templateYamlPath = path.join(brickPath, 'template.yaml');
        templateYamlFile = File(templateYamlPath);
      }
      
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
          } else {
            // Validate version format
            if (VersionParser.parseTemplateVersion(version) == null) {
              issues.add(
                  'Invalid version format: "$version". Expected SemVer format (MAJOR.MINOR.PATCH)');
            }
          }

          // Check compatibility using template's compatibility data
          final checker = await _compatibilityCheckerInstance;
          final compatibilityResult = checker.checkTemplateCompatibility(template);

          if (compatibilityResult.isIncompatible) {
            issues.addAll(compatibilityResult.errors);
          }

          // Add warnings as issues (non-blocking)
          for (final warning in compatibilityResult.warnings) {
            logger.warn('Template compatibility warning: $warning');
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

  /// Load template information from directory with compatibility parsing
  /// 
  /// Parses template.yaml and creates TemplateInfo with optional compatibility data.
  /// The compatibility field is populated when compatibility section exists in YAML.
  /// Compatibility parsing is handled by TemplateInfo.fromYaml internally.
  /// 
  /// Returns null if template.yaml is missing or invalid.
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
      
      // TemplateInfo.fromYaml now handles compatibility parsing internally
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

  /// Get all available versions for a template
  Future<List<String>> getTemplateVersions(String templateName) async {
    return await _versionRegistryInstance.getVersions(templateName);
  }

  /// Get latest version of a template
  Future<String?> getLatestTemplateVersion(String templateName) async {
    return await _versionRegistryInstance.getLatestVersion(templateName);
  }

  /// Check template compatibility using full compatibility data
  /// 
  /// Uses TemplateInfo.compatibility for full checks (CLI, SDK, deprecation, EOL).
  /// If compatibility data is not available, returns compatible (no constraints).
  Future<CompatibilityResult> checkTemplateCompatibility(
      String templateName) async {
    final template = await getTemplate(templateName);
    if (template == null) {
      return CompatibilityResult.incompatible(
        errors: ['Template "$templateName" not found'],
      );
    }

    final checker = await _compatibilityCheckerInstance;
    return checker.checkTemplateCompatibility(template);
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
