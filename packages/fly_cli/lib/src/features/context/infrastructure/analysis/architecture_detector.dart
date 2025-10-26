import 'dart:io';
import 'package:path/path.dart' as path;

import '../../domain/models/models.dart' show ArchitecturePattern;


/// Advanced architecture pattern detector with ML-style heuristics
class ArchitectureDetector {
  const ArchitectureDetector();

  /// Detect architecture patterns in a project
  Future<List<ArchitecturePattern>> detectPatterns(Directory projectDir) async {
    final patterns = <ArchitecturePattern>[];
    
    // Analyze project structure
    final structurePatterns = await _analyzeStructure(projectDir);
    patterns.addAll(structurePatterns);
    
    // Analyze dependencies
    final dependencyPatterns = await _analyzeDependencies(projectDir);
    patterns.addAll(dependencyPatterns);
    
    // Analyze code patterns
    final codePatterns = await _analyzeCodePatterns(projectDir);
    patterns.addAll(codePatterns);
    
    // Analyze configuration files
    final configPatterns = await _analyzeConfiguration(projectDir);
    patterns.addAll(configPatterns);
    
    return patterns;
  }

  /// Analyze project structure for architecture patterns
  Future<List<ArchitecturePattern>> _analyzeStructure(Directory projectDir) async {
    final patterns = <ArchitecturePattern>[];
    
    try {
      final libDir = Directory(path.join(projectDir.path, 'lib'));
      if (!await libDir.exists()) return patterns;
      
      final directories = <String>[];
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is Directory) {
          directories.add(path.basename(entity.path));
        }
      }
      
      // Detect feature-first architecture
      if (_hasFeatureFirstStructure(directories)) {
        patterns.add(ArchitecturePattern(
          name: 'feature-first',
          confidence: 0.85,
          indicators: ['features/', 'lib/features/', 'feature-based organization'],
          metadata: {
            'structure_type': 'feature-first',
            'directories': directories,
          },
        ));
      }
      
      // Detect layer-first architecture
      if (_hasLayerFirstStructure(directories)) {
        patterns.add(ArchitecturePattern(
          name: 'layer-first',
          confidence: 0.80,
          indicators: ['presentation/', 'domain/', 'data/', 'layered organization'],
          metadata: {
            'structure_type': 'layer-first',
            'directories': directories,
          },
        ));
      }
      
