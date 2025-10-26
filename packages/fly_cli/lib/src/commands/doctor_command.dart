import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:fly_cli/src/commands/fly_command.dart';
import 'package:fly_cli/src/doctor/system_checker.dart';
import 'package:fly_cli/src/doctor/checks/flutter_sdk_check.dart';
import 'package:fly_cli/src/doctor/checks/dart_sdk_check.dart';
import 'package:fly_cli/src/doctor/checks/platform_tools_check.dart';
import 'package:fly_cli/src/doctor/checks/network_check.dart';
import 'package:fly_cli/src/doctor/checks/template_check.dart';

/// Check system setup and diagnose issues
class DoctorCommand extends FlyCommand {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Check system setup and diagnose issues';

  @override
  ArgParser get argParser {
    final parser = super.argParser;
    parser.addFlag(
      'fix',
      help: 'Attempt to fix common issues',
      negatable: false,
    );
    return parser;
  }

  @override
  Future<CommandResult> execute() async {
    final fix = argResults?['fix'] as bool? ?? false;

    if (planMode) {
      return _createPlan(fix);
    }

    try {
      logger.info('Running system diagnostics...');
      
      final systemChecker = SystemChecker(logger: logger);
      final checks = await _getSystemChecks();
      final results = await systemChecker.runAllChecks(checks);
      
      final healthyChecks = results.where((result) => result.healthy).length;
      final totalChecks = results.length;
      final overallStatus = systemChecker.getOverallStatus(results);
      
      // Convert results to JSON format
      final checksJson = results.map((result) => result.toJson()).toList();
      
      if (overallStatus == SystemHealthStatus.healthy) {
        return CommandResult.success(
          command: 'doctor',
          message: 'All system checks passed',
          data: {
            'total_checks': totalChecks,
            'healthy_checks': healthyChecks,
            'issues_found': 0,
            'overall_status': overallStatus.name,
            'checks': checksJson,
          },
        );
      } else {
        final issues = results.where((result) => !result.healthy).toList();
        final errorCount = issues.where((result) => result.severity == CheckSeverity.error).length;
        final warningCount = issues.where((result) => result.severity == CheckSeverity.warning).length;
        
        return CommandResult.error(
          message: 'Found ${issues.length} system issues ($errorCount errors, $warningCount warnings)',
          suggestion: fix ? 'Attempting to fix issues...' : 'Run "fly doctor --fix" to attempt fixes',
          metadata: {
            'total_checks': totalChecks,
            'healthy_checks': healthyChecks,
            'issues_found': issues.length,
            'error_count': errorCount,
            'warning_count': warningCount,
            'overall_status': overallStatus.name,
            'checks': checksJson,
          },
        );
      }
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to run system checks: $e',
        suggestion: 'Check your system configuration and try again',
      );
    }
  }

  CommandResult _createPlan(bool fix) {
    return CommandResult.success(
      command: 'doctor',
      message: 'System check plan',
      data: {
        'fix_mode': fix,
        'estimated_checks': 5,
        'estimated_duration_ms': fix ? 10000 : 3000,
      },
    );
  }

  /// Get the list of system checks to run
  Future<List<SystemCheck>> _getSystemChecks() async {
    final checks = <SystemCheck>[
      FlutterSdkCheck(logger: logger),
      DartSdkCheck(logger: logger),
      PlatformToolsCheck(logger: logger),
      NetworkCheck(logger: logger),
    ];

    // Add template check if templates directory exists
    final templatesDirectory = _findTemplatesDirectory();
    if (templatesDirectory != null) {
      checks.add(TemplateCheck(
        templatesDirectory: templatesDirectory,
        logger: logger,
      ));
    }

    return checks;
  }

  /// Find the templates directory
  String? _findTemplatesDirectory() {
    // Try to find templates directory relative to the executable
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);
    
    // Look for templates in common locations
    final possiblePaths = [
      path.join(executableDir, 'templates'),
      path.join(executableDir, '..', 'templates'),
      path.join(executableDir, '..', '..', 'templates'),
      path.join(Directory.current.path, 'templates'),
    ];

    for (final possiblePath in possiblePaths) {
      final dir = Directory(possiblePath);
      if (dir.existsSync()) {
        return possiblePath;
      }
    }

    return null;
  }
}