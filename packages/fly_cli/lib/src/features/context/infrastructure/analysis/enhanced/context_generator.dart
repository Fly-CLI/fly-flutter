import 'dart:io';

import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';
import 'package:fly_cli/src/features/context/domain/models/models.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/base/analyzer_interface.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/base/utils.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/enhanced/dependency_health_analyzer.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/unified/ast_analyzer.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/unified/unified_analyzers.dart';
import 'package:fly_core/src/retry/retry.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// Enhanced context generator using the new unified architecture
class ContextGenerator {
  const ContextGenerator({required this.logger});

  final Logger logger;

  /// Generate complete context for a project using unified analyzers
  Future<Map<String, dynamic>> generate(
    Directory projectDir,
    ContextGeneratorConfig config,
  ) async {
    logger.info('🔍 Analyzing project with enhanced architecture...');

    // Initialize analyzer registry
    final registry = AnalyzerRegistry();
    _registerAnalyzers(registry);

    // Get analyzers that should run
    final analyzers = registry.getAnalyzers(config);

    logger.info('📊 Running ${analyzers.length} analyzers in parallel...');

    // Run all analyzers in parallel with retry logic
    const retryExecutor = RetryExecutor(
      policy: RetryPolicy.quick,
    );
    final results = await retryExecutor.retryAll(
      analyzers
          .map(
            (analyzer) =>
                () => analyzer.analyze(projectDir, config),
          )
          .toList(),
    );

    // Extract results with proper typing
    final analysisResults = <String, dynamic>{};
    for (int i = 0; i < analyzers.length; i++) {
      final analyzer = analyzers[i];
      final result = results[i];
      if (result != null) {
        analysisResults[analyzer.name] = result;
      }
    }

    // Build context sections
    final context = <String, dynamic>{
      'project': _buildProjectSection(analysisResults),
      'structure': _buildStructureSection(analysisResults),
      'commands': _buildCommandsSection(),
      'exported_at': DateTime.now().toIso8601String(),
      'cli_version': VersionUtils.getCurrentVersion(),
    };

    // Add optional sections based on configuration
    if (config.includeDependencies) {
      context['dependencies'] = _buildDependenciesSection(analysisResults);
      context['dependency_health'] = await _buildDependencyHealthSection(
        projectDir,
      );
    }

    if (config.includeCode) {
      // Merge unified code analyzer results with AST analysis
      final codeSection = _buildCodeSection(analysisResults);
      final astSection = await _buildAstAnalysisSection(
        projectDir,
        config,
      );
      
      // Merge both sections, with AST analysis taking precedence for overlapping keys
      // Special handling for patterns: convert Map<String, List<String>> to List<String>
      final mergedCode = <String, dynamic>{
        ...codeSection,
      };
      
      // Collect all patterns from both sections
      final allPatterns = <String>{};
      
      // Get patterns from codeSection (always a List if present)
      final codePatterns = codeSection['patterns'];
      if (codePatterns is List) {
        allPatterns.addAll(codePatterns.cast<String>());
      }
      
      // Get patterns from AST section (might be a Map or List)
      final astPatterns = astSection['patterns'];
      if (astPatterns is Map) {
        // Convert AST patterns Map<String, List<String>> to a flat List<String>
        final patternsMap = astPatterns as Map<String, dynamic>;
        for (final patternsList in patternsMap.values) {
          if (patternsList is List) {
            allPatterns.addAll(patternsList.cast<String>());
          }
        }
      } else if (astPatterns is List) {
        allPatterns.addAll(astPatterns.cast<String>());
      }
      
      // Merge all AST fields except patterns and error
      for (final entry in astSection.entries) {
        if (entry.key != 'patterns' && entry.key != 'error') {
          mergedCode[entry.key] = entry.value;
        }
      }
      
      // Always set patterns as a List (empty if no patterns found)
      mergedCode['patterns'] = allPatterns.toList();
      
      context['code'] = mergedCode;
    }

    if (config.includeArchitecture) {
      context['architecture'] = _buildArchitectureSection(analysisResults);
    }

    if (config.includeSuggestions) {
      context['suggestions'] = _generateSuggestions(analysisResults);
    }

    // Add performance metrics
    context['performance'] = _buildPerformanceSection();

    logger.info(
      '✅ Analysis complete - ${analysisResults.length} analyzers executed',
    );

    return context;
  }

