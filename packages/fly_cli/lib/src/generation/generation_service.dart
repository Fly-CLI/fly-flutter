import 'dart:io';

import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart' as domain;
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/foundation/foundation_orchestrator.dart';
import 'package:fly_cli/src/generation/generation_preview.dart';
import 'package:fly_cli/src/generation/generation_request.dart'
    show GenerationRequest;
import 'package:fly_cli/src/generation/generators/generation_result.dart';
import 'package:fly_cli/src/generation/template/template_info.dart';
import 'package:fly_cli/src/generation/template/template_manager.dart';
import 'package:fly_cli/src/generation/template/template_variable.dart';
import 'package:fly_cli/src/generation/variables/validation/variable_validation_service.dart';
import 'package:mason/mason.dart' as mason show MasonException;
import 'package:mason_logger/mason_logger.dart';

/// Unified generation service that consolidates all template generation logic.
///
/// This service provides a single entry point for all generation operations,
/// consolidating functionality from TemplateManager, TemplateGenerationOrchestrator,
/// and GenerationPreviewService.
///
/// **Key Features:**
/// - Single source of truth for generation logic
/// - Unified result type (GenerationResult)
/// - Integrated validation and variable processing
/// - Support for all generation modes (project, feature, service)
/// - Preview/dry-run support
class GenerationService {
  final TemplateManager _templateManager;
  final Logger _logger;
  final GenerationPreviewService _previewService;
  final TemplateGenerationOrchestrator? _orchestrator;

  /// Creates a unified generation service.
  ///
  /// [templateManager] is used for brick discovery and low-level generation.
  /// [logger] is used for logging generation progress.
  /// [orchestrator] is optional; if provided, used for foundation workflows.
  /// [previewService] is optional; if not provided, a default one is created.
  GenerationService({
    required TemplateManager templateManager,
    required Logger logger,
    TemplateGenerationOrchestrator? orchestrator,
    GenerationPreviewService? previewService,
  }) : _templateManager = templateManager,
       _logger = logger,
       _orchestrator = orchestrator,
       _previewService =
           previewService ?? GenerationPreviewService(logger: logger);

