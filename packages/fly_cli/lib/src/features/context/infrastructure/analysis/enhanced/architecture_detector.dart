import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:fly_cli/src/features/context/domain/models/models.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/base/utils.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/unified/directory_analyzer.dart';

/// Enhanced architecture pattern detector with context-aware analysis
class ArchitectureDetector {
  const ArchitectureDetector();

  /// Detect architecture patterns with improved accuracy
  Future<List<ArchitecturePattern>> detectPatterns(
    Directory projectDir,
    DirectoryAnalysisResult? directoryResult,
  ) async {
    final patterns = <ArchitecturePattern>[];
    
    // Analyze project structure with context
    final structurePatterns = await _analyzeStructureWithContext(projectDir, directoryResult);
    patterns.addAll(structurePatterns);
    
    // Analyze dependencies with enhanced detection
    final dependencyPatterns = await _analyzeDependenciesWithContext(projectDir);
    patterns.addAll(dependencyPatterns);
    
    // Analyze code patterns with AST context
    final codePatterns = await _analyzeCodePatternsWithContext(projectDir, directoryResult);
    patterns.addAll(codePatterns);
    
    // Analyze configuration files
    final configPatterns = await _analyzeConfigurationWithContext(projectDir);
    patterns.addAll(configPatterns);
    
    // Remove duplicates and merge similar patterns
    return _mergeSimilarPatterns(patterns);
  }

  /// Analyze project structure with enhanced context awareness
  Future<List<ArchitecturePattern>> _analyzeStructureWithContext(
    Directory projectDir,
    DirectoryAnalysisResult? directoryResult,
  ) async {
    final patterns = <ArchitecturePattern>[];
    
    try {
      final libDir = Directory(path.join(projectDir.path, 'lib'));
      if (!await libDir.exists()) return patterns;
      
      // Use directory result if available, otherwise analyze
      final result = directoryResult ?? await const UnifiedDirectoryAnalyzer().analyze(projectDir);
      
      // Detect feature-first architecture with enhanced heuristics
      if (_hasFeatureFirstStructure(result)) {
        final confidence = _calculateFeatureFirstConfidence(result);
        patterns.add(ArchitecturePattern(
          name: 'feature-first',
          confidence: confidence,
          indicators: _getFeatureFirstIndicators(result),
          metadata: {
            'structure_type': 'feature-first',
            'feature_count': result.files.values.where((f) => f.type == 'screen').length,
            'has_domain_layer': _hasDomainLayer(result),
            'has_data_layer': _hasDataLayer(result),
          },
        ));
      }
      
      // Detect layer-first architecture with enhanced heuristics
      if (_hasLayerFirstStructure(result)) {
        final confidence = _calculateLayerFirstConfidence(result);
        patterns.add(ArchitecturePattern(
          name: 'layer-first',
          confidence: confidence,
          indicators: _getLayerFirstIndicators(result),
          metadata: {
            'structure_type': 'layer-first',
            'layer_count': _countLayers(result),
            'has_clean_architecture': _hasCleanArchitectureStructure(result),
          },
        ));
      }
      
      // Detect clean architecture with enhanced detection
      if (_hasCleanArchitectureStructure(result)) {
        final confidence = _calculateCleanArchitectureConfidence(result);
        patterns.add(ArchitecturePattern(
          name: 'clean-architecture',
          confidence: confidence,
          indicators: _getCleanArchitectureIndicators(result),
          metadata: {
            'structure_type': 'clean-architecture',
            'layer_completeness': _calculateLayerCompleteness(result),
            'dependency_direction': _analyzeDependencyDirection(result),
          },
        ));
      }
      
    } catch (e) {
      ErrorHandler.handleAnalyzerError('ArchitectureDetector', e);
    }
    
    return patterns;
  }

