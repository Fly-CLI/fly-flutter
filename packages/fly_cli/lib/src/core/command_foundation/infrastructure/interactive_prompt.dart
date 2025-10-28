import 'dart:io';
import 'package:mason_logger/mason_logger.dart';

/// Infrastructure for interactive command-line prompting
/// 
/// Provides functions for prompting users for various types of input
/// including strings, choices, multi-choices, and confirmations.
class InteractivePrompt {

  InteractivePrompt(this.logger, [Stdin? stdin]) 
      : stdinInput = stdin ?? _defaultStdin();
  final Logger logger;
  final Stdin stdinInput;
  
  static Stdin _defaultStdin() => stdin;

  /// Prompt for a string input with optional validation
  /// 
  /// Returns the input string, trimmed of whitespace.
  /// If validation fails, re-prompts until valid input is provided.
  Future<String> promptString({
    required String prompt,
    String? defaultValue,
    bool Function(String)? validator,
    String? validationError,
  }) async {
    while (true) {
      final promptText = defaultValue != null 
          ? '$prompt (default: $defaultValue)'
          : prompt;

      logger.info('$promptText: ');
      final input = stdinInput.readLineSync()?.trim() ?? '';

      // Use default value if input is empty
      final value = input.isEmpty && defaultValue != null ? defaultValue : input;

      if (value.isEmpty) {
        logger.err('Input cannot be empty');
        continue;
      }

      // Validate if validator provided
      if (validator != null && !validator(value)) {
        logger.err(validationError ?? 'Invalid input');
        continue;
      }

      return value;
    }
  }

  /// Prompt for a single choice from a list of options
  /// 
  /// Displays options as a numbered list and returns the selected option.
  /// If defaultChoice is provided and matches an option, Enter accepts it.
  Future<String> promptChoice({
    required String prompt,
    required List<String> choices,
    String? defaultChoice,
  }) async {
    while (true) {
      logger.info(prompt);
      for (var i = 0; i < choices.length; i++) {
        final marker = choices[i] == defaultChoice ? ' [default]' : '';
        logger.info('  ${i + 1}) ${choices[i]}$marker');
      }
      logger.info('Select an option${defaultChoice != null ? ' (default: $defaultChoice)' : ''}: ');

      final input = stdinInput.readLineSync()?.trim() ?? '';
      
      // Use default if empty
      if (input.isEmpty && defaultChoice != null) {
        return defaultChoice;
      }

      // Try to parse as number
      final index = int.tryParse(input);
      if (index != null && index >= 1 && index <= choices.length) {
        return choices[index - 1];
      }

      // Try to match by value
      final selected = choices.firstWhere(
        (choice) => choice.toLowerCase() == input.toLowerCase(),
        orElse: () => '',
      );

      if (selected.isNotEmpty) {
        return selected;
      }

      logger.err('Invalid selection. Please try again.');
    }
  }

  /// Prompt for multiple choices from a list of options
  /// 
  /// Displays options as a checkbox-style list and returns selected options.
  /// Users enter comma-separated numbers (e.g., "1,3,5").
  Future<List<String>> promptMultiChoice({
    required String prompt,
    required List<String> choices,
    List<String>? defaultChoices,
  }) async {
    while (true) {
      logger.info(prompt);
      logger.info('(Enter comma-separated numbers, e.g., 1,3,5)');
      
      for (var i = 0; i < choices.length; i++) {
        final isDefault = defaultChoices?.contains(choices[i]) ?? false;
        final marker = isDefault ? ' [default]' : '';
        logger.info('  ${i + 1}) ${choices[i]}$marker');
      }

      final promptText = defaultChoices != null && defaultChoices.isNotEmpty
          ? 'Select options (default: ${defaultChoices.join(',')}): '
          : 'Select options: ';
      
      logger.info(promptText);
      
      final input = stdinInput.readLineSync()?.trim() ?? '';
      
      // Use defaults if empty
      if (input.isEmpty && defaultChoices != null && defaultChoices.isNotEmpty) {
        return defaultChoices;
      }

      if (input.isEmpty) {
        logger.err('Please select at least one option');
        continue;
      }

      // Parse comma-separated numbers
      final indices = input.split(',').map((s) => int.tryParse(s.trim())).toList();
      
      if (indices.any((i) => i == null)) {
        logger.err('Invalid input. Please enter comma-separated numbers.');
        continue;
      }

      final validIndices = indices.map((i) => i!).where((i) => i >= 1 && i <= choices.length);
      
      if (validIndices.isEmpty) {
        logger.err('No valid selections. Please try again.');
        continue;
      }

      return validIndices.map((i) => choices[i - 1]).toList();
    }
  }

  /// Prompt for a yes/no confirmation
  /// 
  /// Returns true for yes, false for no.
  /// Default value is returned if user just presses Enter.
  Future<bool> promptConfirm({
    required String prompt,
    bool defaultValue = true,
  }) async {
    while (true) {
      final defaultText = defaultValue ? 'Y/n' : 'y/N';
      logger.info('$prompt ($defaultText): ');
      
      final input = stdinInput.readLineSync()?.trim().toLowerCase() ?? '';
      
      if (input.isEmpty) {
        return defaultValue;
      }

      if (input == 'y' || input == 'yes') {
        return true;
      }

      if (input == 'n' || input == 'no') {
        return false;
      }

      logger.err('Please enter "y" for yes or "n" for no');
    }
  }
}
