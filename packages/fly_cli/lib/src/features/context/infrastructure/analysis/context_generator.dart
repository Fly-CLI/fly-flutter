import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:fly_cli/src/features/context/domain/models/models.dart';
import 'project_analyzer.dart';
import 'dependency_analyzer.dart';
import 'code_analyzer.dart';
import 'architecture_detector.dart';
import 'complexity_analyzer.dart';
import 'quality_analyzer.dart';
import 'dependency_health_analyzer.dart';
import 'package:fly_cli/src/features/schema/domain/command_registry.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';
import 'package:mason_logger/mason_logger.dart';

/// Generates comprehensive AI context from project analysis
class ContextGenerator {
  const ContextGenerator({
    required this.logger,
  });

  final Logger logger;

  /// Generate complete context for a project
  Future<Map<String, dynamic>> generate(
    Directory projectDir,
    ContextGeneratorConfig config,
  ) async {
    logger.info('Analyzing project structure...');
    
    // Initialize analyzers
    const projectAnalyzer = ProjectAnalyzer();
    const dependencyAnalyzer = DependencyAnalyzer();
    const codeAnalyzer = CodeAnalyzer();
    const architectureDetector = ArchitectureDetector();
    const complexityAnalyzer = ComplexityAnalyzer();
    const qualityAnalyzer = QualityAnalyzer();
    const dependencyHealthAnalyzer = DependencyHealthAnalyzer();

    // Run independent analyzers in parallel for better performance
    final futures = <Future>[
      projectAnalyzer.analyzeProject(projectDir),
      projectAnalyzer.analyzeStructure(projectDir),
    ];

    // Add optional analyzers based on configuration
    if (config.includeDependencies) {
      logger.info('Analyzing dependencies...');
      final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
      futures.add(dependencyAnalyzer.analyzeDependencies(pubspecFile));
      futures.add(dependencyHealthAnalyzer.analyzeDependencyHealth(projectDir));
    }

    if (config.includeCode) {
      logger.info('Analyzing source code...');
      futures.add(codeAnalyzer.analyzeCode(projectDir, config));
      
      // Add advanced code analysis
      logger.info('Analyzing code complexity...');
      futures.add(_analyzeCodeComplexity(projectDir, complexityAnalyzer));
      
      logger.info('Analyzing code quality...');
      futures.add(_analyzeCodeQuality(projectDir, qualityAnalyzer));
    }

    if (config.includeArchitecture) {
      logger.info('Detecting architecture patterns...');
      futures.add(architectureDetector.detectPatterns(projectDir));
    }

    // Wait for all analyzers to complete with error handling
    final results = await _waitForAnalyzersWithRetry(futures);
    
    // Extract results with null safety
    final projectInfo = results[0] as ProjectInfo?;
    final structureInfo = results[1] as StructureInfo?;
    
    DependencyInfo? dependencyInfo;
    List<DependencyHealth>? dependencyHealth;
    CodeInfo? codeInfo;
    Map<String, ComplexityMetrics>? complexityMetrics;
    Map<String, QualityReport>? qualityReports;
    List<ArchitecturePattern>? architecturePatterns;
    
    int resultIndex = 2;
    if (config.includeDependencies) {
      dependencyInfo = results[resultIndex] as DependencyInfo?;
      resultIndex++;
      dependencyHealth = results[resultIndex] as List<DependencyHealth>?;
      resultIndex++;
    }
    
    if (config.includeCode) {
      codeInfo = results[resultIndex] as CodeInfo?;
      resultIndex++;
      complexityMetrics = results[resultIndex] as Map<String, ComplexityMetrics>?;
      resultIndex++;
      qualityReports = results[resultIndex] as Map<String, QualityReport>?;
      resultIndex++;
    }

    if (config.includeArchitecture) {
      architecturePatterns = results[resultIndex] as List<ArchitecturePattern>?;
    }

    // Ensure we have at least basic project info
    if (projectInfo == null || structureInfo == null) {
      throw Exception('Failed to analyze project: Unable to extract basic project information');
    }

    // Build context sections
    final context = <String, dynamic>{
      'project': buildProjectSection(projectInfo),
      'structure': buildStructureSection(structureInfo),
      'commands': buildCommandsSection(),
      'exported_at': DateTime.now().toIso8601String(),
      'cli_version': VersionUtils.getCurrentVersion(),
    };

    // Add optional sections
    if (dependencyInfo != null) {
      context['dependencies'] = buildDependenciesSection(dependencyInfo);
    }

    if (dependencyHealth != null) {
      context['dependency_health'] = buildDependencyHealthSection(dependencyHealth);
    }

    if (codeInfo != null) {
      context['code'] = buildCodeSection(codeInfo);
    }

    if (complexityMetrics != null) {
      context['complexity'] = buildComplexitySection(complexityMetrics);
    }

    if (qualityReports != null) {
      context['quality'] = buildQualitySection(qualityReports);
    }

    if (architecturePatterns != null && architecturePatterns.isNotEmpty) {
      // Use the pattern with the highest confidence
      final bestPattern = architecturePatterns.reduce((a, b) => a.confidence > b.confidence ? a : b);
      context['architecture'] = buildArchitectureSection(projectInfo, structureInfo, bestPattern);
    } else if (config.includeArchitecture) {
      context['architecture'] = buildArchitectureSection(projectInfo, structureInfo);
    }

    if (config.includeSuggestions) {
      context['suggestions'] = generateSuggestions(projectInfo, dependencyInfo, codeInfo);
    }

    return context;
  }

