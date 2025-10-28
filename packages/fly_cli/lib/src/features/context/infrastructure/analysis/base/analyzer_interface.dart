import 'dart:io';

import 'package:fly_cli/src/features/context/domain/models/models.dart';

/// Base interface for all analyzers in the context infrastructure
abstract class Analyzer<T> {
  /// The name of this analyzer for logging and identification
  String get name;

  /// Whether this analyzer is enabled by default
  bool get isEnabled => true;

  /// The priority of this analyzer (lower numbers run first)
  int get priority => 100;

  /// Analyze the given project directory and return results
  Future<T> analyze(
    Directory projectDir,
    ContextGeneratorConfig config,
  );

  /// Whether this analyzer should run based on the configuration
  bool shouldRun(ContextGeneratorConfig config) => isEnabled;

  /// Get dependencies required by this analyzer
  List<String> get dependencies => [];

  /// Get the configuration keys this analyzer uses
  List<String> get configKeys => [];
}

/// Base class for analyzers that analyze project structure
abstract class ProjectAnalyzer<T> extends Analyzer<T> {
  @override
  int get priority => 10; // High priority for project analysis
}

/// Base class for analyzers that analyze code files
abstract class CodeAnalyzer<T> extends Analyzer<T> {
  @override
  int get priority => 50; // Medium priority for code analysis

  @override
  bool shouldRun(ContextGeneratorConfig config) => 
      isEnabled && config.includeCode;
}

/// Base class for analyzers that analyze dependencies
abstract class DependencyAnalyzer<T> extends Analyzer<T> {
  @override
  int get priority => 30; // Medium-high priority for dependency analysis

  @override
  bool shouldRun(ContextGeneratorConfig config) => 
      isEnabled && config.includeDependencies;
}

/// Base class for analyzers that analyze architecture patterns
abstract class ArchitectureAnalyzer<T> extends Analyzer<T> {
  @override
  int get priority => 40; // Medium priority for architecture analysis

  @override
  bool shouldRun(ContextGeneratorConfig config) => 
      isEnabled && config.includeArchitecture;
}

/// Registry for managing analyzers
class AnalyzerRegistry {
  factory AnalyzerRegistry() => _instance;
  AnalyzerRegistry._internal();
  static final AnalyzerRegistry _instance = AnalyzerRegistry._internal();

  final List<Analyzer> _analyzers = [];

  /// Register an analyzer
  void register(Analyzer analyzer) {
    _analyzers.add(analyzer);
    _analyzers.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Get all analyzers that should run for the given config
  List<Analyzer> getAnalyzers(ContextGeneratorConfig config) {
    return _analyzers
        .where((analyzer) => analyzer.shouldRun(config))
        .toList();
  }

  /// Get analyzers by type
  List<T> getAnalyzersByType<T extends Analyzer>() {
    return _analyzers.whereType<T>().toList();
  }

  /// Clear all registered analyzers
  void clear() {
    _analyzers.clear();
  }
}
