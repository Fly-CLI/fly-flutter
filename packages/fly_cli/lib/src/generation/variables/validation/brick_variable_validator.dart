import 'package:fly_cli/src/generation/domain/entities/brick.dart';

/// Validator for brick-level variable validation.
///
/// Handles shared validation logic that applies to all generation modes:
/// - Required variables are present
/// - Variable types match brick expectations
/// - Variable values are in allowed choices (if specified)
class BrickVariableValidator {
  /// Validate variables against brick requirements.
  ///
  /// Checks:
  /// - Required variables are present
  /// - Variable types match brick expectations
  /// - Variable values are in allowed choices (if specified)
  static List<String> validate(
    Brick brick,
    Map<String, dynamic> variables,
  ) {
    final errors = <String>[];

    // Check required variables
    for (final requiredVar in brick.requiredVariables) {
      if (!variables.containsKey(requiredVar.name)) {
        errors.add('Required variable "${requiredVar.name}" is missing');
      }
    }

    // Validate variable types and values
    for (final entry in variables.entries) {
      final variableName = entry.key;
      final value = entry.value;
      final brickVar = brick.getVariable(variableName);

      if (brickVar != null) {
        // Check if value matches expected type
        if (brickVar.type == 'list' && value is! List) {
          errors.add('Variable "$variableName" should be a list');
        } else if ((brickVar.type == 'bool' || brickVar.type == 'boolean') &&
            value is! bool) {
          errors.add('Variable "$variableName" should be a boolean');
        } else if (brickVar.type == 'string' && value is! String) {
          errors.add('Variable "$variableName" should be a string');
        }

        // Check choices if specified
        if (brickVar.choices != null && brickVar.choices!.isNotEmpty) {
          if (value is String && !brickVar.choices!.contains(value)) {
            errors.add(
              'Variable "$variableName" value "$value" is not in allowed choices: ${brickVar.choices!.join(', ')}',
            );
          }
        }
      }
    }

    return errors;
  }
}
