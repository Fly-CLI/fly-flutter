import 'package:fly_foundation_planning/src/core_template_input.dart';
import 'package:fly_foundation_planning/src/planning_exception.dart';
import 'package:fly_foundation_planning/src/variables/variable_bag.dart';

/// Kind/category of a brick.
enum BrickKind {
  /// Project template brick (e.g., fly_foundation_project).
  projectTemplate,

  /// Feature component brick (e.g., fly_foundation_feature).
  featureComponent,

  /// Service component brick (e.g., fly_foundation_service).
  serviceComponent,

  /// Utility brick (e.g., tooling, scripts).
  utility,

  /// Custom/unknown brick type.
  custom;
}

/// Generic instance configuration for a brick invocation.
///
/// This is a flexible model that can represent any per-instance configuration
/// needed by a brick, with type-specific helpers for common patterns.
class InstanceConfig {

  /// Creates from a generic map (e.g., from manifest or CLI).
  factory InstanceConfig.fromMap(Map<String, dynamic> map) {
    return InstanceConfig(
      type: map['type'] as String? ?? '',
      name: map['name'] as String? ?? '',
      params: Map<String, dynamic>.from(map['params'] as Map? ?? {}),
    );
  }
  const InstanceConfig({
    required this.type,
    required this.name,
    this.params = const {},
  });

  /// Type identifier (e.g., 'feature', 'service').
  final String type;

  /// Instance name (e.g., 'home', 'api').
  final String name;

  /// Additional parameters specific to this instance.
  final Map<String, dynamic> params;

  /// Converts to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'params': params,
    };
  }
}

/// Global variables available to all bricks during planning.
///
/// This is a wrapper around VariableBag that provides convenient access
/// to derived variables and core template input.
///
/// Note: For domain-specific template variables (e.g., presets, feature/service
/// flags), use domain-specific wrappers in higher-level packages (e.g., fly_cli).
class GlobalVars {
  const GlobalVars({
    required this.variables,
    required this.coreInput,
  });

  /// Derived variables from the variable pipeline.
  final VariableBag variables;

  /// Core template input variables.
  final CoreTemplateInput coreInput;

  /// Converts to a Mason variables map.
  Map<String, dynamic> toMasonVars() {
    // Create a new map from variables to avoid modifying unmodifiable maps
    final result = Map<String, dynamic>.from(variables.toMap());
    // Ensure core input variables are included (they may already be in variables)
    result['name'] = coreInput.name;
    result['organization'] = coreInput.organization;
    result['description'] = coreInput.description;
    result['generation_mode'] = coreInput.generationMode.key;
    result['platforms'] = coreInput.platforms;
    return result;
  }
}

/// Definition of a brick, including its metadata and behavior.
class BrickDefinition {
  const BrickDefinition({
    required this.id,
    required this.kind,
    this.requiredCapabilities = const [],
    this.dependencies = const [],
    required this.buildVars,
    this.resolveTargetDir,
  });

  /// Unique brick identifier (e.g., 'fly_foundation_project').
  final String id;

  /// Kind/category of this brick.
  final BrickKind kind;

  /// List of capabilities this brick requires from other bricks.
  final List<String> requiredCapabilities;

  /// List of brick IDs this brick depends on.
  final List<String> dependencies;

  /// Function to build Mason variables for this brick from variable bag and instance config.
  final Map<String, dynamic> Function(VariableBag variables, InstanceConfig?) buildVars;

  /// Optional function to resolve the target directory for this brick.
  ///
  /// If null, the brick will use the root output directory.
  final String? Function(VariableBag variables, InstanceConfig?)? resolveTargetDir;
}

/// Registry of all known bricks.
///
/// This registry holds all BrickDefinitions and provides lookup methods.
/// This is a domain-agnostic registry. Domain-specific bricks (e.g., for Fly foundation)
/// should be registered by higher-level packages (e.g., fly_cli).
class BrickRegistry {
  final Map<String, BrickDefinition> _bricks = {};
  final Map<BrickKind, List<BrickDefinition>> _byKind = {};

  /// Creates an empty registry.
  BrickRegistry();

  /// Registers a brick definition.
  void register(BrickDefinition definition) {
    _bricks[definition.id] = definition;
    _byKind.putIfAbsent(definition.kind, () => []).add(definition);
  }

  /// Gets a brick by its ID.
  BrickDefinition? getById(String id) => _bricks[id];

  /// Gets all bricks of a specific kind.
  List<BrickDefinition> getByKind(BrickKind kind) => _byKind[kind] ?? const [];

  /// Gets all registered bricks.
  List<BrickDefinition> get all => _bricks.values.toList();

  /// Validates that a brick ID exists.
  void validateBrickId(String brickId) {
    if (!_bricks.containsKey(brickId)) {
      throw PlanningException(
        'Unknown brick ID: "$brickId". '
        'Available bricks: ${_bricks.keys.join(", ")}.',
      );
    }
  }
}