  /// Register all analyzers in the registry
  void _registerAnalyzers(AnalyzerRegistry registry) {
    registry..register(UnifiedProjectAnalyzer())
    ..register(UnifiedStructureAnalyzer())
    ..register(UnifiedCodeAnalyzer())
    ..register(UnifiedDependencyAnalyzer())
    ..register(UnifiedArchitectureAnalyzer());
  }

  /// Build project metadata section
  Map<String, dynamic> _buildProjectSection(
    Map<String, dynamic> analysisResults,
  ) {
    final projectInfo = analysisResults['unified-project'] as ProjectInfo?;
    if (projectInfo != null) {
      return projectInfo.toJson();
    }

    return {
      'name': 'unknown',
      'type': 'flutter',
      'version': '0.0.0',
      'is_fly_project': false,
      'has_manifest': false,
    };
  }

  /// Build structure information section
  Map<String, dynamic> _buildStructureSection(
    Map<String, dynamic> analysisResults,
  ) {
    final structureInfo =
        analysisResults['unified-structure'] as StructureInfo?;
    if (structureInfo != null) {
      return structureInfo.toJson();
    }

    return {
      'root_directory': '',
      'directories': {},
      'features': [],
      'total_files': 0,
      'lines_of_code': 0,
      'file_types': {},
      'conventions': [],
    };
  }

