/// Data models for project analysis and context generation
library analysis_models;

import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

/// Configuration for context generation
class ContextGeneratorConfig {
  const ContextGeneratorConfig({
    this.includeCode = false,
    this.includeDependencies = false,
    this.maxFileSize = 10000,
    this.maxFiles = 50,
    this.includeArchitecture = true,
    this.includeSuggestions = true,
    this.includeTests = false,
    this.includeGenerated = false,
  });

  /// Whether to include source code content
  final bool includeCode;

  /// Whether to include dependency information
  final bool includeDependencies;

  /// Maximum file size to include (in bytes)
  final int maxFileSize;

  /// Maximum number of files to analyze
  final int maxFiles;

  /// Whether to include architecture analysis
  final bool includeArchitecture;

  /// Whether to generate suggestions
  final bool includeSuggestions;

  /// Whether to include test files
  final bool includeTests;

  /// Whether to include generated files
  final bool includeGenerated;

  /// Create a copy with modified fields
  ContextGeneratorConfig copyWith({
    bool? includeCode,
    bool? includeDependencies,
    int? maxFileSize,
    int? maxFiles,
    bool? includeArchitecture,
    bool? includeSuggestions,
    bool? includeTests,
    bool? includeGenerated,
  }) => ContextGeneratorConfig(
    includeCode: includeCode ?? this.includeCode,
    includeDependencies: includeDependencies ?? this.includeDependencies,
    maxFileSize: maxFileSize ?? this.maxFileSize,
    maxFiles: maxFiles ?? this.maxFiles,
    includeArchitecture: includeArchitecture ?? this.includeArchitecture,
    includeSuggestions: includeSuggestions ?? this.includeSuggestions,
    includeTests: includeTests ?? this.includeTests,
    includeGenerated: includeGenerated ?? this.includeGenerated,
  );
}

/// Project metadata and information
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ProjectInfo {
  const ProjectInfo({
    required this.name,
    required this.type,
    required this.version,
    this.template,
    this.organization,
    this.description,
    this.platforms = const ['ios', 'android'],
    this.flutterVersion,
    this.dartVersion,
    this.isFlyProject = false,
    this.hasManifest = false,
    this.creationDate,
  });

  factory ProjectInfo.fromJson(Map<String, dynamic> json) =>
      _$ProjectInfoFromJson(json);

  /// Project name from pubspec.yaml
  final String name;

  /// Project type: 'fly' or 'flutter'
  final String type;

  /// Project version
  final String version;

  /// Fly template used (if Fly project)
  final String? template;

  /// Organization identifier
  final String? organization;

  /// Project description
  final String? description;

  /// Target platforms
  final List<String> platforms;

  /// Flutter SDK version constraint
  @JsonKey(name: 'flutter_version')
  final String? flutterVersion;

  /// Dart SDK version constraint
  @JsonKey(name: 'dart_version')
  final String? dartVersion;

  /// Whether this is a Fly-generated project
  @JsonKey(name: 'is_fly_project')
  final bool isFlyProject;

  /// Whether project has a fly_project.yaml manifest
  @JsonKey(name: 'has_manifest')
  final bool hasManifest;

  /// Project creation date (if available)
  @JsonKey(name: 'created_at')
  final DateTime? creationDate;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ProjectInfoToJson(this);
}

/// Project structure information
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class StructureInfo {
  const StructureInfo({
    required this.rootDirectory,
    required this.directories,
    required this.features,
    required this.totalFiles,
    required this.linesOfCode,
    required this.fileTypes,
    this.architecturePattern,
    this.conventions = const [],
  });

  factory StructureInfo.fromJson(Map<String, dynamic> json) =>
      _$StructureInfoFromJson(json);

  /// Root directory path
  @JsonKey(name: 'root_directory')
  final String rootDirectory;

  /// Directory structure with file counts
  final Map<String, DirectoryInfo> directories;

  /// Detected features
  final List<String> features;

  /// Total number of files
  @JsonKey(name: 'total_files')
  final int totalFiles;

  /// Total lines of code
  @JsonKey(name: 'lines_of_code')
  final int linesOfCode;

  /// File counts by type
  @JsonKey(name: 'file_types')
  final Map<String, int> fileTypes;

  /// Detected architecture pattern
  @JsonKey(name: 'architecture_pattern')
  final String? architecturePattern;

  /// Detected conventions
  final List<String> conventions;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$StructureInfoToJson(this);
}

