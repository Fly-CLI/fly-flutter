import 'dart:io';

import 'package:fly_cli/src/features/context/domain/models/models.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/base/analyzer_interface.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/base/utils.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/enhanced/architecture_detector.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/unified/directory_analyzer.dart';
import 'package:path/path.dart' as path;

/// Unified project analyzer that combines all analysis functionality
class UnifiedProjectAnalyzer extends ProjectAnalyzer<ProjectInfo> {
  UnifiedProjectAnalyzer();

  @override
  String get name => 'unified-project';

  @override
  int get priority => 5; // Highest priority

  @override
  Future<ProjectInfo> analyze(
    Directory projectDir,
    ContextGeneratorConfig config,
  ) async {
    try {
      final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
      if (!await pubspecFile.exists()) {
        throw AnalyzerException(
          'Not a Flutter project: pubspec.yaml not found',
        );
      }

      // Analyze pubspec.yaml with retry logic
      final pubspecInfo = await RetryUtils.retry(() async {
        final content = await FileUtils.readFile(pubspecFile);
        if (content == null) {
          throw Exception('Failed to read pubspec.yaml');
        }
        return _parsePubspec(content);
      });

      // Check for Fly manifest
      final manifestInfo = await _analyzeManifest(projectDir);

      // Determine project type
      final isFlyProject = manifestInfo != null || _isFlyProject(pubspecInfo);
      final projectType = isFlyProject ? 'fly' : 'flutter';

      return ProjectInfo(
        name: pubspecInfo.name,
        type: projectType,
        version: pubspecInfo.version,
        template: manifestInfo?.template,
        organization: manifestInfo?.organization,
        description: pubspecInfo.description,
        platforms: manifestInfo?.platforms ?? _extractPlatforms(pubspecInfo),
        flutterVersion: pubspecInfo.environment?['flutter'],
        dartVersion: pubspecInfo.environment?['sdk'],
        isFlyProject: isFlyProject,
        hasManifest: manifestInfo != null,
        creationDate: await _getCreationDate(projectDir),
      );
    } catch (e) {
      return ErrorHandler.handleAnalyzerError(
        name,
        e,
        defaultValue: const ProjectInfo(
          name: 'unknown',
          type: 'flutter',
          version: '0.0.0',
        ),
      );
    }
  }

  /// Parse pubspec.yaml content
  PubspecInfo _parsePubspec(String content) {
    // Simplified pubspec parsing - in real implementation would use pubspec_parse
    final lines = content.split('\n');
    String name = 'unknown';
    String version = '0.0.0';
    String? description;

    for (final line in lines) {
      if (line.trim().startsWith('name:')) {
        name = line.split(':')[1].trim();
      } else if (line.trim().startsWith('version:')) {
        version = line.split(':')[1].trim();
      } else if (line.trim().startsWith('description:')) {
        description = line.split(':')[1].trim();
      }
    }

    return PubspecInfo(name: name, version: version, description: description);
  }