  /// Build project metadata section
  Map<String, dynamic> buildProjectSection(ProjectInfo projectInfo) {
    return projectInfo.toJson();
  }

  /// Build structure information section
  Map<String, dynamic> buildStructureSection(StructureInfo structureInfo) {
    return structureInfo.toJson();
  }

  /// Build commands section with CLI metadata
  Map<String, dynamic> buildCommandsSection() {
    final registry = CommandMetadataRegistry.instance;
    
    if (!registry.isInitialized) {
      return {
        'available': [],
        'schemas': {},
        'suggestions': ['Run "fly doctor" to initialize CLI'],
      };
    }

    final allCommands = registry.getAllCommands();
    final commandNames = allCommands.keys.toList()..sort();

    return {
      'available': commandNames,
      'schemas': allCommands.map((key, value) => MapEntry(key, value.toJson())),
      'suggestions': _generateCommandSuggestions(allCommands),
    };
  }

  /// Build dependencies section
  Map<String, dynamic> buildDependenciesSection(DependencyInfo dependencyInfo) {
    return dependencyInfo.toJson();
  }

  /// Build code section
  Map<String, dynamic> buildCodeSection(CodeInfo codeInfo) {
    return codeInfo.toJson();
  }

  /// Build architecture section
  Map<String, dynamic> buildArchitectureSection(
    ProjectInfo projectInfo,
    StructureInfo structureInfo, [
    ArchitecturePattern? architecturePattern,
  ]) {
    return {
      'pattern': architecturePattern?.name ?? structureInfo.architecturePattern ?? 'unknown',
      'confidence': architecturePattern?.confidence ?? 0.0,
      'indicators': architecturePattern?.indicators ?? [],
      'conventions': structureInfo.conventions,
      'project_type': projectInfo.type,
      'is_fly_project': projectInfo.isFlyProject,
      'has_manifest': projectInfo.hasManifest,
    };
  }

  /// Generate intelligent suggestions based on analysis
  List<String> generateSuggestions(
    ProjectInfo projectInfo,
    DependencyInfo? dependencyInfo,
    CodeInfo? codeInfo,
  ) {
    final suggestions = <String>[];

    // Project-specific suggestions
    if (projectInfo.isFlyProject) {
      suggestions.add('This is a Fly CLI project. Use "fly add screen <name>" to add new screens');
      suggestions.add('Use "fly add service <name>" to add new API services');
      
      if (!projectInfo.hasManifest) {
        suggestions.add('Consider creating a fly_project.yaml manifest for declarative project management');
      }
    } else {
      suggestions.add('This is a standard Flutter project. Consider using "fly create" to scaffold a new Fly project');
    }

    // Dependency suggestions
    if (dependencyInfo != null) {
      // Check for missing common dependencies
      if (!dependencyInfo.dependencies.containsKey('flutter_riverpod') &&
          !dependencyInfo.dependencies.containsKey('flutter_bloc') &&
          !dependencyInfo.dependencies.containsKey('provider')) {
        suggestions.add('Consider adding a state management solution: flutter_riverpod, flutter_bloc, or provider');
      }

      if (!dependencyInfo.dependencies.containsKey('dio') &&
          !dependencyInfo.dependencies.containsKey('http')) {
        suggestions.add('Consider adding an HTTP client: dio or http');
      }

      // Check for Fly packages
      if (dependencyInfo.flyPackages.isEmpty) {
        suggestions.add('Consider using Fly packages for consistent architecture: fly_core, fly_state, fly_networking');
      }

      // Check for warnings
      for (final warning in dependencyInfo.warnings) {
        if (warning.severity == 'high') {
          suggestions.add('High priority: ${warning.message} for package ${warning.package}');
        }
      }

      // Check for conflicts
      for (final conflict in dependencyInfo.conflicts) {
        suggestions.add('Dependency conflict: $conflict');
      }
    }

    // Code suggestions
    if (codeInfo != null) {
      // Check for missing tests
      final testFiles = codeInfo.keyFiles.where((f) => f.type == 'test').length;
      final screenFiles = codeInfo.keyFiles.where((f) => f.type == 'screen').length;
      
      if (screenFiles > 0 && testFiles == 0) {
        suggestions.add('Add tests for your screens using "fly add test <screen_name>"');
      }

      // Check for missing services
      final serviceFiles = codeInfo.keyFiles.where((f) => f.type == 'service').length;
      if (screenFiles > 0 && serviceFiles == 0) {
        suggestions.add('Consider adding API services for data management');
      }

      // Check for patterns
      if (codeInfo.patterns.contains('riverpod')) {
        suggestions.add('Using Riverpod? Consider "fly add provider <name>" for dependency injection');
      }

      if (codeInfo.patterns.contains('bloc')) {
        suggestions.add('Using BLoC? Consider "fly add cubit <name>" for state management');
      }
    }

    // General suggestions
    suggestions.add('Use "fly schema export" to get CLI command schemas for AI integration');
    suggestions.add('Run "fly doctor" to check system health and configuration');

    return suggestions;
  }

