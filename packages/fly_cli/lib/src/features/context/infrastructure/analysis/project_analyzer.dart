import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import 'package:fly_cli/src/features/context/domain/models/models.dart';
import 'package:fly_cli/src/core/manifest/manifest_parser.dart';

/// Analyzes Flutter projects to extract metadata and structure information
class ProjectAnalyzer {
  const ProjectAnalyzer();

  /// Analyze a complete project directory
  Future<ProjectInfo> analyzeProject(Directory projectDir) async {
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw Exception('Not a Flutter project: pubspec.yaml not found');
    }

    // Analyze pubspec.yaml
    final pubspecInfo = await analyzePubspec(pubspecFile);

    // Check for Fly manifest
    final manifestInfo = await analyzeManifest(projectDir);

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
  }

  /// Analyze pubspec.yaml file with retry logic
  Future<PubspecInfo> analyzePubspec(File pubspecFile) async {
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 50);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final content = await pubspecFile.readAsString();
        final pubspec = Pubspec.parse(content);

        return PubspecInfo(
          name: pubspec.name,
          version: pubspec.version.toString(),
          description: pubspec.description,
          homepage: pubspec.homepage,
          repository: pubspec.repository?.toString(),
          environment: pubspec.environment?.map((key, value) => MapEntry(key, value.toString())),
          dependencies: _extractDependencies(pubspec.dependencies),
          devDependencies: _extractDependencies(pubspec.devDependencies),
        );
      } catch (e) {
        if (attempt == maxRetries - 1) {
          throw Exception('Failed to parse pubspec.yaml after $maxRetries attempts: $e');
        }
        // Wait before retry
        await Future.delayed(retryDelay * (attempt + 1));
      }
    }
    
    throw Exception('Failed to parse pubspec.yaml: Unknown error');
  }

  /// Analyze Fly manifest if present
  Future<ManifestInfo?> analyzeManifest(Directory projectDir) async {
    final manifestFile = File(path.join(projectDir.path, 'fly_project.yaml'));
    if (!await manifestFile.exists()) {
      return null;
    }

    try {
      final manifest = await ProjectManifest.fromFile(manifestFile.path);
      return ManifestInfo(
        name: manifest.name,
        template: manifest.template,
        organization: manifest.organization,
        description: manifest.description,
        platforms: manifest.platforms,
        screens: manifest.screens.map((s) => ManifestScreen(
          name: s.name,
          type: s.type,
          features: s.features,
        )).toList(),
        services: manifest.services.map((s) => ManifestService(
          name: s.name,
          type: s.type,
          apiBase: s.apiBase,
          features: s.features,
        )).toList(),
        packages: manifest.packages,
      );
    } catch (e) {
      // If manifest exists but is malformed, return null
      return null;
    }
  }

  /// Analyze project structure
  Future<StructureInfo> analyzeStructure(Directory projectDir) async {
    final directories = <String, DirectoryInfo>{};
    final features = <String>{};
    int totalFiles = 0;
    int linesOfCode = 0;
    final fileTypes = <String, int>{};

    // Analyze each top-level directory
    await for (final entity in projectDir.list(recursive: false)) {
      if (entity is Directory) {
        final dirInfo = await _analyzeDirectory(entity);
        directories[path.basename(entity.path)] = dirInfo;
      }
    }

    // Count all files recursively and analyze content
    await for (final entity in projectDir.list(recursive: true)) {
      if (entity is File) {
        totalFiles++;
        
        // Count file types
        final extension = path.extension(entity.path);
        fileTypes[extension] = (fileTypes[extension] ?? 0) + 1;

        // Count lines of code for Dart files using streaming
        if (entity.path.endsWith('.dart')) {
          try {
            final lines = await _countLinesInFile(entity);
            linesOfCode += lines;
          } catch (e) {
            // Skip files that can't be read
          }
        }

        // Detect features from lib directory
        if (entity.path.startsWith(path.join(projectDir.path, 'lib'))) {
          final relativePath = path.relative(entity.path, from: projectDir.path);
          final feature = _extractFeatureFromPath(relativePath);
          if (feature != null) {
            features.add(feature);
          }
        }
      }
    }

    return StructureInfo(
      rootDirectory: projectDir.path,
      directories: directories,
      features: features.toList()..sort(),
      totalFiles: totalFiles,
      linesOfCode: linesOfCode,
      fileTypes: fileTypes,
      architecturePattern: await _detectArchitecturePattern(projectDir),
      conventions: await _detectConventions(projectDir),
    );
  }

  /// Detect architecture pattern
  Future<String?> _detectArchitecturePattern(Directory projectDir) async {
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) return null;

    final pubspecInfo = await analyzePubspec(pubspecFile);
    final dependencies = pubspecInfo.dependencies;

    // Check for Fly packages
    if (dependencies.containsKey('fly_core') || 
        dependencies.containsKey('fly_state') ||
        dependencies.containsKey('fly_networking')) {
      return 'fly';
    }

    // Check for state management patterns
    if (dependencies.containsKey('flutter_riverpod')) {
      return 'riverpod';
    } else if (dependencies.containsKey('flutter_bloc')) {
      return 'bloc';
    } else if (dependencies.containsKey('provider')) {
      return 'provider';
    }

    return null;
  }

  /// Detect project conventions
  Future<List<String>> _detectConventions(Directory projectDir) async {
    final conventions = <String>[];

    // Check for feature-first structure
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    if (await libDir.exists()) {
      final hasFeaturesDir = await Directory(path.join(libDir.path, 'features')).exists();
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

  /// Analyze a single directory
  Future<DirectoryInfo> _analyzeDirectory(Directory dir) async {
    int files = 0;
    int dartFiles = 0;
    final subdirectories = <String>[];

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        files++;
        if (entity.path.endsWith('.dart')) {
          dartFiles++;
        }
      } else if (entity is Directory) {
        // Only count immediate subdirectories
        final relativePath = path.relative(entity.path, from: dir.path);
        if (!relativePath.contains('/')) {
          subdirectories.add(path.basename(entity.path));
        }
      }
    }

    return DirectoryInfo(
      files: files,
      dartFiles: dartFiles,
      subdirectories: subdirectories,
    );
  }

  /// Extract feature name from file path
  String? _extractFeatureFromPath(String relativePath) {
    final parts = relativePath.split('/');
    // Handle both "features/..." and "lib/features/..." paths
    if (parts.length >= 3 && parts[0] == 'lib' && parts[1] == 'features') {
      return parts[2];
    } else if (parts.length >= 2 && parts[0] == 'features') {
      return parts[1];
    }
    return null;
  }

  /// Check if project uses Fly packages
  bool _isFlyProject(PubspecInfo pubspecInfo) {
    final dependencies = pubspecInfo.dependencies;
    return dependencies.containsKey('fly_core') ||
           dependencies.containsKey('fly_state') ||
           dependencies.containsKey('fly_networking');
  }

  /// Extract platforms from pubspec
  List<String> _extractPlatforms(PubspecInfo pubspecInfo) {
    // Default platforms for Flutter projects
    return ['ios', 'android'];
  }

  /// Extract dependencies as string map
  Map<String, String> _extractDependencies(Map<String, Dependency> dependencies) {
    return dependencies.map((key, value) => MapEntry(key, value.toString()));
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

  /// Count lines in a file using streaming for large files
  Future<int> _countLinesInFile(File file) async {
    try {
      // For small files, read normally
      final stat = await file.stat();
      if (stat.size < 1024 * 1024) { // Less than 1MB
        final content = await file.readAsString();
        return content.split('\n').length;
      }

      // For larger files, use streaming to count lines
      int lineCount = 0;
      final stream = file.openRead();
      
      await for (final chunk in stream) {
        final content = String.fromCharCodes(chunk);
        lineCount += content.split('\n').length - 1; // -1 because split creates extra element
      }
      
      return lineCount + 1; // +1 for the last line
    } catch (e) {
      return 0;
    }
  }
}