  /// Analyze Fly manifest if present
  Future<ManifestInfo?> _analyzeManifest(Directory projectDir) async {
    final manifestFile = File(path.join(projectDir.path, 'fly_project.yaml'));
    if (!await manifestFile.exists()) {
      return null;
    }

    try {
      final content = await FileUtils.readFile(manifestFile);
      if (content == null) return null;

      // Simplified manifest parsing
      return ManifestInfo(
        name: 'fly_project',
        template: 'riverpod',
        organization: 'unknown',
        description: 'Fly project',
        platforms: const ['ios', 'android'],
        screens: const [],
        services: const [],
        packages: const [],
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if project uses Fly packages
  bool _isFlyProject(PubspecInfo pubspecInfo) {
    // Simplified check - would need actual dependency parsing
    return false;
  }

  /// Extract platforms from pubspec
  List<String> _extractPlatforms(PubspecInfo pubspecInfo) {
    return const ['ios', 'android'];
  }

  /// Get project creation date
  Future<DateTime?> _getCreationDate(Directory projectDir) async {
    try {
      final stat = await projectDir.stat();
      return stat.changed;
    } catch (e) {
      return null;
    }
  }
}

/// Unified structure analyzer
class UnifiedStructureAnalyzer extends ProjectAnalyzer<StructureInfo> {
  UnifiedStructureAnalyzer();

  @override
  String get name => 'unified-structure';

  @override
  int get priority => 10;

  @override
  Future<StructureInfo> analyze(
    Directory projectDir,
    ContextGeneratorConfig config,
  ) async {
    try {
      final directoryAnalyzer = const UnifiedDirectoryAnalyzer();
      final result = await directoryAnalyzer.analyze(projectDir);

      return StructureInfo(
        rootDirectory: projectDir.path,
        directories: result.directories,
        features: result
            .getFilesByType('screen')
            .map((f) => path.basename(f))
            .toList(),
        totalFiles: result.totalFiles,
        linesOfCode: result.totalLinesOfCode,
        fileTypes: result.fileTypes,
        architecturePattern: await _detectArchitecturePattern(projectDir),
        conventions: await _detectConventions(projectDir),
      );
    } catch (e) {
      return ErrorHandler.handleAnalyzerError(
        name,
        e,
        defaultValue: StructureInfo(
          rootDirectory: projectDir.path,
          directories: const {},
          features: const [],
          totalFiles: 0,
          linesOfCode: 0,
          fileTypes: const {},
        ),
      );
    }
  }

  /// Detect architecture pattern
  Future<String?> _detectArchitecturePattern(Directory projectDir) async {
    // Simplified detection - would use enhanced architecture detector
    return null;
  }

  /// Detect project conventions
  Future<List<String>> _detectConventions(Directory projectDir) async {
    final conventions = <String>[];

    // Check for feature-first structure
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    if (await libDir.exists()) {
      final hasFeaturesDir = await Directory(
        path.join(libDir.path, 'features'),
      ).exists();
      if (hasFeaturesDir) {
        conventions.add('feature-first');
      }
    }

    // Check for test structure
    final testDir = Directory(path.join(projectDir.path, 'test'));
    if (await testDir.exists()) {
      conventions.add('test-driven');
    }

    // Check for documentation
    final readmeFile = File(path.join(projectDir.path, 'README.md'));
    if (await readmeFile.exists()) {
      conventions.add('documented');
    }

    return conventions;
  }
}

/// Unified code analyzer
class UnifiedCodeAnalyzer extends CodeAnalyzer<CodeInfo> {
  UnifiedCodeAnalyzer();

  @override
  String get name => 'unified-code';

  @override
  Future<CodeInfo> analyze(
    Directory projectDir,
    ContextGeneratorConfig config,
  ) async {
    try {
      final directoryAnalyzer = const UnifiedDirectoryAnalyzer();
      final result = await directoryAnalyzer.analyze(projectDir);

      // Convert directory result to CodeInfo
      final keyFiles = result.files.values
          .map(
            (file) => SourceFile(
              path: file.path,
              name: file.name,
              type: file.type,
              linesOfCode: file.linesOfCode,
              importance: file.importance,
              description: file.description,
            ),
          )
          .toList();

      // Extract file contents if requested
      final fileContents = config.includeCode
          ? await _extractFileContents(keyFiles, config)
          : <String, String>{};

      // Calculate metrics
      final metrics = <String, int>{
        'total_dart_files': result.dartFiles.length,
        'total_lines_of_code': result.totalLinesOfCode,
        'total_characters': result.files.values.fold(
          0,
          (sum, file) => sum + file.size,
        ),
        'classes': 0, // Would need AST analysis
        'functions': 0, // Would need AST analysis
        'imports': 0, // Would need AST analysis
      };

      // Analyze imports
      final imports = await _analyzeImports(keyFiles);

      // Detect patterns
      final patterns = await _detectPatterns(projectDir);

      return CodeInfo(
        keyFiles: keyFiles,
        fileContents: fileContents,
        metrics: metrics,
        imports: imports,
        patterns: patterns,
      );
    } catch (e) {
      return ErrorHandler.handleAnalyzerError(
        name,
        e,
        defaultValue: const CodeInfo(
          keyFiles: [],
          fileContents: {},
          metrics: {},
          imports: {},
          patterns: [],
        ),
      );
    }
  }

  /// Extract file contents for important files
  Future<Map<String, String>> _extractFileContents(
    List<SourceFile> keyFiles,
    ContextGeneratorConfig config,
  ) async {
    final contents = <String, String>{};
    int filesProcessed = 0;

    for (final file in keyFiles) {
      if (filesProcessed >= config.maxFiles) break;

      if (file.importance == 'low') continue;

      try {
        final fileEntity = File(file.path);
        final content = await FileUtils.readFile(fileEntity);

        if (content != null && content.length <= config.maxFileSize) {
          contents[file.path] = content;
          filesProcessed++;
        }
      } catch (e) {
        continue;
      }
    }

    return contents;
  }

  /// Analyze imports in key files
  Future<Map<String, List<String>>> _analyzeImports(
    List<SourceFile> keyFiles,
  ) async {
    final imports = <String, List<String>>{};

    for (final file in keyFiles) {
      if (file.importance == 'low') continue;

      try {
        final fileEntity = File(file.path);
        final content = await FileUtils.readFile(fileEntity);

        if (content != null) {
          final fileImports = _extractImports(content);
          imports[file.path] = fileImports;
        }
      } catch (e) {
        continue;
      }
    }

    return imports;
  }

  /// Extract imports from file content
  List<String> _extractImports(String content) {
    final imports = <String>[];
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.trim().startsWith('import ')) {
        final singleQuote = RegExp(r"import\s+'(.+?)'").firstMatch(line);
        final doubleQuote = RegExp(r'import\s+"(.+?)"').firstMatch(line);
        final match = singleQuote ?? doubleQuote;
        if (match != null) {
          imports.add(match.group(1)!);
        }
      }
    }
    return imports;
  }

  /// Detect patterns in project
  Future<List<String>> _detectPatterns(Directory projectDir) async {
    final patterns = <String>{};

    try {
      final libDir = Directory(path.join(projectDir.path, 'lib'));
      if (!await libDir.exists()) return patterns.toList();

      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = await FileUtils.readFile(entity);
          if (content != null) {
            final detectedPatterns = _detectPatternsInContent(content);
            patterns.addAll(detectedPatterns);
          }
        }
      }
    } catch (e) {
      // Skip if analysis fails
    }

