import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/features/doctor/checks/dart_sdk_check.dart';
import 'package:fly_cli/src/features/doctor/checks/flutter_sdk_check.dart';
import 'package:fly_cli/src/features/doctor/checks/platform_tools_check.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_doctor_params.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_doctor_result.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for fly.doctor tool
class FlyDoctorStrategy
    extends McpToolStrategy<FlyDoctorParams, FlyDoctorResult> {
  @override
  String get name => 'fly.doctor';

  @override
  String get description => 'Check system setup and diagnose issues';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'fix': Schema.bool(),
        },
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'success': Schema.bool(),
          'message': Schema.string(),
          'totalChecks': Schema.int(),
          'healthyChecks': Schema.int(),
          'issuesFound': Schema.int(),
          'overallStatus': Schema.string(),
          'checks': Schema.list(items: ObjectSchema(additionalProperties: true)),
        },
        required: ['success', 'message'],
      );

  @override
  bool get readOnly => true;

  @override
  bool get writesToDisk => false;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => true;

  @override
  Duration? get timeout => const Duration(minutes: 2);

  @override
  FlyDoctorParams paramsFromJson(Map<String, Object?> json) {
    return FlyDoctorParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlyDoctorParams, FlyDoctorResult> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      await progressNotifier?.notify(
          message: 'Running system diagnostics...', percent: 10);

      // Get system checks
      final checks = await _getSystemChecks(context);
      
      await progressNotifier?.notify(
          message: 'Executing checks...', percent: 50);

      // Run checks
      final systemChecker = context.systemChecker;
      final results = await systemChecker.runAllChecks(checks);
      
      cancelToken?.throwIfCancelled();

      final healthyChecks = results.where((result) => result.healthy).length;
      final totalChecks = results.length;
      final overallStatus = systemChecker.getOverallStatus(results);
      
      // Convert results to JSON format
      final checksJson = results.map((result) => result.toJson()).toList();
      
      final issuesFound = totalChecks - healthyChecks;
      final overallStatusStr = overallStatus.name;

      return FlyDoctorResult(
        success: overallStatus == SystemHealthStatus.healthy,
        message: overallStatus == SystemHealthStatus.healthy
            ? 'All system checks passed'
            : 'Found $issuesFound system issues',
        totalChecks: totalChecks,
        healthyChecks: healthyChecks,
        issuesFound: issuesFound,
        overallStatus: overallStatusStr,
        checks: checksJson,
      );
    };
  }

  Future<List<SystemCheck>> _getSystemChecks(CommandContext context) async {
    return <SystemCheck>[
      DartSdkCheck(logger: context.logger),
      FlutterSdkCheck(logger: context.logger),
      PlatformToolsCheck(logger: context.logger),
    ];
  }
}
