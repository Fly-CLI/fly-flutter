import 'dart:io';
import 'package:path/path.dart' as path;

/// Immutable path result with validation status
abstract class ResolvedPath {
  /// Absolute path
  String get absolute;
  
  /// Relative path from working directory
  String get relative;
  
  /// Whether the path exists
  bool get exists;
  
  /// Whether the path is writable
  bool get writable;
  
  /// Whether the path is valid
  bool get isValid;
  
  /// Validation errors if any
  List<String> get validationErrors;
  
  /// Create a new path with updated validation status
  ResolvedPath copyWith({
    bool? exists,
    bool? writable,
    List<String>? validationErrors,
  });
}

/// Working directory path
class WorkingDirectoryPath extends ResolvedPath {
  WorkingDirectoryPath({
    required this.absolute,
    required this.exists,
    required this.writable,
    this.validationErrors = const [],
  });

  @override
  final String absolute;

  @override
  String get relative => path.relative(absolute, from: Directory.current.path);

  @override
  final bool exists;

  @override
  final bool writable;

  @override
  bool get isValid => validationErrors.isEmpty;

  @override
  final List<String> validationErrors;

  @override
  WorkingDirectoryPath copyWith({
    bool? exists,
    bool? writable,
    List<String>? validationErrors,
  }) {
    return WorkingDirectoryPath(
      absolute: absolute,
      exists: exists ?? this.exists,
      writable: writable ?? this.writable,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  String toString() => 'WorkingDirectoryPath(absolute: $absolute, exists: $exists, writable: $writable)';
}

/// Template directory path
class TemplatePath extends ResolvedPath {
  TemplatePath({
    required this.absolute,
    required this.exists,
    required this.writable,
    this.validationErrors = const [],
  });

  @override
  final String absolute;

  @override
  String get relative => path.relative(absolute, from: Directory.current.path);

  @override
  final bool exists;

  @override
  final bool writable;

  @override
  bool get isValid => validationErrors.isEmpty;

  @override
  final List<String> validationErrors;

  @override
  TemplatePath copyWith({
    bool? exists,
    bool? writable,
    List<String>? validationErrors,
  }) {
    return TemplatePath(
      absolute: absolute,
      exists: exists ?? this.exists,
      writable: writable ?? this.writable,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  String toString() => 'TemplatePath(absolute: $absolute, exists: $exists, writable: $writable)';
}

/// Project directory path
class ProjectPath extends ResolvedPath {
  ProjectPath({
    required this.absolute,
    required this.projectName,
    required this.exists,
    required this.writable,
    this.validationErrors = const [],
  });

  @override
  final String absolute;

  @override
  String get relative => path.relative(absolute, from: Directory.current.path);

  @override
  final bool exists;

  @override
  final bool writable;

  @override
  bool get isValid => validationErrors.isEmpty;

  @override
  final List<String> validationErrors;

  /// The project name
  final String projectName;

  @override
  ProjectPath copyWith({
    bool? exists,
    bool? writable,
    List<String>? validationErrors,
  }) {
    return ProjectPath(
      absolute: absolute,
      projectName: projectName,
      exists: exists ?? this.exists,
      writable: writable ?? this.writable,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  String toString() => 'ProjectPath(absolute: $absolute, projectName: $projectName, exists: $exists, writable: $writable)';
}

/// Component directory path (screen, service, etc.)
class ComponentPath extends ResolvedPath {
  ComponentPath({
    required this.absolute,
    required this.componentName,
    required this.componentType,
    required this.feature,
    required this.exists,
    required this.writable,
    this.validationErrors = const [],
  });

  @override
  final String absolute;

  @override
  String get relative => path.relative(absolute, from: Directory.current.path);

  @override
  final bool exists;

  @override
  final bool writable;

  @override
  bool get isValid => validationErrors.isEmpty;

  @override
  final List<String> validationErrors;

  /// The component name
  final String componentName;

  /// The component type (screen, service, etc.)
  final String componentType;

  /// The feature name
  final String feature;

  @override
  ComponentPath copyWith({
    bool? exists,
    bool? writable,
    List<String>? validationErrors,
  }) {
    return ComponentPath(
      absolute: absolute,
      componentName: componentName,
      componentType: componentType,
      feature: feature,
      exists: exists ?? this.exists,
      writable: writable ?? this.writable,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  String toString() => 'ComponentPath(absolute: $absolute, componentName: $componentName, componentType: $componentType, feature: $feature, exists: $exists, writable: $writable)';
}

/// Path resolution result
class PathResolutionResult {
  const PathResolutionResult({
    required this.success,
    this.path,
    this.errors = const [],
  });

  final bool success;
  final ResolvedPath? path;
  final List<String> errors;

  factory PathResolutionResult.success(ResolvedPath path) {
    return PathResolutionResult(success: true, path: path);
  }

  factory PathResolutionResult.failure(List<String> errors) {
    return PathResolutionResult(success: false, errors: errors);
  }

  @override
  String toString() => 'PathResolutionResult(success: $success, path: $path, errors: $errors)';
}
