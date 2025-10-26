/// Security issue severity levels
enum SecuritySeverity {
  critical,
  high,
  medium,
  low,
}

/// Security issue structure
class SecurityIssue {
  final String type;
  final String message;
  final SecuritySeverity severity;
  final String suggestion;

  SecurityIssue({
    required this.type,
    required this.message,
    required this.severity,
    required this.suggestion,
  });
}

/// Security issues found in templates
class SecurityIssues {
  final List<SecurityIssue> issues;

  SecurityIssues(this.issues);

  bool get hasIssues => issues.isNotEmpty;
  bool get hasCritical => issues.any((i) => i.severity == SecuritySeverity.critical);
  bool get hasHigh => issues.any((i) => i.severity == SecuritySeverity.high);
}

/// Template structure for validation
class TemplateContent {
  final String name;
  final Map<String, String> files; // file path -> content
  final List<String> imports;
  final List<String> dependencies;

  TemplateContent({
    required this.name,
    required this.files,
    required this.imports,
    required this.dependencies,
  });
}

/// Validates templates for security issues
class TemplateValidator {
  /// Validate template for security issues
  SecurityIssues validate(TemplateContent template) {
    final allIssues = <SecurityIssue>[];

    // Run all validation checks
    allIssues.addAll(_checkForHardcodedSecrets(template));
    allIssues.addAll(_checkForSuspiciousImports(template));
    allIssues.addAll(_checkForFileSystemAccess(template));
    allIssues.addAll(_checkForNetworkCalls(template));
    allIssues.addAll(_validatePackageSources(template));
    allIssues.addAll(_checkForShellCommands(template));

    return SecurityIssues(allIssues);
  }

  /// Check for hardcoded secrets in template files
  List<SecurityIssue> _checkForHardcodedSecrets(TemplateContent template) {
    final issues = <SecurityIssue>[];
    final patterns = [
      (pattern: r'apiKey\s*[:=]\s*["''][^"'']+["'']', type: 'API Key'),
      (pattern: r'password\s*[:=]\s*["''][^"'']+["'']', type: 'Password'),
      (pattern: r'sk-[a-zA-Z0-9]{32,}', type: 'OpenAI API Key'),
      (pattern: r'ghp_[a-zA-Z0-9]{36}', type: 'GitHub Token'),
      (pattern: r'AIza[0-9A-Za-z\\-_]{35}', type: 'Google API Key'),
      (pattern: r'AKIA[0-9A-Z]{16}', type: 'AWS Access Key'),
    ];

    for (final file in template.files.entries) {
      final filePath = file.key;
      final content = file.value;

      for (final pattern in patterns) {
        final regex = RegExp(pattern.pattern, caseSensitive: false);
        if (regex.hasMatch(content)) {
          issues.add(SecurityIssue(
            type: 'hardcoded_secret',
            message: 'Found ${pattern.type} in $filePath',
            severity: SecuritySeverity.critical,
            suggestion: 'Remove hardcoded credentials. Use environment variables or configuration files.',
          ));
        }
      }
    }

    return issues;
  }

  /// Check for suspicious imports that could be dangerous
  List<SecurityIssue> _checkForSuspiciousImports(TemplateContent template) {
    final issues = <SecurityIssue>[];
    final dangerousImports = [
      (import: 'dart:io', reason: 'File system access'),
      (import: 'dart:ffi', reason: 'Foreign function interface'),
      (import: 'dart:isolate', reason: 'Process isolation'),
    ];

    for (final import in template.imports) {
      for (final dangerous in dangerousImports) {
        if (import.contains(dangerous.import)) {
          issues.add(SecurityIssue(
            type: 'suspicious_import',
            message: 'Suspicious import: $import (${dangerous.reason})',
            severity: SecuritySeverity.high,
            suggestion: 'Review if this import is necessary. Use with caution in templates.',
          ));
        }
      }
    }

    return issues;
  }