  /// Analyze dependencies with enhanced pattern detection
  Future<List<ArchitecturePattern>> _analyzeDependenciesWithContext(Directory projectDir) async {
    final patterns = <ArchitecturePattern>[];
    
    try {
      final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
      if (!await pubspecFile.exists()) return patterns;
      
      final content = await FileUtils.readFile(pubspecFile);
      if (content == null) return patterns;
      
      // Detect state management patterns with enhanced confidence
      final statePatterns = _detectStateManagementPatterns(content);
      patterns.addAll(statePatterns);
      
      // Detect navigation patterns
      final navPatterns = _detectNavigationPatterns(content);
      patterns.addAll(navPatterns);
      
      // Detect dependency injection patterns
      final diPatterns = _detectDependencyInjectionPatterns(content);
      patterns.addAll(diPatterns);
      
      // Detect testing patterns
      final testPatterns = _detectTestingPatterns(content);
      patterns.addAll(testPatterns);
      
    } catch (e) {
      ErrorHandler.handleAnalyzerError('ArchitectureDetector', e);
    }
    
    return patterns;
  }

  /// Analyze code patterns with AST context
  Future<List<ArchitecturePattern>> _analyzeCodePatternsWithContext(
    Directory projectDir,
    DirectoryAnalysisResult? directoryResult,
  ) async {
    final patterns = <ArchitecturePattern>[];
    
    try {
      final result = directoryResult ?? await const UnifiedDirectoryAnalyzer().analyze(projectDir);
      
      // Analyze key files for patterns
      final keyFiles = result.getFilesByImportance('high');
      for (final filePath in keyFiles) {
        final file = File(path.join(projectDir.path, filePath));
        if (await file.exists()) {
          final content = await FileUtils.readFile(file);
          if (content != null) {
            final filePatterns = _analyzeFilePatterns(content, filePath);
            patterns.addAll(filePatterns);
          }
        }
      }
      
    } catch (e) {
      ErrorHandler.handleAnalyzerError('ArchitectureDetector', e);
    }
    
    return patterns;
  }

  /// Analyze configuration files with enhanced detection
  Future<List<ArchitecturePattern>> _analyzeConfigurationWithContext(Directory projectDir) async {
    final patterns = <ArchitecturePattern>[];
    
    try {
      // Check for Fly manifest
      final flyManifest = File(path.join(projectDir.path, 'fly_project.yaml'));
      if (await flyManifest.exists()) {
        final content = await FileUtils.readFile(flyManifest);
        if (content != null) {
          patterns.add(ArchitecturePattern(
            name: 'fly',
            confidence: 0.95,
            indicators: ['fly_project.yaml', 'Fly framework'],
            metadata: {
              'framework': 'fly',
              'manifest': 'fly_project.yaml',
              'has_screens': content.contains('screens:'),
              'has_services': content.contains('services:'),
            },
          ));
        }
      }
      
      // Check for build configuration
      final buildYaml = File(path.join(projectDir.path, 'build.yaml'));
      if (await buildYaml.exists()) {
        patterns.add(const ArchitecturePattern(
          name: 'code-generation',
          confidence: 0.80,
          indicators: ['build.yaml', 'code generation'],
          metadata: {
            'build_system': 'build_runner',
            'config': 'build.yaml',
          },
        ));
      }
      
    } catch (e) {
      ErrorHandler.handleAnalyzerError('ArchitectureDetector', e);
    }
    
    return patterns;
  }

  /// Enhanced feature-first structure detection
  bool _hasFeatureFirstStructure(DirectoryAnalysisResult result) {
    final featureIndicators = [
      'features',
      'feature',
      'screens',
      'pages',
      'modules',
    ];
    
    // Check directory structure
    final hasFeatureDir = result.directories.keys.any((dir) => 
        featureIndicators.any((indicator) => dir.toLowerCase().contains(indicator)));
    
    // Check file organization
    final screenFiles = result.getFilesByType('screen');
    final hasScreenFiles = screenFiles.isNotEmpty;
    
    // Check for feature-based organization
    final hasFeatureOrganization = result.files.values.any((file) => 
        file.path.contains('features/') || file.path.contains('feature/'));
    
    return hasFeatureDir || (hasScreenFiles && hasFeatureOrganization);
  }