  /// Build commands section with CLI metadata
  Map<String, dynamic> _buildCommandsSection() {
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
  Map<String, dynamic> _buildDependenciesSection(
    Map<String, dynamic> analysisResults,
  ) {
    final dependencyInfo =
        analysisResults['unified-dependency'] as DependencyInfo?;
    if (dependencyInfo != null) {
      return dependencyInfo.toJson();
    }

    return {
      'dependencies': {},
      'dev_dependencies': {},
      'categories': {},
      'fly_packages': [],
      'warnings': [],
      'conflicts': [],
    };
  }

  /// Build dependency health section
  Future<Map<String, dynamic>> _buildDependencyHealthSection(
    Directory projectDir,
  ) async {
    try {
      final healthAnalyzer = const DependencyHealthAnalyzer();
      final healthReports = await healthAnalyzer.analyzeDependencyHealth(
        projectDir,
      );

      return {
        'packages': healthReports.map((health) => health.toJson()).toList(),
        'cache_stats': DependencyHealthAnalyzer.getCacheStats(),
      };
    } catch (e) {
      logger.warn('Failed to analyze dependency health: $e');
      return {'packages': [], 'error': e.toString()};
    }
  }

  /// Build code section
  Map<String, dynamic> _buildCodeSection(Map<String, dynamic> analysisResults) {
    final codeInfo = analysisResults['unified-code'] as CodeInfo?;
    if (codeInfo != null) {
      return codeInfo.toJson();
    }

    return {
      'key_files': [],
      'file_contents': {},
      'metrics': {},
      'imports': {},
      'patterns': [],
    };
  }

  /// Build AST analysis section
  Future<Map<String, dynamic>> _buildAstAnalysisSection(
    Directory projectDir,
    ContextGeneratorConfig config,
  ) async {
    try {
      final libDir = Directory(path.join(projectDir.path, 'lib'));
      if (!await libDir.exists()) {
        return {'error': 'lib directory not found'};
      }

      // Get Dart files with size limits
      final dartFiles = <File>[];
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          // Check file size before adding
          final stat = await entity.stat();
          if (stat.size <= config.maxFileSize) {
            dartFiles.add(entity);
          }
        }
      }

      if (dartFiles.isEmpty) {
        return {'error': 'No Dart files found'};
      }

      // Limit files based on configuration
      final filesToAnalyze = dartFiles.take(config.maxFiles).toList();

      const astAnalyzer = AstAnalyzer();
      final result = await astAnalyzer.analyzeFiles(filesToAnalyze);

      return {
        ...result.toJson(),
        'files_analyzed': filesToAnalyze.length,
        'total_files_found': dartFiles.length,
      };
    } catch (e) {
      logger.warn('Failed to perform AST analysis: $e');
      return {
        'error': e.toString(),
        'files_analyzed': 0,
        'total_files_found': 0,
      };
    }
  }

  /// Build architecture section
  Map<String, dynamic> _buildArchitectureSection(
    Map<String, dynamic> analysisResults,
  ) {
    final architecturePatterns =
        analysisResults['unified-architecture'] as List<ArchitecturePattern>?;
    final projectInfo = analysisResults['unified-project'] as ProjectInfo?;
    final structureInfo =
        analysisResults['unified-structure'] as StructureInfo?;

    if (architecturePatterns != null && architecturePatterns.isNotEmpty) {
      // Prioritize state management and framework patterns over structural patterns
      final priorityPatterns = architecturePatterns.where((p) =>
          ['riverpod', 'bloc', 'provider', 'get', 'fly'].contains(p.name));
      
      // Use priority pattern if available, otherwise use highest confidence
      final bestPattern = priorityPatterns.isNotEmpty
          ? priorityPatterns.reduce(
              (a, b) => a.confidence > b.confidence ? a : b,
            )
          : architecturePatterns.reduce(
              (a, b) => a.confidence > b.confidence ? a : b,
            );

      return {
        'pattern': bestPattern.name,
        'confidence': bestPattern.confidence,
        'indicators': bestPattern.indicators,
        'metadata': bestPattern.metadata,
        'all_patterns': architecturePatterns.map((p) => p.toJson()).toList(),
        'project_type': projectInfo?.type ?? 'unknown',
        'is_fly_project': projectInfo?.isFlyProject ?? false,
        'has_manifest': projectInfo?.hasManifest ?? false,
        'conventions': structureInfo?.conventions ?? [],
      };
    }

    return {
      'pattern': structureInfo?.architecturePattern ?? 'unknown',
      'confidence': 0.0,
      'indicators': [],
      'metadata': {},
      'all_patterns': [],
      'project_type': projectInfo?.type ?? 'unknown',
      'is_fly_project': projectInfo?.isFlyProject ?? false,
      'has_manifest': projectInfo?.hasManifest ?? false,
      'conventions': structureInfo?.conventions ?? [],
    };
  }

  /// Generate intelligent suggestions based on analysis
  List<String> _generateSuggestions(Map<String, dynamic> analysisResults) {
    final suggestions = <String>[];

    final projectInfo = analysisResults['unified-project'] as ProjectInfo?;
    final dependencyInfo =
        analysisResults['unified-dependency'] as DependencyInfo?;
    final codeInfo = analysisResults['unified-code'] as CodeInfo?;
    final architecturePatterns =
        analysisResults['unified-architecture'] as List<ArchitecturePattern>?;

    // Project-specific suggestions
    if (projectInfo?.isFlyProject == true) {
      suggestions.add(
        'This is a Fly CLI project. Use "fly add screen <name>" to add new screens',
      );
      suggestions.add('Use "fly add service <name>" to add new API services');

      if (projectInfo?.hasManifest == false) {
        suggestions.add(
          'Consider creating a fly_project.yaml manifest for declarative project management',
        );
      }
    } else {
      suggestions.add(
        'This is a standard Flutter project. Consider using "fly create" to scaffold a new Fly project',
      );
    }

    // Dependency suggestions
    if (dependencyInfo != null) {
      // Check for missing common dependencies
      if (!dependencyInfo.dependencies.containsKey('flutter_riverpod') &&
          !dependencyInfo.dependencies.containsKey('flutter_bloc') &&
          !dependencyInfo.dependencies.containsKey('provider')) {
        suggestions.add(
          'Consider adding a state management solution: flutter_riverpod, flutter_bloc, or provider',
        );
      }

      if (!dependencyInfo.dependencies.containsKey('dio') &&
          !dependencyInfo.dependencies.containsKey('http')) {
        suggestions.add('Consider adding an HTTP client: dio or http');
      }

      // Check for Fly packages
      if (dependencyInfo.flyPackages.isEmpty) {
        suggestions.add(
          'Consider using Fly packages for consistent architecture: fly_core, fly_state, fly_networking',
        );
      }

      // Check for warnings
      for (final warning in dependencyInfo.warnings) {
        if (warning.severity == 'high') {
          suggestions.add(
            'High priority: ${warning.message} for package ${warning.package}',
          );
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
      final screenFiles = codeInfo.keyFiles
          .where((f) => f.type == 'screen')
          .length;

      if (screenFiles > 0 && testFiles == 0) {
        suggestions.add(
          'Add tests for your screens using "fly add test <screen_name>"',
        );
      }

      // Check for missing services
      final serviceFiles = codeInfo.keyFiles
          .where((f) => f.type == 'service')
          .length;
      if (screenFiles > 0 && serviceFiles == 0) {
        suggestions.add('Consider adding API services for data management');
      }

      // Check for patterns
      if (codeInfo.patterns.contains('riverpod')) {
        suggestions.add(
          'Using Riverpod? Consider "fly add provider <name>" for dependency injection',
        );
      }

      if (codeInfo.patterns.contains('bloc')) {
        suggestions.add(
          'Using BLoC? Consider "fly add cubit <name>" for state management',
        );
      }
    }

    // Architecture suggestions
    if (architecturePatterns != null && architecturePatterns.isNotEmpty) {
      final bestPattern = architecturePatterns.reduce(
        (a, b) => a.confidence > b.confidence ? a : b,
      );

      if (bestPattern.name == 'feature-first' && bestPattern.confidence < 0.8) {
        suggestions.add(
          'Consider improving feature-first organization for better maintainability',
        );
      }

      if (bestPattern.name == 'clean-architecture' &&
          bestPattern.confidence < 0.7) {
        suggestions.add('Consider implementing clean architecture principles');
      }
    }

    // General suggestions
    suggestions
      ..add(
        'Use "fly schema export" to get CLI command schemas for AI integration',
      )
      ..add('Run "fly doctor" to check system health and configuration');

    return suggestions;
  }

  /// Generate command-specific suggestions
  List<String> _generateCommandSuggestions(Map<String, dynamic> allCommands) {
    final suggestions = <String>[];

    // Suggest commands based on available functionality
    if (allCommands.containsKey('create')) {
      suggestions.add(
        'Create new projects with: fly create <name> --template=riverpod',
      );
    }

    if (allCommands.containsKey('add')) {
      suggestions.add(
        'Add components with: fly add screen <name> or fly add service <name>',
      );
    }

    if (allCommands.containsKey('schema')) {
      suggestions.add(
        'Export CLI schemas with: fly schema export --format=json',
      );
    }

    if (allCommands.containsKey('doctor')) {
      suggestions.add('Check system health with: fly doctor');
    }

    return suggestions;
  }

  /// Build performance section
  Map<String, dynamic> _buildPerformanceSection() {
    return {
      'file_cache_stats': FileUtils.getCacheStats(),
      'dependency_cache_stats':
          DependencyHealthAnalyzer.getCacheStats(),
      'analysis_time': DateTime.now().toIso8601String(),
    };
  }
}