      // Detect clean architecture
      if (_hasCleanArchitectureStructure(directories)) {
        patterns.add(ArchitecturePattern(
          name: 'clean-architecture',
          confidence: 0.90,
          indicators: ['domain/', 'data/', 'presentation/', 'clean architecture layers'],
          metadata: {
            'structure_type': 'clean-architecture',
            'directories': directories,
          },
        ));
      }
      
    } catch (e) {
      // Skip if analysis fails
    }
    
    return patterns;
  }

  /// Analyze dependencies for architecture patterns
  Future<List<ArchitecturePattern>> _analyzeDependencies(Directory projectDir) async {
    final patterns = <ArchitecturePattern>[];
    
    try {
      final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
      if (!await pubspecFile.exists()) return patterns;
      
      final content = await pubspecFile.readAsString();
      
      // Detect state management patterns
      if (content.contains('flutter_riverpod')) {
        patterns.add(const ArchitecturePattern(
          name: 'riverpod',
          confidence: 0.95,
          indicators: ['flutter_riverpod dependency', 'riverpod state management'],
          metadata: {
            'state_management': 'riverpod',
            'dependency': 'flutter_riverpod',
          },
        ));
      }
      
      if (content.contains('flutter_bloc')) {
        patterns.add(const ArchitecturePattern(
          name: 'bloc',
          confidence: 0.95,
          indicators: ['flutter_bloc dependency', 'bloc state management'],
          metadata: {
            'state_management': 'bloc',
            'dependency': 'flutter_bloc',
          },
        ));
      }
      
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
      
      // Detect navigation patterns
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
      
      // Detect dependency injection patterns
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
      
    } catch (e) {
      // Skip if analysis fails
    }
    
    return patterns;
  }

  /// Analyze code patterns for architecture detection
  Future<List<ArchitecturePattern>> _analyzeCodePatterns(Directory projectDir) async {
    final patterns = <ArchitecturePattern>[];
    
    try {
      final libDir = Directory(path.join(projectDir.path, 'lib'));
      if (!await libDir.exists()) return patterns;
      
      // Look for common architecture patterns in code
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = await entity.readAsString();
          
          // Detect MVVM pattern
          if (_hasMVVMPattern(content)) {
            patterns.add(ArchitecturePattern(
              name: 'mvvm',
              confidence: 0.80,
              indicators: ['ViewModel', 'View', 'Model separation'],
              metadata: {
                'pattern': 'mvvm',
                'file': entity.path,
              },
            ));
          }
          
          // Detect Repository pattern
          if (_hasRepositoryPattern(content)) {
            patterns.add(ArchitecturePattern(
              name: 'repository',
              confidence: 0.85,
              indicators: ['Repository', 'data abstraction'],
              metadata: {
                'pattern': 'repository',
                'file': entity.path,
              },
            ));
          }
          
          // Detect Factory pattern
          if (_hasFactoryPattern(content)) {
            patterns.add(ArchitecturePattern(
              name: 'factory',
              confidence: 0.75,
              indicators: ['Factory', 'object creation'],
              metadata: {
                'pattern': 'factory',
                'file': entity.path,
              },
            ));
          }
          
          // Detect Singleton pattern
          if (_hasSingletonPattern(content)) {
            patterns.add(ArchitecturePattern(
              name: 'singleton',
              confidence: 0.70,
              indicators: ['Singleton', 'single instance'],
              metadata: {
                'pattern': 'singleton',
                'file': entity.path,
              },
            ));
          }
        }
      }
      
    } catch (e) {
      // Skip if analysis fails
    }
    
    return patterns;
  }

  /// Analyze configuration files for architecture patterns
  Future<List<ArchitecturePattern>> _analyzeConfiguration(Directory projectDir) async {
    final patterns = <ArchitecturePattern>[];
    
    try {
      // Check for Fly manifest
      final flyManifest = File(path.join(projectDir.path, 'fly_project.yaml'));
      if (await flyManifest.exists()) {
        patterns.add(const ArchitecturePattern(
          name: 'fly-framework',
          confidence: 0.95,
          indicators: ['fly_project.yaml', 'Fly framework'],
          metadata: {
            'framework': 'fly',
            'manifest': 'fly_project.yaml',
          },
        ));
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
      // Skip if analysis fails
    }
    
    return patterns;
  }

  /// Check if project has feature-first structure
  bool _hasFeatureFirstStructure(List<String> directories) {
    final featureIndicators = [
      'features',
      'feature',
      'screens',
      'pages',
      'modules',
    ];
    
    return featureIndicators.any((indicator) => 
        directories.any((dir) => dir.toLowerCase().contains(indicator)));
  }

  /// Check if project has layer-first structure
  bool _hasLayerFirstStructure(List<String> directories) {
    final layerIndicators = [
      'presentation',
      'domain',
      'data',
      'infrastructure',
      'application',
    ];
    
    return layerIndicators.any((indicator) => 
        directories.any((dir) => dir.toLowerCase().contains(indicator)));
  }

  /// Check if project has clean architecture structure
  bool _hasCleanArchitectureStructure(List<String> directories) {
    final cleanArchIndicators = [
      'domain',
      'data',
      'presentation',
      'infrastructure',
    ];
    
    final matches = cleanArchIndicators.where((indicator) => 
        directories.any((dir) => dir.toLowerCase().contains(indicator))).length;
    
    return matches >= 3; // Need at least 3 layers
  }

  /// Check if code has MVVM pattern
  bool _hasMVVMPattern(String content) {
    final mvvmIndicators = [
      'ViewModel',
      'viewmodel',
      'view_model',
      'extends ChangeNotifier',
      'extends StateNotifier',
    ];
    
    return mvvmIndicators.any((indicator) => content.contains(indicator));
  }

  /// Check if code has Repository pattern
  bool _hasRepositoryPattern(String content) {
    final repoIndicators = [
      'Repository',
      'repository',
      'abstract class',
      'implements',
    ];
    
    return repoIndicators.any((indicator) => content.contains(indicator));
  }

  /// Check if code has Factory pattern
  bool _hasFactoryPattern(String content) {
    final factoryIndicators = [
      'Factory',
      'factory',
      'create',
      'build',
    ];
    
    return factoryIndicators.any((indicator) => content.contains(indicator));
  }

  /// Check if code has Singleton pattern
  bool _hasSingletonPattern(String content) {
    final singletonIndicators = [
      'Singleton',
      'singleton',
      'instance',
      'static',
    ];
    
    return singletonIndicators.any((indicator) => content.contains(indicator));
  }
}