/// Directory information
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class DirectoryInfo {
  const DirectoryInfo({
    required this.files,
    required this.dartFiles,
    this.subdirectories = const [],
  });

  factory DirectoryInfo.fromJson(Map<String, dynamic> json) =>
      _$DirectoryInfoFromJson(json);

  /// Total files in directory
  final int files;

  /// Dart files in directory
  @JsonKey(name: 'dart_files')
  final int dartFiles;

  /// Subdirectories
  final List<String> subdirectories;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$DirectoryInfoToJson(this);
}

/// Dependency information
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class DependencyInfo {
  const DependencyInfo({
    required this.dependencies,
    required this.devDependencies,
    required this.categories,
    required this.flyPackages,
    this.warnings = const [],
    this.conflicts = const [],
  });

  factory DependencyInfo.fromJson(Map<String, dynamic> json) =>
      _$DependencyInfoFromJson(json);

  /// Main dependencies
  final Map<String, String> dependencies;

  /// Development dependencies
  @JsonKey(name: 'dev_dependencies')
  final Map<String, String> devDependencies;

  /// Dependencies categorized by type
  final Map<String, List<String>> categories;

  /// Fly packages detected
  @JsonKey(name: 'fly_packages')
  final List<String> flyPackages;

  /// Dependency warnings
  final List<DependencyWarning> warnings;

  /// Version conflicts
  final List<String> conflicts;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$DependencyInfoToJson(this);
}

/// Dependency warning
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class DependencyWarning {
  const DependencyWarning({
    required this.package,
    required this.message,
    required this.severity,
  });

  factory DependencyWarning.fromJson(Map<String, dynamic> json) =>
      _$DependencyWarningFromJson(json);

  /// Package name
  final String package;

  /// Warning message
  final String message;

  /// Warning severity: 'low', 'medium', 'high'
  final String severity;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$DependencyWarningToJson(this);
}

/// Code analysis information
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CodeInfo {
  const CodeInfo({
    required this.keyFiles,
    required this.fileContents,
    required this.metrics,
    required this.imports,
    required this.patterns,
  });

  factory CodeInfo.fromJson(Map<String, dynamic> json) =>
      _$CodeInfoFromJson(json);

  /// Key source files identified
  @JsonKey(name: 'key_files')
  final List<SourceFile> keyFiles;

  /// File contents (if includeCode is true)
  @JsonKey(name: 'file_contents')
  final Map<String, String> fileContents;

  /// Code metrics
  final Map<String, int> metrics;

  /// Import analysis
  final Map<String, List<String>> imports;

  /// Detected patterns
  final List<String> patterns;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$CodeInfoToJson(this);
}

/// Source file information
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SourceFile {
  const SourceFile({
    required this.path,
    required this.name,
    required this.type,
    required this.linesOfCode,
    this.importance = 'medium',
    this.description,
  });

  factory SourceFile.fromJson(Map<String, dynamic> json) =>
      _$SourceFileFromJson(json);

  /// File path relative to project root
  final String path;

  /// File name
  final String name;

  /// File type: 'main', 'screen', 'service', 'test', etc.
  final String type;

  /// Lines of code
  @JsonKey(name: 'lines_of_code')
  final int linesOfCode;

  /// Importance level: 'high', 'medium', 'low'
  final String importance;

  /// Description of file purpose
  final String? description;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$SourceFileToJson(this);
}

