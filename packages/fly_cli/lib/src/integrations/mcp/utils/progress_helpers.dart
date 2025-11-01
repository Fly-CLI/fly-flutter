import 'package:fly_mcp/fly_mcp.dart';

/// Progress notification helpers for MCP tools
///
/// Provides standardized progress stages for common operations to ensure
/// consistent progress reporting across all tools.
class ProgressHelpers {
  /// Template application progress stages
  static const List<ProgressStage> templateApplyStages = [
    ProgressStage(percent: 10, message: 'Loading template...'),
    ProgressStage(percent: 20, message: 'Template loaded'),
    ProgressStage(percent: 30, message: 'Validating template variables...'),
    ProgressStage(percent: 40, message: 'Variables validated'),
    ProgressStage(percent: 50, message: 'Generating template...'),
    ProgressStage(percent: 60, message: 'Generating files...'),
    ProgressStage(percent: 70, message: 'Applying template...'),
    ProgressStage(percent: 80, message: 'Processing template files...'),
    ProgressStage(percent: 90, message: 'Finalizing...'),
    ProgressStage(percent: 100, message: 'Template applied successfully'),
  ];

  /// Send progress notification for a specific stage
  static Future<void> notifyStage(
    ProgressNotifier? progressNotifier,
    ProgressStage stage,
  ) async {
    await progressNotifier?.notify(
      message: stage.message,
      percent: stage.percent,
    );
  }

  /// Send progress for a list of stages sequentially
  /// Useful for operations with well-defined progress steps
  static Future<void> notifyStages(
    ProgressNotifier? progressNotifier,
    List<ProgressStage> stages,
  ) async {
    for (final stage in stages) {
      await progressNotifier?.notify(
        message: stage.message,
        percent: stage.percent,
      );
    }
  }

  /// Send progress notification with custom message and percentage
  static Future<void> notify(
    ProgressNotifier? progressNotifier,
    String message, {
    int? percent,
  }) async {
    await progressNotifier?.notify(
      message: message,
      percent: percent,
    );
  }

  /// Send progress notification for template operations
  static Future<void> notifyTemplateProgress(
    ProgressNotifier? progressNotifier,
    TemplateProgressStage stage,
  ) async {
    await notifyStage(progressNotifier, stage.toProgressStage());
  }
}

/// Progress stage with message and percentage
class ProgressStage {
  const ProgressStage({
    required this.percent,
    required this.message,
  });

  final int percent;
  final String message;
}

/// Template application progress stages
enum TemplateProgressStage {
  loading(10, 'Loading template...'),
  loaded(20, 'Template loaded'),
  validating(30, 'Validating template variables...'),
  validated(40, 'Variables validated'),
  generating(50, 'Generating template...'),
  generatingFiles(60, 'Generating files...'),
  applying(70, 'Applying template...'),
  processing(80, 'Processing template files...'),
  finalizing(90, 'Finalizing...'),
  complete(100, 'Template applied successfully');

  const TemplateProgressStage(this.percent, this.message);

  final int percent;
  final String message;

  ProgressStage toProgressStage() => ProgressStage(
        percent: percent,
        message: message,
      );
}