    return patterns.toList();
  }

  /// Detect patterns in file content
  List<String> _detectPatternsInContent(String content) {
    final patterns = <String>{};

    // State management patterns
    if (content.contains('ConsumerWidget') || content.contains('Consumer')) {
      patterns.add('riverpod');
    }
    if (content.contains('BlocBuilder') || content.contains('BlocListener')) {
      patterns.add('bloc');
    }
    if (content.contains('ChangeNotifier') || content.contains('Provider')) {
      patterns.add('provider');
    }

    // Architecture patterns
    if (content.contains('BaseScreen') || content.contains('BaseViewModel')) {
      patterns.add('fly_architecture');
    }
    if (content.contains('ViewModel') && content.contains('Screen')) {
      patterns.add('mvvm');
    }

    return patterns.toList();
  }
}

/// Unified dependency analyzer
class UnifiedDependencyAnalyzer extends DependencyAnalyzer<DependencyInfo> {
  UnifiedDependencyAnalyzer();

  @override
  String get name => 'unified-dependency';

  @override
  Future<DependencyInfo> analyze(
    Directory projectDir,
    ContextGeneratorConfig config,
  ) async {
    try {
      final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
      if (!await pubspecFile.exists()) {
        throw AnalyzerException('pubspec.yaml not found');
      }

      final content = await FileUtils.readFile(pubspecFile);
      if (content == null) {
        throw AnalyzerException('Failed to read pubspec.yaml');
      }

      final dependencies = _extractDependencies(content);
      final devDependencies = _extractDevDependencies(content);

      final categories = _categorizeDependencies(dependencies);
      final flyPackages = _detectFlyPackages(dependencies);
      final warnings = _checkForWarnings(dependencies, devDependencies);
      final conflicts = _checkForConflicts(dependencies);

      return DependencyInfo(
        dependencies: dependencies,
        devDependencies: devDependencies,
        categories: categories,
        flyPackages: flyPackages,
        warnings: warnings,
        conflicts: conflicts,
      );
    } catch (e) {
      return ErrorHandler.handleAnalyzerError(
        name,
        e,
        defaultValue: const DependencyInfo(
          dependencies: {},
          devDependencies: {},
          categories: {},
          flyPackages: [],
          warnings: [],
          conflicts: [],
        ),
      );
    }
  }

