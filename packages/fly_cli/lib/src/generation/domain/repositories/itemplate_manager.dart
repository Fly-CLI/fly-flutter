import 'package:fly_cli/src/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/generation/brick/brick_registry.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/generation_preview.dart';
import 'package:fly_cli/src/generation/generators/generation_result.dart';
import 'package:fly_cli/src/generation/template/template_info.dart';

/// Interface extracted from TemplateManager.
///
/// Represents the core template management operations.
/// This interface will be implemented by the refactored TemplateManager
/// and its decomposed components.
abstract class ITemplateManager {
  /// Get a brick by name.
  Future<Brick?> getBrick(String name);

  /// Get a template by name.
  Future<TemplateInfo?> getTemplate(String name);

  /// Discover all available templates.
  Future<List<TemplateInfo>> discoverTemplates({bool forceRefresh = false});

  /// Get all project bricks.
  Future<List<Brick>> getProjectBricks();

  /// Get all feature bricks.
  Future<List<Brick>> getFeatureBricks();

  /// Get all screen bricks.
  Future<List<Brick>> getScreenBricks();

  /// Get all service bricks.
  Future<List<Brick>> getServiceBricks();

  /// Validate a brick.
  Future<BrickValidationResult> validateBrick(String brickName);

  /// Generate from any brick type.
  Future<GenerationResult> generateFromBrick({
    required String brickName,
    required BrickType brickType,
    required String outputDirectory,
    required Map<String, dynamic> variables,
    bool dryRun = false,
  });

  /// Generate preview for brick generation.
  Future<GenerationPreview> generatePreview({
    required String brickName,
    required BrickType brickType,
    required String outputDirectory,
    required Map<String, dynamic> variables,
    String? projectName,
  });
}

