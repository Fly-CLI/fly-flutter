import 'package:mason_logger/mason_logger.dart';

/// Base class for system health checks
abstract class SystemCheck {
  /// The name of this check
  String get name;
  
  /// The category this check belongs to
  String get category;
  
  /// The description of what this check does
  String get description;
  
  /// Run the system check
  Future<CheckResult> run();
}

/// Result of a system check
class CheckResult {

  CheckResult({
    required this.healthy,
    required this.message,
    this.severity = CheckSeverity.info,
    this.suggestion,
    this.fixCommand,
    this.data,
  });

  /// Create a successful check result
  factory CheckResult.success({
    required String message,
    Map<String, dynamic>? data,
  }) => CheckResult(
      healthy: true,
      message: message,
      data: data,
    );

  /// Create a warning check result
  factory CheckResult.warning({
    required String message,
    String? suggestion,
    String? fixCommand,
    Map<String, dynamic>? data,
  }) => CheckResult(
      healthy: false,
      message: message,
      severity: CheckSeverity.warning,
      suggestion: suggestion,
      fixCommand: fixCommand,
      data: data,
    );

  /// Create an error check result
  factory CheckResult.error({
    required String message,
    String? suggestion,
    String? fixCommand,
    Map<String, dynamic>? data,
  }) => CheckResult(
      healthy: false,
      message: message,
      severity: CheckSeverity.error,
      suggestion: suggestion,
      fixCommand: fixCommand,
      data: data,
    );
  /// Whether the check passed
  final bool healthy;
  
  /// Human-readable message about the check result
  final String message;
  
  /// Severity level of the issue (if any)
  final CheckSeverity severity;
  
  /// Optional suggestion for fixing the issue
  final String? suggestion;
  
  /// Optional command to run to fix the issue
  final String? fixCommand;
  
  /// Additional data about the check result
  final Map<String, dynamic>? data;

  /// Convert to JSON for structured output
  Map<String, dynamic> toJson() => {
      'healthy': healthy,
      'message': message,
      'severity': severity.name,
      'suggestion': suggestion,
      'fixCommand': fixCommand,
      'data': data,
    };
}

/// Severity levels for check results
enum CheckSeverity {
  info,
  warning,
  error,
}

/// Manages and runs system checks
class SystemChecker {
  SystemChecker({required this.logger});
  
  final Logger logger;
  
  /// Run all registered system checks
  Future<List<CheckResult>> runAllChecks(List<SystemCheck> checks) async {
    final results = <CheckResult>[];
    
    for (final check in checks) {
      try {
        logger.detail('Running check: ${check.name}');
        final result = await check.run();
        results.add(result);
        
        if (result.healthy) {
          logger.detail('✅ ${check.name}: ${result.message}');
        } else {
          logger.detail('❌ ${check.name}: ${result.message}');
          if (result.suggestion != null) {
            logger.detail('   Suggestion: ${result.suggestion}');
          }
        }
      } catch (e) {
        logger.err('Error running check ${check.name}: $e');
        results.add(CheckResult.error(
          message: 'Check failed with error: $e',
          suggestion: 'Check the system configuration and try again',
        ),);
      }
    }
    
    return results;
  }
  
  /// Get overall system health status
  SystemHealthStatus getOverallStatus(List<CheckResult> results) {
    final errors = results.where((r) => r.severity == CheckSeverity.error).length;
    final warnings = results.where((r) => r.severity == CheckSeverity.warning).length;
    
    if (errors > 0) {
      return SystemHealthStatus.unhealthy;
    } else if (warnings > 0) {
      return SystemHealthStatus.degraded;
    } else {
      return SystemHealthStatus.healthy;
    }
  }
}

/// Overall system health status
enum SystemHealthStatus {
  healthy,
  degraded,
  unhealthy,
}
