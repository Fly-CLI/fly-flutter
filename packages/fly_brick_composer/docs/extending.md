# Extending the System

This guide explains how to add new bricks, workflows, and capabilities to the composition system.

## Adding a New Brick

### Step 1: Create the Brick Definition

Define your brick in `BrickRegistry._registerFoundationBricks()`:

```dart
register(BrickDefinition(
  id: 'my_custom_brick',
  kind: BrickKind.utility,  // or appropriate kind
  dependencies: ['fly_foundation_project'],  // if needed
  buildVars: (globalVars, instanceConfig) {
    final vars = globalVars.toMasonVars();
    
    // Add brick-specific variables
    if (instanceConfig != null) {
      vars['custom_field'] = instanceConfig.params['custom_field'];
    }
    
    return vars;
  },
  resolveTargetDir: (globalVars, instanceConfig) {
    // Optional: specify output directory
    return 'lib/custom';
  },
));
```

### Step 2: Implement Variable Mapping

Ensure `buildVars` provides all variables your brick template needs:

```dart
buildVars: (globalVars, instanceConfig) {
  final vars = globalVars.toMasonVars();
  
  // Always include base variables
  vars['name'] = globalVars.base.name;
  vars['organization'] = globalVars.base.organization;
  
  // Add brick-specific variables
  vars['custom_option'] = instanceConfig?.params['custom_option'] ?? false;
  
  return vars;
}
```

### Step 3: Test the Brick

```dart
test('my custom brick is registered', () {
  final registry = BrickRegistry.defaultRegistry();
  final brick = registry.getById('my_custom_brick');
  expect(brick, isNotNull);
  expect(brick!.kind, BrickKind.utility);
});
```

## Adding a New Workflow

### Step 1: Define the Workflow

Add to `WorkflowRegistry._registerDefaultWorkflows()`:

```dart
register(WorkflowDefinition(
  id: WorkflowId.myCustomWorkflow,
  steps: [
    WorkflowStep(
      id: 'step1',
      brickId: 'fly_foundation_project',
      defaultPhase: 0,
      repeatable: false,
    ),
    WorkflowStep(
      id: 'step2',
      brickId: 'my_custom_brick',
      defaultPhase: 1,
      repeatable: true,
      selectionKey: 'custom_items',
    ),
  ],
));
```

### Step 2: Add Workflow ID

Add to `WorkflowId` enum:

```dart
enum WorkflowId {
  // ... existing workflows
  myCustomWorkflow('my_custom_workflow');
  
  const WorkflowId(this.value);
  final String value;
}
```

### Step 3: Update Workflow Inference (Optional)

If you want automatic inference, update `ComposerRequest._inferWorkflowId()`:

```dart
static WorkflowId _inferWorkflowId(Map<String, dynamic> rawVars) {
  // ... existing logic
  if (rawVars['custom_flag'] == true) {
    return WorkflowId.myCustomWorkflow;
  }
  // ...
}
```

## Adding a New Instance Config Type

### Step 1: Create Helper Class

```dart
class CustomInstanceConfig {
  const CustomInstanceConfig({
    required this.name,
    required this.customField,
    this.optionalField,
  });

  final String name;
  final String customField;
  final bool? optionalField;

  factory CustomInstanceConfig.fromInstanceConfig(InstanceConfig config) {
    final params = config.params;
    return CustomInstanceConfig(
      name: config.name,
      customField: params['custom_field'] as String,
      optionalField: params['optional_field'] as bool?,
    );
  }

  InstanceConfig toInstanceConfig() {
    return InstanceConfig(
      type: 'custom',
      name: name,
      params: {
        'custom_field': customField,
        if (optionalField != null) 'optional_field': optionalField,
      },
    );
  }
}
```

### Step 2: Use in Brick Definition

```dart
buildVars: (globalVars, instanceConfig) {
  final vars = globalVars.toMasonVars();
  
  if (instanceConfig != null) {
    final customConfig = CustomInstanceConfig.fromInstanceConfig(instanceConfig);
    vars['custom_field'] = customConfig.customField;
  }
  
  return vars;
}
```

## Adding a New Variable Planner

### Step 1: Create Planner Class

```dart
class CustomPlanner extends CrossCuttingPlanner {
  @override
  bool canHandle(BaseTemplateVariables base) {
    return base.someCondition;
  }

  @override
  SharedDerivedVariables derive(
    BaseTemplateVariables base,
    SharedDerivedVariables shared,
    ComposerLogger logger,
  ) {
    return shared.copyWith(
      customVariable: _computeCustomVariable(base),
    );
  }
}
```

### Step 2: Register in PlannerFactory

```dart
class PlannerFactory {
  List<CrossCuttingPlanner> getCrossCuttingPlanners() {
    return [
      NamingPlanner(),
      PlatformPlanner(),
      CustomPlanner(),  // Add here
    ];
  }
}
```

### Step 3: Add to SharedDerivedVariables