/// Architecture information
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ArchitectureInfo {
  const ArchitectureInfo({
    required this.pattern,
    required this.conventions,
    required this.stateManagement,
    required this.routing,
    required this.dependencyInjection,
    this.frameworks = const [],
  });

  factory ArchitectureInfo.fromJson(Map<String, dynamic> json) =>
      _$ArchitectureInfoFromJson(json);

  /// Architecture pattern: 'riverpod', 'bloc', 'provider', etc.
  final String pattern;

  /// Detected conventions
  final List<String> conventions;

  /// State management approach
  @JsonKey(name: 'state_management')
  final String stateManagement;

  /// Routing solution
  final String routing;

  /// Dependency injection approach
  @JsonKey(name: 'dependency_injection')
  final String dependencyInjection;

  /// Additional frameworks
  final List<String> frameworks;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ArchitectureInfoToJson(this);
}

/// Manifest information (for Fly projects)
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ManifestInfo {
  const ManifestInfo({
    required this.name,
    required this.template,
    required this.organization,
    this.description,
    this.platforms = const ['ios', 'android'],
    this.screens = const [],
    this.services = const [],
    this.packages = const [],
  });

  factory ManifestInfo.fromJson(Map<String, dynamic> json) =>
      _$ManifestInfoFromJson(json);

  /// Project name from manifest
  final String name;

  /// Template used
  final String template;

  /// Organization identifier
  final String organization;

  /// Project description
  final String? description;

  /// Target platforms
  final List<String> platforms;

  /// Configured screens
  final List<ManifestScreen> screens;

  /// Configured services
  final List<ManifestService> services;

  /// Additional packages
  final List<String> packages;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ManifestInfoToJson(this);
}

/// Manifest screen configuration
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ManifestScreen {
  const ManifestScreen({
    required this.name,
    this.type,
    this.features = const [],
  });

  factory ManifestScreen.fromJson(Map<String, dynamic> json) =>
      _$ManifestScreenFromJson(json);

  /// Screen name
  final String name;

  /// Screen type
  final String? type;

  /// Associated features
  final List<String> features;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ManifestScreenToJson(this);
}

/// Manifest service configuration
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ManifestService {
  const ManifestService({
    required this.name,
    this.type,
    this.apiBase,
    this.features = const [],
  });

  factory ManifestService.fromJson(Map<String, dynamic> json) =>
      _$ManifestServiceFromJson(json);

  /// Service name
  final String name;

  /// Service type
  final String? type;

  /// API base URL
  @JsonKey(name: 'api_base')
  final String? apiBase;

  /// Associated features
  final List<String> features;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ManifestServiceToJson(this);
}

/// Pubspec information
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PubspecInfo {
  const PubspecInfo({
    required this.name,
    required this.version,
    this.description,
    this.homepage,
    this.repository,
    this.environment,
    this.dependencies = const {},
    this.devDependencies = const {},
  });

  factory PubspecInfo.fromJson(Map<String, dynamic> json) =>
      _$PubspecInfoFromJson(json);

  /// Project name
  final String name;

  /// Project version
  final String version;

  /// Project description
  final String? description;

  /// Homepage URL
  final String? homepage;

  /// Repository URL
  final String? repository;

  /// Environment constraints
  final Map<String, String>? environment;

  /// Dependencies
  final Map<String, String> dependencies;

  /// Development dependencies
  @JsonKey(name: 'dev_dependencies')
  final Map<String, String> devDependencies;

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$PubspecInfoToJson(this);
}

/// Complexity metrics for code analysis
@JsonSerializable()
class ComplexityMetrics {
  const ComplexityMetrics({
    required this.cyclomaticComplexity,
    required this.cognitiveComplexity,
    required this.maintainabilityIndex,
  });

  factory ComplexityMetrics.fromJson(Map<String, dynamic> json) =>
      _$ComplexityMetricsFromJson(json);

  @JsonKey(name: 'cyclomatic_complexity')
  final int cyclomaticComplexity;
  