  /// Extract dependencies from pubspec content
  Map<String, String> _extractDependencies(String content) {
    final dependencies = <String, String>{};
    final lines = content.split('\n');
    bool inDependencies = false;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed == 'dependencies:') {
        inDependencies = true;
        continue;
      }

      if (inDependencies) {
        if (trimmed.isEmpty || trimmed.startsWith('dev_dependencies:')) {
          break;
        }

        if (trimmed.contains(':')) {
          final parts = trimmed.split(':');
          if (parts.length >= 2) {
            final package = parts[0].trim();
            final version = parts[1].trim();
            if (package.isNotEmpty && !package.startsWith('#')) {
              dependencies[package] = version;
            }
          }
        }
      }
    }

    return dependencies;
  }

  /// Extract dev dependencies from pubspec content
  Map<String, String> _extractDevDependencies(String content) {
    final devDependencies = <String, String>{};
    final lines = content.split('\n');
    bool inDevDependencies = false;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed == 'dev_dependencies:') {
        inDevDependencies = true;
        continue;
      }

      if (inDevDependencies) {
        if (trimmed.isEmpty) {
          break;
        }

        if (trimmed.contains(':')) {
          final parts = trimmed.split(':');
          if (parts.length >= 2) {
            final package = parts[0].trim();
            final version = parts[1].trim();
            if (package.isNotEmpty && !package.startsWith('#')) {
              devDependencies[package] = version;
            }
          }
        }
      }
    }

    return devDependencies;
  }

  /// Categorize dependencies by type
  Map<String, List<String>> _categorizeDependencies(
    Map<String, String> dependencies,
  ) {
    final categories = <String, List<String>>{
      'state_management': [],
      'networking': [],
      'ui': [],
      'utilities': [],
      'testing': [],
      'development': [],
      'platform': [],
      'other': [],
    };

    for (final entry in dependencies.entries) {
      final package = entry.key;
      final category = _categorizePackage(package);
      categories[category]!.add(package);
    }

    // Remove empty categories
    categories.removeWhere((key, value) => value.isEmpty);
    return categories;
  }

  /// Detect Fly packages
  List<String> _detectFlyPackages(Map<String, String> dependencies) {
    return dependencies.keys
        .where((package) => package.startsWith('fly_'))
        .toList();
  }

  /// Check for dependency warnings
  List<DependencyWarning> _checkForWarnings(
    Map<String, String> dependencies,
    Map<String, String> devDependencies,
  ) {
    final warnings = <DependencyWarning>[];

    // Check for missing dev dependencies
    if (!devDependencies.containsKey('flutter_test')) {
      warnings.add(
        const DependencyWarning(
          package: 'flutter_test',
          message: 'Missing flutter_test dependency for testing',
          severity: 'high',
        ),
      );
    }

    return warnings;
  }

  /// Check for version conflicts
  List<String> _checkForConflicts(Map<String, String> dependencies) {
    final conflicts = <String>[];

    // Check for conflicting state management packages
    final stateManagementPackages = [
      'flutter_riverpod',
      'flutter_bloc',
      'provider',
      'get',
    ];

    final foundStatePackages = stateManagementPackages
        .where((pkg) => dependencies.containsKey(pkg))
        .toList();

    if (foundStatePackages.length > 1) {
      conflicts.add(
        'Multiple state management packages detected: ${foundStatePackages.join(', ')}',
      );
    }

    return conflicts;
  }

  /// Categorize a package by its purpose
  String _categorizePackage(String package) {
    // State management
    if (_isStateManagementPackage(package)) {
      return 'state_management';
    }

    // Networking
    if (_isNetworkingPackage(package)) {
      return 'networking';
    }

    // UI packages
    if (_isUIPackage(package)) {
      return 'ui';
    }

    // Testing packages
    if (_isTestingPackage(package)) {
      return 'testing';
    }

    // Development tools
    if (_isDevelopmentPackage(package)) {
      return 'development';
    }

    // Platform-specific
    if (_isPlatformPackage(package)) {
      return 'platform';
    }

    return 'other';
  }

  /// Check if package is for state management
  bool _isStateManagementPackage(String package) {
    const stateManagementPackages = {
      'flutter_riverpod',
      'riverpod',
      'flutter_bloc',
      'bloc',
      'provider',
      'get',
      'mobx',
      'flutter_mobx',
      'flutter_redux',
      'redux',
      'fish_redux',
      'flutter_hooks',
      'hooks_riverpod',
    };

    return stateManagementPackages.contains(package);
  }

  /// Check if package is for networking
  bool _isNetworkingPackage(String package) {
    const networkingPackages = {
      'dio',
      'http',
      'chopper',
      'retrofit',
      'graphql',
      'web_socket_channel',
      'connectivity_plus',
      'internet_connection_checker',
    };

    return networkingPackages.contains(package) ||
        package.startsWith('fly_networking');
  }

  /// Check if package is for UI
  bool _isUIPackage(String package) {
    const uiPackages = {
      'flutter_screenutil',
      'responsive_framework',
      'flutter_staggered_grid_view',
      'flutter_slidable',
      'flutter_spinkit',
      'lottie',
      'shimmer',
      'cached_network_image',
      'photo_view',
      'image_picker',
      'file_picker',
    };

    return uiPackages.contains(package);
  }

  /// Check if package is for testing
  bool _isTestingPackage(String package) {
    const testingPackages = {
      'flutter_test',
      'mockito',
      'mocktail',
      'integration_test',
      'patrol',
      'golden_toolkit',
    };

    return testingPackages.contains(package);
  }

  /// Check if package is for development
  bool _isDevelopmentPackage(String package) {
    const developmentPackages = {
      'build_runner',
      'json_annotation',
      'json_serializable',
      'freezed',
      'freezed_annotation',
      'injectable',
      'auto_route',
      'go_router',
      'flutter_gen',
      'flutter_launcher_icons',
      'flutter_native_splash',
    };

    return developmentPackages.contains(package);
  }

  /// Check if package is platform-specific
  bool _isPlatformPackage(String package) {
    const platformPackages = {
      'permission_handler',
      'device_info_plus',
      'package_info_plus',
      'url_launcher',
      'share_plus',
      'path_provider',
      'shared_preferences',
      'sqflite',
      'hive',
      'isar',
    };

    return platformPackages.contains(package);
  }
}

/// Unified architecture analyzer
class UnifiedArchitectureAnalyzer
    extends ArchitectureAnalyzer<List<ArchitecturePattern>> {
  UnifiedArchitectureAnalyzer();

  @override
  String get name => 'unified-architecture';

  @override
  Future<List<ArchitecturePattern>> analyze(
    Directory projectDir,
    ContextGeneratorConfig config,
  ) async {
    try {
      final directoryAnalyzer = const UnifiedDirectoryAnalyzer();
      final directoryResult = await directoryAnalyzer.analyze(projectDir);

      final architectureDetector = const ArchitectureDetector();
      return await architectureDetector.detectPatterns(
        projectDir,
        directoryResult,
      );
    } catch (e) {
      return ErrorHandler.handleAnalyzerError(
        name,
        e,
        defaultValue: <ArchitecturePattern>[],
      );
    }
  }
}