```dart
class SharedDerivedVariables {
  final String? customVariable;  // Add field
  
  // Update copyWith, merge, toMasonVars, etc.
}
```

## Adding a New Generation Mode

### Step 1: Add to Enum

```dart
enum GenerationMode {
  project,
  feature,
  service,
  custom;  // Add new mode
  
  String get key {
    switch (this) {
      // ... existing cases
      case GenerationMode.custom:
        return 'custom';
    }
  }
}
```

### Step 2: Create Mode-Specific Variables

```dart
class CustomVariables extends ModeSpecificVariables {
  const CustomVariables({
    this.isCustom = true,
    this.customField,
  });

  final bool isCustom;
  final String? customField;

  @override
  GenerationMode get mode => GenerationMode.custom;

  @override
  Map<String, dynamic> toMasonVars() {
    return {
      MasonVarKey.isCustom.key: isCustom,
      if (customField != null) 'custom_field': customField,
    };
  }
}
```

### Step 3: Create Mode-Specific Planner

```dart
class CustomPlanner extends ModeSpecificPlanner {
  @override
  GenerationMode get mode => GenerationMode.custom;

  @override
  ModeSpecificVariables derive(
    BaseTemplateVariables base,
    ComposerLogger logger,
  ) {
    return CustomVariables(
      customField: base.someField,
    );
  }
}
```

### Step 4: Register in PlannerFactory

```dart
ModeSpecificPlanner? getModePlanner(GenerationMode mode) {
  switch (mode) {
    // ... existing cases
    case GenerationMode.custom:
      return CustomPlanner();
  }
}
```

## Best Practices

### Brick Definitions

1. **Unique IDs**: Use descriptive, namespaced IDs (e.g., `fly_foundation_*`)
2. **Complete Variables**: Provide all variables the brick template needs
3. **Type Safety**: Use typed instance config helpers
4. **Documentation**: Document required variables and options

### Workflows

1. **Clear Phases**: Use phases to express dependencies
2. **Descriptive IDs**: Use clear step IDs
3. **Consistent Keys**: Use same selection keys in input and workflow
4. **Validation**: Validate brick IDs exist

### Variable Planners

1. **Idempotent**: Planners should be safe to run multiple times
2. **Validation**: Validate combinations early
3. **Logging**: Use logger for important decisions
4. **Defaults**: Provide sensible defaults

### Testing

1. **Unit Tests**: Test each component independently
2. **Integration Tests**: Test full composition pipeline
3. **Edge Cases**: Test empty inputs, missing fields, etc.
4. **Error Cases**: Test validation and error handling

## Example: Complete Custom Brick

```dart
// 1. Register brick
register(BrickDefinition(
  id: 'my_custom_brick',
  kind: BrickKind.utility,
  dependencies: [],
  buildVars: (globalVars, instanceConfig) {
    final vars = globalVars.toMasonVars();
    if (instanceConfig != null) {
      final config = CustomInstanceConfig.fromInstanceConfig(instanceConfig);
      vars['custom_field'] = config.customField;
    }
    return vars;
  },
));

// 2. Create instance config helper
class CustomInstanceConfig {
  // ... as shown above
}

// 3. Add to workflow (if needed)
register(WorkflowDefinition(
  id: WorkflowId.customWorkflow,
  steps: [
    WorkflowStep(
      id: 'custom',
      brickId: 'my_custom_brick',
      defaultPhase: 0,
      repeatable: true,
      selectionKey: 'custom_items',
    ),
  ],
));

// 4. Test
test('custom brick workflow', () {
  final composer = BrickComposer();
  final result = composer.composeBricks({
    'name': 'test',
    'generation_mode': 'custom',
    'custom_items': [
      {'name': 'item1', 'type': 'custom', 'params': {'custom_field': 'value1'}},
    ],
  });
  
  expect(result.brickInvocations.length, 1);
  expect(result.brickInvocations.first.brickId, 'my_custom_brick');
});
```

## Migration Guide

When migrating existing bricks to the new system:

1. **Identify Variables**: List all variables the brick needs
2. **Create Definition**: Register brick with `buildVars` function
3. **Update Workflows**: Add brick to appropriate workflows
4. **Test**: Ensure variables are correctly passed
5. **Remove Old Code**: Delete hard-coded brick mappings

## Troubleshooting

### Brick Not Found

- Check brick is registered in `BrickRegistry`
- Verify brick ID matches exactly (case-sensitive)
- Ensure registry is initialized before use

### Missing Variables

- Check `buildVars` provides all needed variables
- Verify variable keys match `MasonVarKey` enum
- Check variable derivation in planners

### Wrong Execution Order

- Verify phase numbers in workflow steps
- Check dependencies are expressed via phases
- Ensure sorting is deterministic

### Instance Config Issues

- Verify instance config structure matches expected format
- Check `selectionKey` matches raw input key
- Ensure instance config helpers handle all cases

