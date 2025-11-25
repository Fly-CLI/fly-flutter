/// Prompt generation error for MCP prompts
///
/// Provides structured error information with hints and remediation
/// for prompt generation failures.
class PromptError extends StateError {
  PromptError({
    required String message,
    required this.code,
    required this.category,
    required this.severity,
    this.promptId,
    this.variableName,
    this.hints = const [],
    this.remediation,
    Map<String, Object?>? context,
  }) : _context = context ?? <String, Object?>{},
       super(message);

  /// Error code identifying the specific error type
  final String code;

  /// Error category (e.g., 'validation', 'template', 'missing')
  final String category;

  /// Error severity (e.g., 'error', 'warning')
  final String severity;

  /// The prompt ID that caused the error
  final String? promptId;

  /// The variable name that caused the error
  final String? variableName;

  /// Hints for resolving the error
  final List<String> hints;

  /// Remediation steps
  final String? remediation;

  /// Additional error context
  final Map<String, Object?> _context;

  /// Additional error context
  Map<String, Object?> get context => Map<String, Object?>.from(_context);

  /// Missing required variable
  factory PromptError.missingVariable({
    required String variableName,
    String? promptId,
    String? description,
  }) {
    return PromptError(
      message: 'Missing required variable: $variableName',
      code: 'missing_variable',
      category: 'validation',
      severity: 'error',
      promptId: promptId,
      variableName: variableName,
      hints: [
        'Variable "$variableName" is required but was not provided',
        if (description != null) description,
        'Check the prompt arguments and ensure all required variables are provided',
        'Use prompts/get to see required variables for this prompt',
      ],
      remediation:
          'Provide the required variable "$variableName" in the prompt arguments. '
          'Use prompts/get to see all required and optional variables.',
      context: {
        'variable_name': variableName,
        if (description != null) 'description': description,
      },
    );
  }

  /// Invalid variable type
  factory PromptError.invalidVariableType({
    required String variableName,
    required String expectedType,
    String? actualType,
    String? promptId,
  }) {
    final hintsList = [
      'Variable "$variableName" has incorrect type',
      'Expected type: $expectedType',
      if (actualType != null) 'Actual type: $actualType',
      'Check the variable type and ensure it matches the expected type',
    ];

    return PromptError(
      message:
          'Invalid type for variable "$variableName": expected $expectedType, got ${actualType ?? 'unknown'}',
      code: 'invalid_variable_type',
      category: 'validation',
      severity: 'error',
      promptId: promptId,
      variableName: variableName,
      hints: hintsList,
      remediation:
          'Ensure variable "$variableName" has type $expectedType. '
          'Convert or validate the value before passing it to the prompt.',
      context: {
        'variable_name': variableName,
        'expected_type': expectedType,
        if (actualType != null) 'actual_type': actualType,
      },
    );
  }

  /// Invalid variable value
  factory PromptError.invalidVariableValue({
    required String variableName,
    required String reason,
    String? promptId,
    List<String>? allowedValues,
  }) {
    final hintsList = [
      'Variable "$variableName" has an invalid value',
      reason,
      if (allowedValues != null && allowedValues.isNotEmpty)
        'Allowed values: ${allowedValues.join(", ")}',
      'Check the variable value and ensure it meets the requirements',
    ];

    // Build remediation string
    final remediationBase =
        'Provide a valid value for variable "$variableName". ';
    final remediationAllowed = allowedValues != null && allowedValues.isNotEmpty
        ? 'Allowed values: ${allowedValues.join(", ")}. '
        : '';
    final remediation =
        remediationBase +
        remediationAllowed +
        'Check the variable constraints and requirements.';

    return PromptError(
      message: 'Invalid value for variable "$variableName": $reason',
      code: 'invalid_variable_value',
      category: 'validation',
      severity: 'error',
      promptId: promptId,
      variableName: variableName,
      hints: hintsList,
      remediation: remediation,
      context: {
        'variable_name': variableName,
        'reason': reason,
        if (allowedValues != null) 'allowed_values': allowedValues,
      },
    );
  }