  /// Generate code using the unified service.
  ///
  /// [mode] specifies the generation mode (project, feature, or service).
  /// [rawVars] contains the input variables for generation.
  /// [outputDirectory] is where files should be generated.
  /// [dryRun] if true, generates a preview instead of actual files.
  ///
  /// Returns a [GenerationResult] with success status and generated files or preview.
  Future<GenerationResult> generate({
    required GenerationMode mode,
    required Map<String, dynamic> rawVars,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    try {
      final startTime = DateTime.now();

      // Step 1: Determine brick name and type from mode
      final brickName = _getBrickNameForMode(mode);
      final brickType = _getBrickTypeForMode(mode);

      // Step 2: Apply variable derivers (foundation pipeline)
      final derivedVars = _applyVariableDerivers(rawVars);

      // Step 3: Get brick info
      final domain.Brick? brick = await _templateManager.getBrick(brickName);
      if (brick == null) {
        return GenerationResult.failure(
          error: 'Brick "$brickName" not found',
          data: {'brick_name': brickName, 'mode': mode.key},
        );
      }

      // Step 4: Validate brick type matches expected
      if (brick.type != brickType) {
        return GenerationResult.failure(
          error:
              'Brick "$brickName" is of type ${brick.type.name}, expected ${brickType.name}',
          data: {
            'brick_name': brickName,
            'expected_type': brickType.name,
            'actual_type': brick.type.name,
          },
        );
      }

      // Step 5: Validate variables
      final validationErrors = VariableValidationService.validateAll(
        brick: brick,
        mode: mode,
        variables: derivedVars,
      );
      if (validationErrors.isNotEmpty) {
        return GenerationResult.failure(
          error: 'Variable validation failed: ${validationErrors.join(', ')}',
          data: {
            'validation_errors': validationErrors,
            'brick_name': brickName,
          },
        );
      }

      // Step 6: Generate preview if dry run
      if (dryRun) {
        _logger.info('Generating dry run preview for brick: $brickName');
        final preview = await _previewService.generatePreview(
          brickName: brickName,
          brickType: brickType,
          outputDirectory: outputDirectory,
          variables: derivedVars,
        );

        final template = _brickToTemplateInfo(brick);
        return GenerationResult.dryRun(
          preview: preview,
          template: template,
        );
      }

      // Step 7: Perform actual generation
      return await _performGeneration(
        brick: brick,
        mode: mode,
        variables: derivedVars,
        outputDirectory: outputDirectory,
        startTime: startTime,
      );
    } catch (e, stackTrace) {
      _logger.err('Generation failed: $e');
      if (_logger is Logger && (_logger as Logger).level == Level.debug) {
        _logger.err('Stack trace: $stackTrace');
      }
      return GenerationResult.failure(
        error: 'Generation failed: $e',
        data: {
          'error_type': e.runtimeType.toString(),
          'mode': mode.key,
        },
      );
    }
  }

  /// Generate from a GenerationRequest (for backward compatibility).
  ///
  /// This method adapts GenerationRequest to the unified generate method.
  Future<GenerationResult> generateFromRequest({
    required GenerationRequest request,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    // Convert request to raw vars
    final rawVars = request.toVariableMap();

    return generate(
      mode: request.type,
      rawVars: rawVars,
      outputDirectory: outputDirectory,
      dryRun: dryRun,
    );
  }

  /// Apply variable derivers to process variables.
  ///
  /// This applies the foundation pipeline to derive additional variables
  /// from the input variables.
  Map<String, dynamic> _applyVariableDerivers(
    Map<String, dynamic> rawVars,
  ) {
    // For now, skip variable derivers as they require GenerationContext
    // which we don't have in this simplified flow.
    // Variable derivers will be applied by the orchestrator for project mode.
    // For feature/service modes, we use the raw vars directly.
    return rawVars;
  }

  /// Get brick name for a generation mode.
  String _getBrickNameForMode(GenerationMode mode) {
    switch (mode) {
      case GenerationMode.project:
        return 'project';
      case GenerationMode.feature:
        return 'feature';
      case GenerationMode.service:
        return 'service';
    }
  }

  /// Get brick type for a generation mode.
  BrickType _getBrickTypeForMode(GenerationMode mode) {
    switch (mode) {
      case GenerationMode.project:
        return BrickType.project;
      case GenerationMode.feature:
        return BrickType.feature;
      case GenerationMode.service:
        return BrickType.service;
    }
  }

  /// Perform actual generation using Mason or orchestrator.
  Future<GenerationResult> _performGeneration({
    required domain.Brick brick,
    required GenerationMode mode,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    required DateTime startTime,
  }) async {
    try {
      _logger.info('Generating from brick: ${brick.name}');

      // Use orchestrator for foundation workflows (project mode)
      if (mode == GenerationMode.project && _orchestrator != null) {
        final orchestrationResult = await _orchestrator!.generate(
          rawVars: variables,
          outputDirectory: outputDirectory,
        );

        final duration = DateTime.now().difference(startTime);
        final template = _brickToTemplateInfo(brick);

        if (orchestrationResult.success) {
          return GenerationResult.success(
            files: orchestrationResult.files ?? [],
            targetDirectory:
                orchestrationResult.targetDirectory ?? outputDirectory,
            template: template,
            duration: duration,
          );
        } else {
          return GenerationResult.failure(
            error: orchestrationResult.error ?? 'Generation failed',
            data: {'brick_name': brick.name},
          );
        }
      }

      // Use TemplateManager for direct brick generation (feature/service modes)
      final result = await _templateManager.generateFromBrick(
        brickName: brick.name,
        brickType: brick.type,
        outputDirectory: outputDirectory,
        variables: variables,
        dryRun: false,
      );

      // TemplateManager now returns GenerationResult directly
      // Update duration if not already set
      if (result.duration == null) {
        final duration = DateTime.now().difference(startTime);
        // Create new result with duration
        if (result.success && !result.isDryRun) {
          return GenerationResult.success(
            files: result.files ?? [],
            targetDirectory: result.targetDirectory ?? outputDirectory,
            template: result.template,
            duration: duration,
            data: result.data,
          );
        }
      }

      return result;
    } on mason.MasonException catch (e) {
      _logger.err('Mason generation error: $e');
      return GenerationResult.failure(
        error: 'Mason generation failed: ${e.message}',
        data: {'brick_name': brick.name},
      );
    } on FileSystemException catch (e) {
      _logger.err('File system error: $e');
      return GenerationResult.failure(
        error: 'File system error: ${e.message}',
        data: {'brick_name': brick.name},
      );
    } catch (e, stackTrace) {
      _logger.err('Unexpected error: $e');
      if (_logger is Logger && (_logger as Logger).level == Level.debug) {
        _logger.err('Stack trace: $stackTrace');
      }
      return GenerationResult.failure(
        error: 'Generation failed: $e',
        data: {'brick_name': brick.name},
      );
    }
  }

  /// Convert Brick to TemplateInfo.
  TemplateInfo _brickToTemplateInfo(domain.Brick brick) {
    // This is a helper method that should be in TemplateManager
    // For now, we'll create a minimal TemplateInfo
    return TemplateInfo(
      name: brick.name,
      version: brick.version.toString(),
      description: brick.description,
      path: brick.path,
      minFlutterSdk: brick.minFlutterSdk?.toString() ?? '3.10.0',
      minDartSdk: brick.minDartSdk?.toString() ?? '3.0.0',
      variables: brick.variables.values
          .map(
            (brickVar) => TemplateVariable(
              name: brickVar.name,
              type: brickVar.type,
              required: brickVar.required,
              defaultValue: brickVar.defaultValue,
              choices: brickVar.choices,
              description: brickVar.description,
            ),
          )
          .toList(),
      features: brick.features,
      packages: brick.packages,
    );
  }
}
