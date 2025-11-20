import 'package:fly_foundation_planning/src/brick_registry.dart';
import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/logger.dart';
import 'package:fly_foundation_planning/src/module_invocation.dart';
import 'package:fly_foundation_planning/src/planning_exception.dart';
import 'package:fly_foundation_planning/src/planning_request.dart';
import 'package:fly_foundation_planning/src/variables/generation_context.dart';
import 'package:fly_foundation_planning/src/variables/variable_bag.dart';
import 'package:fly_foundation_planning/src/variables/variable_pipeline.dart';
import 'package:fly_foundation_planning/src/workflow_definition.dart';

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

    // Step 3: Convert raw vars to base template variables for convenience
    final base = BaseTemplateVariables.fromVars(request.raw);

    // Step 4: Run the variable pipeline to derive variables
    final variableBag = _variablePipeline.run(ctx, _logger);

    // Step 5: Build global vars wrapper for backward compatibility
    final globalVars = GlobalVars(variables: variableBag, base: base);

    // Step 6: Expand workflow into brick invocations
    final brickInvocations = _expandWorkflow(request, variableBag, base)

      // Step 6: Sort invocations by phase and displayName for deterministic execution
      ..sort((a, b) {
        final phaseCompare = a.phase.compareTo(b.phase);
        if (phaseCompare != 0) return phaseCompare;
        return a.displayName.compareTo(b.displayName);
      });

    return PlanningResult(
      derivedVars: globalVars.toMasonVars(),
      brickInvocations: brickInvocations,
      // Keep moduleInvocations for backward compatibility
      moduleInvocations:
          brickInvocations.map(ModuleInvocation.fromBrickInvocation).toList(),
    );
  }

  /// Expands a workflow definition into a list of brick invocations.
  List<BrickInvocation> _expandWorkflow(
    PlanningRequest request,
    VariableBag variableBag,
    BaseTemplateVariables base,
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

          final displayName = _buildDisplayName(step.id, instanceConfig);
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
        // For standalone feature/service generation, create InstanceConfig from rawVars
        InstanceConfig? instanceConfig;
        if (step.brickId == 'fly_foundation_feature' ||
            step.brickId == 'fly_foundation_service') {
          instanceConfig =
              _createInstanceConfigFromRaw(step.brickId, request.raw);
        }

        final vars = brickDef.buildVars(variableBag, instanceConfig);
        final targetDir =
            brickDef.resolveTargetDir?.call(variableBag, instanceConfig);

        final displayName = instanceConfig != null
            ? _buildDisplayName(step.id, instanceConfig)
            : step.id;
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

  /// Creates an InstanceConfig from rawVars for standalone feature/service generation.
  InstanceConfig? _createInstanceConfigFromRaw(
      String brickId, Map<String, dynamic> raw,) {
    if (brickId == 'fly_foundation_feature') {
      return InstanceConfig(
        type: 'feature',
        name: raw['name'] as String? ??
            raw['component_name'] as String? ??
            'unnamed',
        params: {
          'feature': raw['feature'] as String? ?? 'core',
          if (raw['screen_type'] != null) 'screen_type': raw['screen_type'],
          'with_viewmodel': raw['with_viewmodel'] as bool? ?? true,
          'with_tests': raw['with_tests'] as bool? ?? true,
          'with_validation': raw['with_validation'] as bool? ?? false,
          'with_navigation': raw['with_navigation'] as bool? ?? false,
        },
      );
    } else if (brickId == 'fly_foundation_service') {
      return InstanceConfig(
        type: 'service',
        name: raw['name'] as String? ??
            raw['component_name'] as String? ??
            'unnamed',
        params: {
          'feature': raw['feature'] as String? ?? 'core',
          'service_type': raw['service_type'] as String? ?? 'api',
          'with_tests': raw['with_tests'] as bool? ?? true,
          'with_mocks': raw['with_mocks'] as bool? ?? false,
          'with_interceptors': raw['with_interceptors'] as bool? ?? false,
          'with_retry_logic': raw['with_retry_logic'] as bool? ?? false,
          'with_caching': raw['with_caching'] as bool? ?? false,
          if (raw['api_base_url'] != null) 'api_base_url': raw['api_base_url'],
        },
      );
    }
    return null;
  }

  /// Builds a display name for a brick invocation.
  String _buildDisplayName(String stepId, InstanceConfig instanceConfig) {
    if (instanceConfig.type == 'feature') {
      final featureConfig =
          FeatureInstanceConfig.fromInstanceConfig(instanceConfig);
      return 'feature:${featureConfig.featureKey}:${instanceConfig.name}';
    } else if (instanceConfig.type == 'service') {
      final serviceConfig =
          ServiceInstanceConfig.fromInstanceConfig(instanceConfig);
      return 'service:${serviceConfig.serviceType.key}:${instanceConfig.name}';
    }
    return '$stepId:${instanceConfig.name}';
  }
}

/// Result of planning foundation generation.
class PlanningResult {
  const PlanningResult({
    required this.derivedVars,
    required this.brickInvocations,
    required this.moduleInvocations,
  });

  /// Derived variables ready for template rendering.
  final Map<String, dynamic> derivedVars;

  /// List of brick invocations that should be executed (new model).
  final List<BrickInvocation> brickInvocations;

  /// List of module invocations that should be executed (legacy, for backward compatibility).
  final List<ModuleInvocation> moduleInvocations;
}

