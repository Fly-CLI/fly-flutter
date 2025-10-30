import 'dart:io';

import 'package:args/args.dart' hide OptionType;
import 'package:fly_cli/src/core/command_foundation/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/command_validator.dart';
import 'package:fly_cli/src/core/command_metadata/command_metadata.dart' show CommandDefinition, CommandExample, OptionDefinition;
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/core/errors/error_codes.dart';
import 'package:fly_cli/src/core/errors/error_context.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/features/doctor/checks/dart_sdk_check.dart';
import 'package:fly_cli/src/features/doctor/checks/flutter_sdk_check.dart';
import 'package:fly_cli/src/features/doctor/checks/network_check.dart';
import 'package:fly_cli/src/features/doctor/checks/platform_tools_check.dart';
import 'package:fly_cli/src/features/doctor/checks/template_check.dart';

/// DoctorCommand using new architecture
class DoctorCommand extends FlyCommand {
  DoctorCommand(CommandContext context) : super(context);

  /// Factory constructor for enum-based command creation
  factory DoctorCommand.create(CommandContext context) => DoctorCommand(context);

  @override
  String get name => 'doctor';

  @override
  String get description => 'Check system setup and diagnose issues';

  @override
  CommandDefinition? get metadata => CommandDefinition(
    name: name,
    description: description,
    options: [
      const OptionDefinition(
        name: 'fix',
        description: 'Attempt to fix common issues automatically',
      ),
    ],
    examples: [
      const CommandExample(
        command: 'fly doctor',
        description: 'Check system setup and show status',
      ),
      const CommandExample(
        command: 'fly doctor --fix',
        description: 'Check system setup and attempt to fix issues',
      ),
    ],
  );

  @override
  ArgParser get argParser {
    final parser = super.argParser
    ..addFlag(
      'fix',
      help: 'Attempt to fix common issues',
      negatable: false,
    );
    return parser;
  }

  @override
  List<CommandValidator> get validators => [
    EnvironmentValidator(),
    NetworkValidator(['pub.dev', 'flutter.dev']),
  ];

  @override
  List<CommandMiddleware> get middleware => [
    LoggingMiddleware(),
    MetricsMiddleware(),
  ];

  @override
  Future<CommandResult> execute() async {
    final fix = argResults!['fix'] as bool? ?? false;

    try {
      logger.info('Running system diagnostics...');
      
      // Use injected system checker
      final systemChecker = context.systemChecker;
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
          errorCode: ErrorCode.environmentError,
          context: ErrorContext.forSystemError(
            'system_diagnostics',
            error: 'Found $errorCount errors and $warningCount warnings',
          ),
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
        errorCode: ErrorCode.environmentError,
        context: ErrorContext.forCommand(
          'doctor',
          arguments: argResults?.arguments,
          extra: {'error': e.toString()},
        ),
      );
    }
  }

  /// Get the list of system checks to run
  Future<List<SystemCheck>> _getSystemChecks() async {
    return <SystemCheck>[
      DartSdkCheck(logger: logger),
      FlutterSdkCheck(logger: logger),
      PlatformToolsCheck(logger: logger),
      // Keep TemplateCheck and NetworkCheck optional if added back later
    ];
  }

  // Lifecycle hooks implementation
  @override
  Future<void> onBeforeExecute(CommandContext context) async {
    logger.info('🔧 Preparing system diagnostics...');
  }

  @override
  Future<void> onAfterExecute(CommandContext context, CommandResult result) async {
    if (result.success) {
      logger.info('🎉 All system checks passed!');
    } else {
      logger.err('💥 System issues detected');
    }
  }

  @override
  Future<void> onError(CommandContext context, Object error, StackTrace stackTrace) async {
    logger.err('💥 System check failed: $error');
    if (context.verbose) {
      logger.err('Stack trace: $stackTrace');
    }
  }
}
