import 'dart:io';

import 'package:fly_cli/src/core/cache/brick_cache_manager.dart';
import 'package:fly_cli/src/core/cache/cache_models.dart';
import 'package:fly_cli/src/core/cache/sdk_version_cache.dart';
import 'package:fly_cli/src/core/cache/template_cache.dart';
import 'package:fly_cli/src/core/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/core/generation/brick/brick_registry.dart';
import 'package:fly_cli/src/core/generation/domain/entities/brick.dart' as domain;
import 'package:fly_cli/src/core/generation/domain/value_objects/brick_variable.dart' as domain;
import 'package:fly_cli/src/core/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/core/generation/generation/generation_preview.dart';
import 'package:fly_cli/src/core/generation/generators/generation_result.dart';
import 'package:fly_cli/src/core/generation/template/template_info.dart';
import 'package:fly_cli/src/core/generation/template/template_variable.dart';
import 'package:fly_cli/src/core/generation/utils/mason_variable_keys.dart';
import 'package:fly_cli/src/core/generation/variables/validation/variable_validation_service.dart';
import 'package:fly_cli/src/core/generation/versioning/compatibility_checker.dart';
import 'package:fly_cli/src/core/generation/versioning/compatibility_result.dart';
import 'package:fly_cli/src/core/generation/versioning/version_parser.dart';
import 'package:fly_cli/src/core/generation/versioning/version_registry.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';
import 'package:mason/mason.dart' as mason;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

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
    SdkVersionCache? sdkVersionCache,
  })  : _cacheManager = cacheManager ?? TemplateCacheManager(logger: logger),
        _brickCacheManager =
            brickCacheManager ?? BrickCacheManager(logger: logger),
        _brickRegistry = BrickRegistry(logger: logger),
        _previewService = GenerationPreviewService(logger: logger),
        _sdkVersionCache = sdkVersionCache ?? SdkVersionCache(logger: logger);

  static const String _defaultUnifiedTemplate = 'fly_foundation';

  /// Cached templates directory (avoids repeated directory existence checks)
  static String? _cachedTemplatesDir;

  /// Find templates directory using a single definitive path
  ///
  /// Calculates the templates directory relative to the package or executable location.
  /// For development: checks for templates in packages/fly_cli/templates
  /// For production: templates are located relative to the executable
  ///
  /// Returns the absolute path to the templates directory.
  /// Results are cached after first lookup to improve performance.
  static String findTemplatesDirectory() {
    // Return cached value if available
    if (_cachedTemplatesDir != null) {
      return _cachedTemplatesDir!;
    }

    // Check environment variable first (fastest)
    final envTemplatesDir = Platform.environment['FLY_TEMPLATES_DIR'];
    if (envTemplatesDir != null && envTemplatesDir.isNotEmpty) {
      _cachedTemplatesDir = path.normalize(envTemplatesDir);
      return _cachedTemplatesDir!;
    }

    final currentDir = Directory.current.path;

    final localTemplatesPath = path.join(currentDir, 'templates');
    if (Directory(localTemplatesPath).existsSync()) {
      _cachedTemplatesDir = path.normalize(localTemplatesPath);
      return _cachedTemplatesDir!;
    }

    final devTemplatesPath =
        path.join(currentDir, 'packages', 'fly_cli', 'templates');
    final devTemplatesDir = Directory(devTemplatesPath);
    if (devTemplatesDir.existsSync()) {
      _cachedTemplatesDir = path.normalize(devTemplatesPath);
      return _cachedTemplatesDir!;
    }

    // Try relative to script location (development)
    final scriptPath = Platform.script.toFilePath();
    final scriptDir = path.dirname(scriptPath);

    // Try multiple relative paths for development
    final scriptRelativePaths = [
      path.join(scriptDir, '..', '..', 'templates'),
      // From packages/fly_cli/bin/
      path.join(
          scriptDir, '..', '..', '..', 'packages', 'fly_cli', 'templates'),
      // From test files
      path.join(scriptDir, '..', '..', '..', '..', 'packages', 'fly_cli',
          'templates'),
      // From deeper test files
    ];

    for (final scriptRelativePath in scriptRelativePaths) {
      final normalizedPath = path.normalize(scriptRelativePath);
      final scriptRelativeDir = Directory(normalizedPath);
      if (scriptRelativeDir.existsSync()) {
        _cachedTemplatesDir = normalizedPath;
        return _cachedTemplatesDir!;
      }
    }

    // Production path: relative to executable
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);

    // Templates are located at: {executable_dir}/../templates
    _cachedTemplatesDir = path.normalize(
      path.join(executableDir, '..', 'templates'),
    );
    return _cachedTemplatesDir!;
  }

  final String templatesDirectory;
  final Logger logger;
  final TemplateCacheManager _cacheManager;
  final BrickCacheManager _brickCacheManager;
  final BrickRegistry _brickRegistry;
  final GenerationPreviewService _previewService;
  final SdkVersionCache _sdkVersionCache;

  // Versioning services (lazy initialized)
  VersionRegistry? _versionRegistry;
  CompatibilityChecker? _compatibilityChecker;

  /// Get version registry (lazy initialized)
  VersionRegistry get _versionRegistryInstance {
    _versionRegistry ??= VersionRegistry(
      templatesDirectory: templatesDirectory,
      logger: logger, // Cast to dynamic to avoid Logger type ambiguity
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

    final flutterVersion = await _sdkVersionCache.getFlutterVersion();
    final dartVersion = await _sdkVersionCache.getDartVersion();

    _compatibilityChecker = CompatibilityChecker(
      currentCliVersion: cliVersion,
      currentFlutterVersion: flutterVersion,
      currentDartVersion: dartVersion,
    );

    return _compatibilityChecker!;
  }


  /// Get all available bricks from registry
  Future<List<domain.Brick>> getAvailableBricks({BrickType? filterByType}) async {
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
  Future<domain.Brick?> getBrick(String name) async {
    try {
      return await _brickRegistry.getBrick(name);
    } catch (e) {
      logger.err('Error getting brick $name: $e');
      return null;
    }
  }

  /// Get project bricks
  Future<List<domain.Brick>> getProjectBricks() async =>
      await _brickRegistry.getProjectBricks();

  /// Get screen bricks
  Future<List<domain.Brick>> getScreenBricks() async =>
      await _brickRegistry.getScreenBricks();

  /// Get service bricks
  Future<List<domain.Brick>> getServiceBricks() async =>
      await _brickRegistry.getServiceBricks();

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
  Future<GenerationResult> generateFromBrick({
    required String brickName,
    required BrickType brickType,
    required String outputDirectory,
    required Map<String, dynamic> variables,
    bool dryRun = false,
  }) async {
    try {
      // Get brick info
      final domain.Brick? brick = await getBrick(brickName);
      if (brick == null) {
        return GenerationResult.failure(
          error: 'Brick "$brickName" not found',
          data: {'brick_name': brickName},
        );
      }

      if (brick.type != brickType) {
        return GenerationResult.failure(
          error:
              'Brick "$brickName" is of type ${brick.type.name}, expected ${brickType.name}',
          data: {
            'brick_name': brickName,
            'expected_type': brickType.name,
            'actual_type': brick.type.name,
          },
        );
      }

      // Determine generation mode from brick type
      final mode = _brickTypeToGenerationMode(brickType);

      // Validate variables using unified validation service
      final validationErrors = VariableValidationService.validateAll(
        brick: brick,
        mode: mode,
        variables: variables,
      );
      if (validationErrors.isNotEmpty) {
        return GenerationResult.failure(
          error: 'Variable validation failed: ${validationErrors.join(', ')}',
          data: {
            'validation_errors': validationErrors,
            'brick_name': brickName,
          },
        );
      }

      // Generate preview if dry run
      if (dryRun) {
        logger.warn('Generating dry run preview for brick: $brickName');
        final preview = await _previewService.generatePreview(
          brickName: brickName,
          brickType: brickType,
          outputDirectory: outputDirectory,
          variables: variables,
        );

        return GenerationResult.dryRun(
          preview: preview,
          template: _brickToTemplateInfo(brick),
        );
      }

      // Perform actual generation
      return await _performGeneration(brick, outputDirectory, variables);
    } catch (e) {
      return GenerationResult.failure(
        error: 'Generation failed: ${e.toString()}',
        data: {'brick_name': brickName},
      );
    }
  }

  /// Convert BrickType to GenerationMode
  GenerationMode? _brickTypeToGenerationMode(BrickType brickType) {
    switch (brickType) {
      case BrickType.project:
        return GenerationMode.project;
      case BrickType.feature:
        return GenerationMode.feature;
      case BrickType.service:
        return GenerationMode.service;
      default:
        return null;
    }
  }


  /// Generate preview for brick generation
  Future<GenerationPreview> generatePreview({
    required String brickName,
    required BrickType brickType,
    required String outputDirectory,
    required Map<String, dynamic> variables,
    String? projectName,
  }) async =>
      _previewService.generatePreview(
        brickName: brickName,
        brickType: brickType,
        outputDirectory: outputDirectory,
        variables: variables,
        projectName: projectName,
      );



  /// Perform actual generation using Mason
  Future<GenerationResult> _performGeneration(domain.Brick brick,
    String outputDirectory,
    Map<String, dynamic> variables,
  ) async {
    try {
      final startTime = DateTime.now();

      logger..info('Generating from brick: ${brick.name}')
      ..warn('Brick path: ${brick.path}')
      ..warn('Variables: $variables');

      // Create Brick instance from brick directory
      final brickInstance = mason.Brick.path(brick.path);
      logger.warn('Brick loaded: ${brick.path}');

      // Create MasonGenerator from brick
      final generator = await mason.MasonGenerator.fromBrick(brickInstance);
      logger.warn('Generator created successfully');

      // Create target directory
      final targetDir = Directory(outputDirectory);
      await targetDir.create(recursive: true);
      logger.warn('Target directory created: $outputDirectory');

      // Create DirectoryGeneratorTarget
      final target = mason.DirectoryGeneratorTarget(targetDir);
      logger.warn('Target created: $outputDirectory');

      // Handle feature iteration for project bricks
      // Mason doesn't automatically iterate over list variables in directory names
      if (brick.type == BrickType.project &&
          variables.containsKey(MasonVarKey.features.key)) {
        final features = variables.getVar<List<dynamic>>(MasonVarKey.features);
        if (features != null && features.isNotEmpty) {
          // Convert features to strings and remove duplicates
          final uniqueFeatures =
              features.map((f) => f.toString()).toSet().toList();

          // First, generate base project structure with first feature
          // This ensures base files are generated
          final baseVariables = Map<String, dynamic>.from(variables);
          baseVariables[MasonVarKey.feature.key] = uniqueFeatures.first;

          logger.info(
              'Generating base project structure with feature: ${uniqueFeatures.first}...');
          final baseFiles = await generator.generate(
            target,
            vars: baseVariables,
            logger: logger,
            fileConflictResolution: mason.FileConflictResolution.overwrite,
          );

          // Collect all generated files
          final allFiles = <mason.GeneratedFile>[...baseFiles];
          var totalFiles = baseFiles.length;
          logger.info('✓ Base structure generated ($totalFiles files)');

          // Then generate each additional feature separately
          // Each generation will create the {{feature}}/ directory for that feature
          if (uniqueFeatures.length > 1) {
            logger.info(
                'Generating ${uniqueFeatures.length - 1} additional feature(s)...');
            for (int i = 1; i < uniqueFeatures.length; i++) {
              final featureName = uniqueFeatures[i];
              logger.warn('Generating feature: $featureName');

              final featureVariables = Map<String, dynamic>.from(variables);
              featureVariables[MasonVarKey.feature.key] = featureName;

              // Generate with this feature - Mason will create {{feature}}/ directory
              final featureFiles = await generator.generate(
                target,
                vars: featureVariables,
                logger: logger,
                fileConflictResolution: mason.FileConflictResolution.overwrite,
              );

              // Add feature files to the collection
              allFiles.addAll(featureFiles);
              totalFiles += featureFiles.length;
              logger.warn(
                  '✓ Feature "$featureName" generated (${featureFiles.length} files)');
            }
          }

          logger.info(
              '✓ Generation successful ($totalFiles total files generated)');
          logger.info('Generated features: ${uniqueFeatures.join(', ')}');

          final endTime = DateTime.now();
          final duration = endTime.difference(startTime);

          logger.info('Generation completed in ${duration.inMilliseconds}ms');

          return GenerationResult.success(
            files: allFiles,
            targetDirectory: outputDirectory,
            template: _brickToTemplateInfo(brick),
            duration: duration,
          );
        }
      }

      // Standard generation for non-project bricks or projects without features
      final generatedFiles = await generator.generate(
        target,
        vars: variables,
        logger: logger, // Cast to dynamic to avoid Logger type ambiguity
        fileConflictResolution: mason.FileConflictResolution.overwrite,
      );

      final fileCount = generatedFiles.length;
      logger.info('✓ Generation successful ($fileCount files generated)');

      // Debug: Log generated files
      // Note: Verbose logging removed as CLI Logger doesn't have level property

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      logger.info('Generation completed in ${duration.inMilliseconds}ms');

      // Use Mason's GeneratedFile directly
      final files = generatedFiles;

      return GenerationResult.success(
        files: files,
        targetDirectory: outputDirectory,
        template: _brickToTemplateInfo(brick),
        duration: duration,
      );
    } on mason.MasonException catch (e) {
      logger.err('Mason generation error: $e');
      return GenerationResult.failure(
        error: 'Mason generation failed: ${e.message}',
        data: {'brick_name': brick.name},
      );
    } on FileSystemException catch (e) {
      logger.err('File system error: $e');
      return GenerationResult.failure(
        error: 'File system error: ${e.message}',
        data: {'brick_name': brick.name},
      );
    } catch (e, stackTrace) {
      logger.err('Unexpected error: $e');
      logger.warn(stackTrace.toString());
      return GenerationResult.failure(
        error: 'Generation failed: $e',
        data: {'brick_name': brick.name},
      );
    }
  }

  /// Convert Brick to TemplateInfo
  ///
  /// Creates TemplateInfo from Brick for result types.
  TemplateInfo _brickToTemplateInfo(domain.Brick brick) {
    // Convert BrickVariable to TemplateVariable
    final templateVariables = brick.variables.values
        .map<TemplateVariable>((domain.BrickVariable brickVar) => TemplateVariable(
              name: brickVar.name,
              type: brickVar.type,
              required: brickVar.required,
              defaultValue: brickVar.defaultValue,
              choices: brickVar.choices,
              description: brickVar.description,
            ))
        .toList();

    return TemplateInfo(
      name: brick.name,
      version: brick.version.toString(),
      description: brick.description,
      path: brick.path,
      minFlutterSdk: brick.minFlutterSdk?.toString() ?? '3.10.0',
      minDartSdk: brick.minDartSdk?.toString() ?? '3.0.0',
      variables: templateVariables,
      features: brick.features,
      packages: brick.packages,
    );
  }

  /// Get all available templates
  ///
  /// Discovers templates from the brick registry and converts them to templates.
  /// All templates are now stored as bricks in the bricks/ directory.
  /// Each template includes compatibility data if specified in brick.yaml.
  Future<List<TemplateInfo>> getAvailableTemplates() async {
    final templates = <TemplateInfo>[];

    try {
      // Discover bricks and convert them to templates
      final bricks = await getAvailableBricks();
      for (final brick in bricks) {
        // Only include project bricks as templates (for project generation)
        // Feature and service bricks are handled separately
        if (brick.type == BrickType.project) {
          final templateInfo = _brickToTemplateInfo(brick);
          templates.add(templateInfo);
        }
      }
    } catch (e) {
      logger.err('Error discovering templates: $e');
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
        final versionedTemplate =
            await _versionRegistryInstance.getTemplateVersion(name, version);
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

      // Load from bricks (templates are now stored as bricks)
      TemplateInfo? template;

      try {
        final brick = await getBrick(name);
        if (brick != null && brick.type == BrickType.project) {
          template = _brickToTemplateInfo(brick);
          logger.info('Found template "$name" as brick');
        }
      } catch (e) {
        logger.warn('Error checking for brick "$name": $e');
        // Don't fail if brick lookup fails
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
          final compatibilityResult =
              checker.checkTemplateCompatibility(template);

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
        result =
            result.replaceAll(placeholder, (entry.value as List).join(', '));
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


/// Template validation result
class TemplateValidationResult {
  const TemplateValidationResult({
    required this.isValid,
    required this.issues,
    this.template,
  });

  factory TemplateValidationResult.failure(String error) =>
      TemplateValidationResult(
        isValid: false,
        issues: [error],
      );

  final bool isValid;
  final List<String> issues;
  final TemplateInfo? template;
}