  /// Template syntax error
  factory PromptError.templateSyntaxError({
    required String templateName,
    required String error,
    int? line,
    int? column,
  }) {
    final hintsList = [
      'Template contains syntax errors',
      error,
      if (line != null) 'Error at line $line',
      if (column != null) 'Error at column $column',
      'Check the template syntax and ensure all Mustache tags are properly closed',
      'Validate template syntax: {{variable}}, {{#section}}...{{/section}}',
    ];

    return PromptError(
      message: 'Template syntax error in "$templateName": $error',
      code: 'template_syntax_error',
      category: 'template',
      severity: 'error',
      hints: hintsList,
      remediation:
          'Fix the template syntax errors in "$templateName". '
          'Ensure all Mustache tags are properly formatted and closed. '
          'Check for unmatched {{#section}} and {{/section}} tags.',
      context: {
        'template_name': templateName,
        'error': error,
        if (line != null) 'line': line,
        if (column != null) 'column': column,
      },
    );
  }

  /// Template rendering error
  factory PromptError.templateRenderingError({
    required String templateName,
    required String error,
    String? missingVariable,
    int? line,
    int? column,
  }) {
    final hintsList = [
      'Failed to render template',
      error,
      if (missingVariable != null) 'Missing variable: $missingVariable',
      if (line != null) 'Error at line $line',
      if (column != null) 'Error at column $column',
      'Check that all required template variables are provided',
      'Verify template variable names match exactly',
    ];

    return PromptError(
      message: 'Template rendering error in "$templateName": $error',
      code: 'template_rendering_error',
      category: 'template',
      severity: 'error',
      hints: hintsList,
      remediation:
          'Ensure all required template variables are provided. '
          '${missingVariable != null ? 'Provide the missing variable: $missingVariable. ' : ''}'
          'Check template variable names and values.',
      context: {
        'template_name': templateName,
        'error': error,
        if (missingVariable != null) 'missing_variable': missingVariable,
        if (line != null) 'line': line,
        if (column != null) 'column': column,
      },
    );
  }

  /// Unknown prompt ID
  factory PromptError.unknownPromptId({
    required String promptId,
    List<String>? availablePrompts,
  }) {
    final hintsList = [
      'Prompt ID not found',
      'The requested prompt does not exist',
      if (availablePrompts != null && availablePrompts.isNotEmpty)
        'Available prompts: ${availablePrompts.join(", ")}',
      'Use prompts/list to see all available prompts',
      'Check the prompt ID for typos',
    ];

    return PromptError(
      message: 'Unknown prompt ID: $promptId',
      code: 'unknown_prompt_id',
      category: 'not_found',
      severity: 'error',
      promptId: promptId,
      hints: hintsList,
      remediation:
          'Verify the prompt ID is correct. '
          'Use prompts/list to see all available prompts.',
      context: {
        'prompt_id': promptId,
        if (availablePrompts != null) 'available_prompts': availablePrompts,
      },
    );
  }

  /// Invalid prompt arguments format
  factory PromptError.invalidArgumentsFormat({
    required String reason,
    String? promptId,
  }) {
    return PromptError(
      message: 'Invalid prompt arguments format: $reason',
      code: 'invalid_arguments_format',
      category: 'validation',
      severity: 'error',
      promptId: promptId,
      hints: [
        'Prompt arguments must be a Map<String, Object?>',
        'Use "arguments" key in MCP protocol (or "variables" for backward compatibility)',
        reason,
        'Check the arguments structure and ensure it matches the expected format',
      ],
      remediation:
          'Ensure prompt arguments are provided as a Map<String, Object?>. '
          'Use the "arguments" key in MCP protocol requests.',
      context: {
        'reason': reason,
      },
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (hints.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Hints:');
      for (final hint in hints) {
        buffer.writeln('  - $hint');
      }
    }
    if (remediation != null) {
      buffer.writeln();
      buffer.writeln('Remediation: $remediation');
    }
    return buffer.toString();
  }
}
