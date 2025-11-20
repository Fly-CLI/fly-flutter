import 'package:fly_foundation_planning/src/exceptions/planning_exception.dart';
import 'package:fly_foundation_planning/src/registry/brick_registry.dart';
import 'package:fly_foundation_planning/src/registry/module_invocation.dart';
import 'package:fly_foundation_planning/src/registry/workflow_definition.dart';
import 'package:fly_foundation_planning/src/utils/logger.dart';
import 'package:fly_foundation_planning/src/variables/generation_context.dart';
import 'package:fly_foundation_planning/src/variables/variable_bag.dart';
import 'package:fly_foundation_planning/src/variables/variable_pipeline.dart';

import 'planning_request.dart';

/// Main entry point for planning Fly foundation generation.
///
/// This class provides a clean API for the CLI to:
/// 1. Plan variable derivation from raw user input
/// 2. Determine which bricks should be executed based on workflow definitions
/// 3. Get the variables to pass to each brick
class FoundationPlanner {

  /// Creates a foundation planner with the given variable pipeline.
  ///
  /// The [variablePipeline], [workflowRegistry], and [brickRegistry] are required.
  /// Domain-specific pipelines, workflows, and bricks (e.g., for Fly foundation)
  /// should be provided by higher-level packages (e.g., fly_cli).
  FoundationPlanner({
    required VariablePipeline variablePipeline,
    required WorkflowRegistry workflowRegistry,
    required BrickRegistry brickRegistry,
    PlanningLogger? logger,
  })  : _variablePipeline = variablePipeline,
        _workflowRegistry = workflowRegistry,
        _brickRegistry = brickRegistry,
        _logger = logger ?? const NoOpLogger();
  final VariablePipeline _variablePipeline;
  final PlanningLogger _logger;
  final BrickRegistry _brickRegistry;
  final WorkflowRegistry _workflowRegistry;

  /// Plans foundation generation from raw user input variables.
  ///
  /// This is a convenience method that creates a PlanningRequest and calls
  /// [planFromRequest]. The [workflowId] must be provided explicitly.
  ///
  /// Returns a [PlanningResult] containing:
  /// - Derived variables ready for template rendering
  /// - List of brick invocations that should be executed
  PlanningResult planFoundationGeneration(
    Map<String, dynamic> rawVars,
    WorkflowId workflowId,
  ) {
    final request = PlanningRequest.fromVars(
      rawVars,
      workflowId: workflowId,
    );
    return planFromRequest(request);
  }

  /// Plans foundation generation from a normalized planning request.
  ///
  /// Returns a [PlanningResult] containing:
  /// - Derived variables ready for template rendering
  /// - List of brick invocations that should be executed
  PlanningResult planFromRequest(PlanningRequest request) {
    // Step 1: Validate workflow ID
    _workflowRegistry.validateWorkflowId(request.workflowId);

    // Step 2: Create generation context from request
    final ctx = GenerationContext.fromVars(
      request.raw,
      mode: request.generationMode,
      workflowId: request.workflowId,
    );

    // Step 3: Run the variable pipeline to derive variables
    // The pipeline is responsible for extracting and setting all necessary fields
    // (name, organization, platforms, generation_mode, etc.) from the raw input.
    final variableBag = _variablePipeline.run(ctx, _logger);

    // Step 4: Expand workflow into brick invocations
    final brickInvocations = _expandWorkflow(request, variableBag)

      // Step 5: Sort invocations by phase and displayName for deterministic execution
      ..sort((a, b) {
        final phaseCompare = a.phase.compareTo(b.phase);
        if (phaseCompare != 0) return phaseCompare;
        return a.displayName.compareTo(b.displayName);
      });

    return PlanningResult(
      derivedVars: variableBag.toMap(),
      brickInvocations: brickInvocations,
    );
  }

  /// Expands a workflow definition into a list of brick invocations.
  List<BrickInvocation> _expandWorkflow(
    PlanningRequest request,
    VariableBag variableBag,
  ) {
    final workflow = _workflowRegistry.getById(request.workflowId);
    if (workflow == null) {
      throw PlanningException(
        'Workflow "${request.workflowId}" not found in registry.',
      );
    }

    final invocations = <BrickInvocation>[];
    var invocationCounter = 0;

    for (final step in workflow.steps) {
      // Validate brick exists
      _brickRegistry.validateBrickId(step.brickId);
      final brickDef = _brickRegistry.getById(step.brickId)!;

      if (step.repeatable) {
        // Repeatable step: look up instances from raw input
        if (step.selectionKey == null) {
          _logger.warn(
            'Skipping repeatable step "${step.id}": no selectionKey specified',
          );
          continue;
        }

        final instancesRaw = request.raw[step.selectionKey] as List?;
        if (instancesRaw == null || instancesRaw.isEmpty) {
          _logger.detail(
            'No instances found for repeatable step "${step.id}" (key: ${step.selectionKey})',
          );
          continue;
        }

        // Create one invocation per instance
        for (final instanceRaw in instancesRaw) {
          final instanceMap = instanceRaw is Map<String, dynamic>
              ? instanceRaw
              : <String, dynamic>{
                  'name': instanceRaw.toString(),
                  'params': <String, dynamic>{}
                };
          final instanceConfig = InstanceConfig.fromMap(instanceMap);

          final vars = brickDef.buildVars(variableBag, instanceConfig);
          final targetDir =
              brickDef.resolveTargetDir?.call(variableBag, instanceConfig);

          // Build display name from step ID and instance config
          final displayName = instanceConfig != null
              ? '${step.id}:${instanceConfig.name}'
              : step.id;
          final invocationId = '${step.id}_${invocationCounter++}';

          invocations.add(
            BrickInvocation(
              invocationId: invocationId,
              brickId: step.brickId,
              displayName: displayName,
              phase: step.defaultPhase,
              vars: vars,
              targetDir: targetDir,
            ),
          );
        }
      } else {
        // Single step: create one invocation
        // Domain-specific instance config creation should be handled by
        // the brick definition's buildVars function, not by the planner.
        final vars = brickDef.buildVars(variableBag, null);
        final targetDir = brickDef.resolveTargetDir?.call(variableBag, null);

        final displayName = step.id;
        final invocationId = '${step.id}_${invocationCounter++}';

        invocations.add(BrickInvocation(
          invocationId: invocationId,
          brickId: step.brickId,
          displayName: displayName,
          phase: step.defaultPhase,
          vars: vars,
          targetDir: targetDir,
        ));
      }
    }

    return invocations;
  }

}

/// Result of planning foundation generation.
class PlanningResult {
  const PlanningResult({
    required this.derivedVars,
    required this.brickInvocations,
  });

  /// Derived variables ready for template rendering.
  final Map<String, dynamic> derivedVars;

  /// List of brick invocations that should be executed (new model).
  final List<BrickInvocation> brickInvocations;
}