  /// Check for potentially dangerous file system operations
  List<SecurityIssue> _checkForFileSystemAccess(TemplateContent template) {
    final issues = <SecurityIssue>[];
    final fileSystemPatterns = [
      (pattern: r'''File\(['"]([^'"\n]+)['"]\)''', operation: 'File access'),
      (pattern: r'''Directory\(['"]([^'"\n]+)['"]\)''', operation: 'Directory access'),
      (pattern: r'\.delete\(\)', operation: 'File deletion'),
      (pattern: r'\.writeAsString\(', operation: 'File writing'),
    ];

    for (final file in template.files.entries) {
      final filePath = file.key;
      final content = file.value;

      for (final pattern in fileSystemPatterns) {
        final regex = RegExp(pattern.pattern, caseSensitive: false);
        if (regex.hasMatch(content)) {
          issues.add(SecurityIssue(
            type: 'file_system_access',
            message: 'File system operation detected in $filePath: ${pattern.operation}',
            severity: SecuritySeverity.medium,
            suggestion: 'Ensure file operations are scoped to safe directories only.',
          ));
        }
      }
    }

    return issues;
  }

  /// Check for network calls
  List<SecurityIssue> _checkForNetworkCalls(TemplateContent template) {
    final issues = <SecurityIssue>[];
    final networkPatterns = [
      (pattern: r'http\.get\(', operation: 'HTTP GET'),
      (pattern: r'http\.post\(', operation: 'HTTP POST'),
      (pattern: r'HttpClient\(\)', operation: 'HTTP Client creation'),
      (pattern: r'socket\.', operation: 'Socket operation'),
    ];

    for (final file in template.files.entries) {
      final content = file.value;

      for (final pattern in networkPatterns) {
        final regex = RegExp(pattern.pattern, caseSensitive: false);
        if (regex.hasMatch(content)) {
          issues.add(SecurityIssue(
            type: 'network_call',
            message: 'Network operation detected: ${pattern.operation}',
            severity: SecuritySeverity.medium,
            suggestion: 'Review network calls in template. Ensure they only connect to trusted endpoints.',
          ));
        }
      }
    }

    return issues;
  }

  /// Validate package sources
  List<SecurityIssue> _validatePackageSources(TemplateContent template) {
    final issues = <SecurityIssue>[];
    final gitUrlPattern = RegExp(r'git:');

    for (final dependency in template.dependencies) {
      if (gitUrlPattern.hasMatch(dependency)) {
        issues.add(SecurityIssue(
          type: 'git_dependency',
          message: 'Git dependency found: $dependency',
          severity: SecuritySeverity.low,
          suggestion: 'Prefer pub.dev packages over direct Git dependencies for better security.',
        ));
      }

      // Check for hosted packages from untrusted sources
      if (dependency.startsWith('http://')) {
        issues.add(SecurityIssue(
          type: 'unsecure_dependency',
          message: 'Unsecure HTTP dependency: $dependency',
          severity: SecuritySeverity.high,
          suggestion: 'Use HTTPS for package sources to prevent man-in-the-middle attacks.',
        ));
      }
    }

    return issues;
  }

  /// Check for shell command execution
  List<SecurityIssue> _checkForShellCommands(TemplateContent template) {
    final issues = <SecurityIssue>[];
    final shellPatterns = [
      (pattern: r'Process\.run\(', operation: 'Process execution'),
      (pattern: r'Process\.start\(', operation: 'Process starting'),
      (pattern: r'\.exec\(', operation: 'Shell execution'),
    ];

    for (final file in template.files.entries) {
      final content = file.value;

      for (final pattern in shellPatterns) {
        final regex = RegExp(pattern.pattern, caseSensitive: false);
        if (regex.hasMatch(content)) {
          issues.add(SecurityIssue(
            type: 'shell_command',
            message: 'Shell command execution detected: ${pattern.operation}',
            severity: SecuritySeverity.critical,
            suggestion: 'Shell commands in templates are dangerous. Use with extreme caution.',
          ));
        }
      }
    }

    return issues;
  }
} 