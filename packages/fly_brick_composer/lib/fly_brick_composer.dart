/// Fly Brick Composer Library
///
/// This library provides generic brick composition and variable derivation infrastructure
/// for template generation systems. It is domain-agnostic and can be used for
/// any template generation workflow.
library;

export 'src/core/brick_composer.dart';
export 'src/core/composer_model.dart';
export 'src/core/composer_request.dart';
export 'src/exceptions/composer_exception.dart';
export 'src/orchestration/brick_executor.dart';
export 'src/orchestration/brick_orchestrator.dart';
export 'src/orchestration/orchestration_result.dart';
export 'src/registry/brick_registry.dart';
export 'src/registry/module_invocation.dart';
export 'src/registry/workflow_definition.dart';
export 'src/utils/logger.dart';
export 'src/utils/naming_utils.dart';
export 'src/variables/generation_context.dart';
export 'src/variables/variable_bag.dart';
export 'src/variables/variable_deriver.dart';
export 'src/variables/variable_pipeline.dart';