  /// Enhanced layer-first structure detection
  bool _hasLayerFirstStructure(DirectoryAnalysisResult result) {
    final layerIndicators = [
      'presentation',
      'domain',
      'data',
      'infrastructure',
      'application',
    ];
    
    return layerIndicators.any((indicator) => 
        result.directories.keys.any((dir) => dir.toLowerCase().contains(indicator)));
  }

  /// Enhanced clean architecture structure detection
  bool _hasCleanArchitectureStructure(DirectoryAnalysisResult result) {
    final cleanArchIndicators = [
      'domain',
      'data',
      'presentation',
      'infrastructure',
    ];
    
    final matches = cleanArchIndicators.where((indicator) => 
        result.directories.keys.any((dir) => dir.toLowerCase().contains(indicator))).length;
    
    return matches >= 3; // Need at least 3 layers
  }

  /// Calculate confidence for feature-first architecture
  double _calculateFeatureFirstConfidence(DirectoryAnalysisResult result) {
    double confidence = 0.0;
    
    // Base confidence for having features directory
    if (result.directories.keys.any((dir) => dir.contains('features'))) {
      confidence += 0.4;
    }
    
    // Confidence for screen files
    final screenCount = result.getFilesByType('screen').length;
    if (screenCount > 0) {
      confidence += 0.3;
    }
    
    // Confidence for feature organization
    final featureFiles = result.files.values.where((f) => f.path.contains('features/')).length;
    if (featureFiles > 0) {
      confidence += 0.3;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Calculate confidence for layer-first architecture
  double _calculateLayerFirstConfidence(DirectoryAnalysisResult result) {
    double confidence = 0.0;
    
    final layerIndicators = ['presentation', 'domain', 'data', 'infrastructure'];
    final layerCount = layerIndicators.where((indicator) => 
        result.directories.keys.any((dir) => dir.toLowerCase().contains(indicator))).length;
    
    confidence = layerCount / layerIndicators.length;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Calculate confidence for clean architecture
  double _calculateCleanArchitectureConfidence(DirectoryAnalysisResult result) {
    double confidence = 0.0;
    
    final cleanArchIndicators = ['domain', 'data', 'presentation', 'infrastructure'];
    final layerCount = cleanArchIndicators.where((indicator) => 
        result.directories.keys.any((dir) => dir.toLowerCase().contains(indicator))).length;
    
    // Base confidence from layer count
    confidence = layerCount / cleanArchIndicators.length;
    
    // Bonus for having all layers
    if (layerCount == cleanArchIndicators.length) {
      confidence += 0.2;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Detect state management patterns with enhanced analysis
  List<ArchitecturePattern> _detectStateManagementPatterns(String content) {
    final patterns = <ArchitecturePattern>[];
    
    // Riverpod detection with enhanced confidence
    if (content.contains('flutter_riverpod')) {
      double confidence = 0.95;
      if (content.contains('hooks_riverpod')) confidence += 0.05;
      if (content.contains('riverpod_annotation')) confidence += 0.05;
      
      patterns.add(ArchitecturePattern(
        name: 'riverpod',
        confidence: confidence.clamp(0.0, 1.0),
        indicators: ['flutter_riverpod dependency', 'riverpod state management'],
        metadata: {
          'state_management': 'riverpod',
          'dependency': 'flutter_riverpod',
          'has_hooks': content.contains('hooks_riverpod'),
          'has_annotations': content.contains('riverpod_annotation'),
        },
      ));
    }
    
    // BLoC detection with enhanced confidence
    if (content.contains('flutter_bloc')) {
      double confidence = 0.95;
      if (content.contains('bloc_test')) confidence += 0.05;
      
      patterns.add(ArchitecturePattern(
        name: 'bloc',
        confidence: confidence.clamp(0.0, 1.0),
        indicators: ['flutter_bloc dependency', 'bloc state management'],
        metadata: {
          'state_management': 'bloc',
          'dependency': 'flutter_bloc',
          'has_testing': content.contains('bloc_test'),
        },
      ));
    }
    
    // Provider detection
    if (content.contains('provider:')) {
      patterns.add(const ArchitecturePattern(
        name: 'provider',
        confidence: 0.90,
        indicators: ['provider dependency', 'provider state management'],
        metadata: {
          'state_management': 'provider',
          'dependency': 'provider',
        },
      ));
    }
    
    return patterns;
  }

  /// Detect navigation patterns
  List<ArchitecturePattern> _detectNavigationPatterns(String content) {
    final patterns = <ArchitecturePattern>[];
    
    if (content.contains('go_router')) {
      patterns.add(const ArchitecturePattern(
        name: 'go-router',
        confidence: 0.90,
        indicators: ['go_router dependency', 'declarative routing'],
        metadata: {
          'navigation': 'go-router',
          'dependency': 'go_router',
        },
      ));
    }
    
    if (content.contains('auto_route')) {
      patterns.add(const ArchitecturePattern(
        name: 'auto-route',
        confidence: 0.90,
        indicators: ['auto_route dependency', 'code generation routing'],
        metadata: {
          'navigation': 'auto-route',
          'dependency': 'auto_route',
        },
      ));
    }
    
    return patterns;
  }

  /// Detect dependency injection patterns
  List<ArchitecturePattern> _detectDependencyInjectionPatterns(String content) {
    final patterns = <ArchitecturePattern>[];
    
    if (content.contains('get_it')) {
      patterns.add(const ArchitecturePattern(
        name: 'get-it',
        confidence: 0.85,
        indicators: ['get_it dependency', 'service locator pattern'],
        metadata: {
          'dependency_injection': 'get-it',
          'dependency': 'get_it',
        },
      ));
    }
    
    if (content.contains('injectable')) {
      patterns.add(const ArchitecturePattern(
        name: 'injectable',
        confidence: 0.90,
        indicators: ['injectable dependency', 'code generation DI'],
        metadata: {
          'dependency_injection': 'injectable',
          'dependency': 'injectable',
        },
      ));
    }
    
    return patterns;
  }

  /// Detect testing patterns
  List<ArchitecturePattern> _detectTestingPatterns(String content) {
    final patterns = <ArchitecturePattern>[];
    
    if (content.contains('mockito') || content.contains('mocktail')) {
      patterns.add(ArchitecturePattern(
        name: 'mocking',
        confidence: 0.80,
        indicators: ['mocking framework', 'test doubles'],
        metadata: {
          'testing': 'mocking',
          'framework': content.contains('mockito') ? 'mockito' : 'mocktail',
        },
      ));
    }
    
    if (content.contains('integration_test')) {
      patterns.add(const ArchitecturePattern(
        name: 'integration-testing',
        confidence: 0.85,
        indicators: ['integration_test dependency', 'end-to-end testing'],
        metadata: {
          'testing': 'integration',
          'dependency': 'integration_test',
        },
      ));
    }
    
    return patterns;
  }

  /// Analyze file patterns with enhanced detection
  List<ArchitecturePattern> _analyzeFilePatterns(String content, String filePath) {
    final patterns = <ArchitecturePattern>[];
    
    // Enhanced MVVM pattern detection
    if (_hasEnhancedMVVMPattern(content)) {
      patterns.add(ArchitecturePattern(
        name: 'mvvm',
        confidence: 0.85,
        indicators: ['ViewModel', 'View', 'Model separation'],
        metadata: {
          'pattern': 'mvvm',
          'file': filePath,
          'has_viewmodel': content.contains('ViewModel'),
          'has_view': content.contains('View'),
        },
      ));
    }
    
    // Enhanced Repository pattern detection
    if (_hasEnhancedRepositoryPattern(content)) {
      patterns.add(ArchitecturePattern(
        name: 'repository',
        confidence: 0.90,
        indicators: ['Repository', 'data abstraction'],
        metadata: {
          'pattern': 'repository',
          'file': filePath,
          'is_abstract': content.contains('abstract class'),
          'has_implementation': content.contains('implements'),
        },
      ));
    }
    
    return patterns;
  }

  /// Enhanced MVVM pattern detection
  bool _hasEnhancedMVVMPattern(String content) {
    final mvvmIndicators = [
      'ViewModel',
      'viewmodel',
      'view_model',
      'extends ChangeNotifier',
      'extends StateNotifier',
      'class.*ViewModel',
    ];
    
    return mvvmIndicators.any((indicator) => 
        RegExp(indicator, caseSensitive: false).hasMatch(content));
  }

  /// Enhanced Repository pattern detection
  bool _hasEnhancedRepositoryPattern(String content) {
    final repoIndicators = [
      'Repository',
      'repository',
      'abstract class.*Repository',
      'implements.*Repository',
    ];
    
    return repoIndicators.any((indicator) => 
        RegExp(indicator, caseSensitive: false).hasMatch(content));
  }

  /// Helper methods for structure analysis
  bool _hasDomainLayer(DirectoryAnalysisResult result) => 
      result.directories.keys.any((dir) => dir.toLowerCase().contains('domain'));
  
  bool _hasDataLayer(DirectoryAnalysisResult result) => 
      result.directories.keys.any((dir) => dir.toLowerCase().contains('data'));
  
  int _countLayers(DirectoryAnalysisResult result) {
    final layerIndicators = ['presentation', 'domain', 'data', 'infrastructure'];
    return layerIndicators.where((indicator) => 
        result.directories.keys.any((dir) => dir.toLowerCase().contains(indicator))).length;
  }
  
  double _calculateLayerCompleteness(DirectoryAnalysisResult result) {
    final cleanArchIndicators = ['domain', 'data', 'presentation', 'infrastructure'];
    final layerCount = cleanArchIndicators.where((indicator) => 
        result.directories.keys.any((dir) => dir.toLowerCase().contains(indicator))).length;
    return layerCount / cleanArchIndicators.length;
  }
  
  String _analyzeDependencyDirection(DirectoryAnalysisResult result) {
    // Simplified dependency direction analysis
    return 'inward'; // Placeholder
  }

  /// Get indicators for different architecture patterns
  List<String> _getFeatureFirstIndicators(DirectoryAnalysisResult result) {
    final indicators = <String>['feature-based organization'];
    if (result.directories.keys.any((dir) => dir.contains('features'))) {
      indicators.add('features/ directory');
    }
    if (result.getFilesByType('screen').isNotEmpty) {
      indicators.add('screen files');
    }
    return indicators;
  }

  List<String> _getLayerFirstIndicators(DirectoryAnalysisResult result) {
    final indicators = <String>['layered organization'];
    final layerIndicators = ['presentation', 'domain', 'data', 'infrastructure'];
    for (final layer in layerIndicators) {
      if (result.directories.keys.any((dir) => dir.toLowerCase().contains(layer))) {
        indicators.add('$layer/ layer');
      }
    }
    return indicators;
  }

  List<String> _getCleanArchitectureIndicators(DirectoryAnalysisResult result) {
    final indicators = <String>['clean architecture layers'];
    final cleanArchIndicators = ['domain', 'data', 'presentation', 'infrastructure'];
    for (final layer in cleanArchIndicators) {
      if (result.directories.keys.any((dir) => dir.toLowerCase().contains(layer))) {
        indicators.add('$layer/ layer');
      }
    }
    return indicators;
  }

  /// Merge similar patterns to avoid duplicates
  List<ArchitecturePattern> _mergeSimilarPatterns(List<ArchitecturePattern> patterns) {
    final merged = <String, ArchitecturePattern>{};
    
    for (final pattern in patterns) {
      final key = pattern.name;
      if (merged.containsKey(key)) {
        // Merge patterns with same name, keeping the one with higher confidence
        final existing = merged[key]!;
        if (pattern.confidence > existing.confidence) {
          merged[key] = pattern;
        }
      } else {
        merged[key] = pattern;
      }
    }
    
    return merged.values.toList();
  }
}