  @JsonKey(name: 'cognitive_complexity')
  final int cognitiveComplexity;
  
  @JsonKey(name: 'maintainability_index')
  final double maintainabilityIndex;

  Map<String, dynamic> toJson() => _$ComplexityMetricsToJson(this);
}

/// Quality report for code analysis
@JsonSerializable()
class QualityReport {
  const QualityReport({
    required this.issues,
    required this.deadCode,
    required this.duplicatedCode,
    required this.overallScore,
  });

  factory QualityReport.fromJson(Map<String, dynamic> json) =>
      _$QualityReportFromJson(json);

  final List<QualityIssue> issues;
  
  @JsonKey(name: 'dead_code')
  final List<String> deadCode;
  
  @JsonKey(name: 'duplicated_code')
  final List<DuplicatedCode> duplicatedCode;
  
  @JsonKey(name: 'overall_score')
  final double overallScore;

  Map<String, dynamic> toJson() => _$QualityReportToJson(this);
}

/// Quality issue found during analysis
@JsonSerializable()
class QualityIssue {
  const QualityIssue({
    required this.type,
    required this.message,
    required this.severity,
    required this.line,
    required this.file,
  });

  factory QualityIssue.fromJson(Map<String, dynamic> json) =>
      _$QualityIssueFromJson(json);

  final String type;
  final String message;
  final String severity;
  final int line;
  final String file;

  Map<String, dynamic> toJson() => _$QualityIssueToJson(this);
}

/// Duplicated code block
@JsonSerializable()
class DuplicatedCode {
  const DuplicatedCode({
    required this.file1,
    required this.file2,
    required this.lines1,
    required this.lines2,
    required this.similarity,
  });

  factory DuplicatedCode.fromJson(Map<String, dynamic> json) =>
      _$DuplicatedCodeFromJson(json);

  final String file1;
  final String file2;
  final int lines1;
  final int lines2;
  final int similarity;

  Map<String, dynamic> toJson() => _$DuplicatedCodeToJson(this);
}

/// Enhanced architecture pattern with confidence score
@JsonSerializable()
class ArchitecturePattern {
  const ArchitecturePattern({
    required this.name,
    required this.confidence,
    required this.indicators,
    required this.metadata,
  });

  factory ArchitecturePattern.fromJson(Map<String, dynamic> json) =>
      _$ArchitecturePatternFromJson(json);

  final String name;
  final double confidence;
  final List<String> indicators;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => _$ArchitecturePatternToJson(this);
}

/// Dependency health information
@JsonSerializable()
class DependencyHealth {
  const DependencyHealth({
    required this.package,
    required this.healthScore,
    required this.vulnerabilities,
    required this.license,
    required this.isMaintained,
    required this.popularity,
  });

  factory DependencyHealth.fromJson(Map<String, dynamic> json) =>
      _$DependencyHealthFromJson(json);

  final String package;
  
  @JsonKey(name: 'health_score')
  final double healthScore;
  
  final List<String> vulnerabilities;
  final String license;
  
  @JsonKey(name: 'is_maintained')
  final bool isMaintained;
  
  final int popularity;

  Map<String, dynamic> toJson() => _$DependencyHealthToJson(this);
}

/// Performance metrics for analysis
@JsonSerializable()
class PerformanceMetrics {
  const PerformanceMetrics({
    required this.analysisTime,
    required this.memoryUsage,
    required this.filesProcessed,
    required this.linesOfCode,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$PerformanceMetricsFromJson(json);

  @JsonKey(name: 'analysis_time_ms')
  final Duration analysisTime;
  
  @JsonKey(name: 'memory_usage_mb')
  final int memoryUsage;
  
  @JsonKey(name: 'files_processed')
  final int filesProcessed;
  
  @JsonKey(name: 'lines_of_code')
  final int linesOfCode;

  Map<String, dynamic> toJson() => _$PerformanceMetricsToJson(this);
}