  /// Generate command-specific suggestions
  List<String> _generateCommandSuggestions(Map<String, dynamic> allCommands) {
    final suggestions = <String>[];

    // Suggest commands based on available functionality
    if (allCommands.containsKey('create')) {
      suggestions.add('Create new projects with: fly create <name> --template=riverpod');
    }

    if (allCommands.containsKey('add')) {
      suggestions.add('Add components with: fly add screen <name> or fly add service <name>');
    }

    if (allCommands.containsKey('schema')) {
      suggestions.add('Export CLI schemas with: fly schema export --format=json');
    }

    if (allCommands.containsKey('doctor')) {
      suggestions.add('Check system health with: fly doctor');
    }

    return suggestions;
  }

  /// Wait for analyzers to complete with retry logic and graceful degradation
  Future<List<dynamic?>> _waitForAnalyzersWithRetry(List<Future> futures) async {
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 100);
    
    final results = <dynamic?>[];
    
    for (int i = 0; i < futures.length; i++) {
      dynamic result;
      bool success = false;
      
      for (int attempt = 0; attempt < maxRetries && !success; attempt++) {
        try {
          result = await futures[i];
          success = true;
        } catch (e) {
          if (attempt == maxRetries - 1) {
            // Last attempt failed, log error and continue with null
            logger.warn('Analyzer ${i} failed after $maxRetries attempts: $e');
            result = null;
          } else {
            // Wait before retry
            await Future.delayed(retryDelay * (attempt + 1));
          }
        }
      }
      
      results.add(result);
    }
    
    return results;
  }

  /// Analyze code complexity for all Dart files
  Future<Map<String, ComplexityMetrics>> _analyzeCodeComplexity(
    Directory projectDir,
    ComplexityAnalyzer analyzer,
  ) async {
    final complexityMetrics = <String, ComplexityMetrics>{};
    
    try {
      final libDir = Directory(path.join(projectDir.path, 'lib'));
      if (!await libDir.exists()) return complexityMetrics;
      
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          try {
            final metrics = await analyzer.calculateComplexity(entity);
            complexityMetrics[entity.path] = metrics;
          } catch (e) {
            // Skip files that can't be analyzed
            continue;
          }
        }
      }
    } catch (e) {
      // Return empty map if analysis fails
    }
    
    return complexityMetrics;
  }

  /// Analyze code quality for all Dart files
  Future<Map<String, QualityReport>> _analyzeCodeQuality(
    Directory projectDir,
    QualityAnalyzer analyzer,
  ) async {
    final qualityReports = <String, QualityReport>{};
    
    try {
      final libDir = Directory(path.join(projectDir.path, 'lib'));
      if (!await libDir.exists()) return qualityReports;
      
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          try {
            final report = await analyzer.analyzeQuality(entity);
            qualityReports[entity.path] = report;
          } catch (e) {
            // Skip files that can't be analyzed
            continue;
          }
        }
      }
    } catch (e) {
      // Return empty map if analysis fails
    }
    
    return qualityReports;
  }

  /// Build dependency health section
  Map<String, dynamic> buildDependencyHealthSection(List<DependencyHealth> dependencyHealth) {
    return {
      'packages': dependencyHealth.map((health) => health.toJson()).toList(),
    };
  }

  /// Build complexity metrics section
  Map<String, dynamic> buildComplexitySection(Map<String, ComplexityMetrics> complexityMetrics) {
    return {
      'files': complexityMetrics.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  /// Build quality reports section
  Map<String, dynamic> buildQualitySection(Map<String, QualityReport> qualityReports) {
    return {
      'files': qualityReports.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}
