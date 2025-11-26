import 'package:fly_cli/src/generation/domain/entities/brick.dart';

/// Interface for variable validation.
///
/// Each processor implementation should have its own validator that implements
/// this interface, encapsulating validation logic specific to that processor.
abstract class IVariableValidator {
  /// Validate all aspects of variables: brick-level and business rules.
  ///
  /// This is the main entry point for validation. It performs both brick-level
  /// validation (required vars, types, choices) and business rule validation
  /// (naming, formats, dependencies).
  ///
  /// Returns a list of error messages. Empty list means validation passed.
  List<String> validateAll({
    required Brick? brick,
    required Map<String, dynamic> variables,
  });

  /// Validate business rules for variables.
  ///
  /// Checks naming conventions, format requirements, and dependencies
  /// specific to the generation mode.
  ///
  /// Returns a list of error messages. Empty list means validation passed.
  List<String> validateBusinessRules(Map<String, dynamic> variables);
}

