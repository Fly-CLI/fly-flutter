import 'package:fly_cli/src/generation/brick/brick_metadata.dart' show BrickCategory, BrickType, BrickValidationResult;
import 'package:fly_cli/src/generation/domain/value_objects/brick_variable.dart';
import 'package:fly_cli/src/generation/brick/brick_registry.dart' show BrickValidationResult;
import 'package:fly_cli/src/generation/domain/entities/brick.dart';

/// Domain service for brick validation.
///
/// Contains business rules for validating bricks.
abstract class IBrickValidator {
  /// Validate a brick.
  ///
  /// Returns a validation result with errors and warnings.
  BrickValidationResult validate(Brick brick);

  /// Validate brick name format.
  bool isValidName(String name);

  /// Validate brick path exists and is accessible.
  Future<bool> isValidPath(String path);

  /// Validate brick variables.
  List<String> validateVariables(Brick brick);
}

/// Implementation of brick validator.
class BrickValidator implements IBrickValidator {
  const BrickValidator();

  @override
  BrickValidationResult validate(Brick brick) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate name
    if (!isValidName(brick.name)) {
      errors.add('Invalid brick name: ${brick.name}');
    }

    // Validate description
    if (brick.description.isEmpty) {
      errors.add('Brick description is required');
    }

    // Validate path
    if (brick.path.isEmpty) {
      errors.add('Brick path is required');
    }

    // Validate type and category consistency
    final typeCategoryErrors = _validateTypeCategoryConsistency(brick);
    errors.addAll(typeCategoryErrors);

    // Validate variables
    final variableErrors = validateVariables(brick);
    errors.addAll(variableErrors);

    // Validate version format (warnings only)
    if (brick.version.isPreRelease) {
      warnings.add('Brick version is a pre-release: ${brick.version}');
    }

    return BrickValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  @override
  bool isValidName(String name) {
    // Brick names should be lowercase, alphanumeric with underscores/hyphens
    final pattern = RegExp(r'^[a-z][a-z0-9_-]*$');
    return pattern.hasMatch(name) && name.length >= 3 && name.length <= 50;
  }

  @override
  Future<bool> isValidPath(String path) async {
    // This would check if path exists - implementation depends on file system adapter
    // For now, just check if path is not empty
    return path.isNotEmpty;
  }

  @override
  List<String> validateVariables(Brick brick) {
    final errors = <String>[];

    // Check for duplicate variable names
    final variableNames = brick.variables.keys.toList();
    final duplicates = variableNames
        .where((name) => variableNames.where((n) => n == name).length > 1)
        .toSet();
    if (duplicates.isNotEmpty) {
      errors.add('Duplicate variable names: ${duplicates.join(', ')}');
    }

    // Validate each variable
    for (final entry in brick.variables.entries) {
      final variable = entry.value;
      if (variable.name.isEmpty) {
        errors.add('Variable name cannot be empty');
      }
      if (variable.required && variable.defaultValue != null) {
        errors.add(
          'Variable ${variable.name} is required but has a default value',
        );
      }
    }

    return errors;
  }

  /// Validate type and category consistency.
  List<String> _validateTypeCategoryConsistency(Brick brick) {
    final errors = <String>[];

    switch (brick.category) {
      case BrickCategory.project:
        if (brick.type != BrickType.project) {
          errors.add('Project category must have project type');
        }
        break;
      case BrickCategory.component:
        if (![
          BrickType.feature,
          BrickType.service,
          BrickType.component,
        ].contains(brick.type)) {
          errors.add(
            'Component category must have feature, service, or component type',
          );
        }
        break;
      case BrickCategory.addon:
        if (brick.type != BrickType.custom) {
          errors.add('Addon category must have custom type');
        }
        break;
    }

    return errors;
  }
}

