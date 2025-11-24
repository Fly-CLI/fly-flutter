# Examples

Practical examples of using the Fly Foundation Planning system.

## Basic Usage

### Single Feature Generation

```dart
import 'package:fly_brick_composer/fly_brick_composer.dart';

final composer = BrickComposer();

final result = composer.composeBricks({
  'name': 'home_screen',
  'generation_mode': 'feature',
  'feature': 'home',
  'screen_type': 'list',
  'with_viewmodel': true,
  'with_tests': true,
  'with_navigation': false,
});

print('Planned ${result.brickInvocations.length} invocation(s)');
// Output: Planned 1 invocation(s)
```

### Single Service Generation

```dart
final result = composer.composeBricks({
  'name': 'api_service',
  'generation_mode': 'service',
  'feature': 'core',
  'service_type': 'api',
  'with_tests': true,
  'with_mocks': false,
  'with_interceptors': true,
  'with_retry_logic': true,
  'api_base_url': 'https://api.example.com',
});

for (final invocation in result.brickInvocations) {
  print('${invocation.displayName} (phase ${invocation.phase})');
}
// Output: service:api:api_service (phase 0)
```

## Project Generation

### Project Only

```dart
final result = composer.composeBricks({
  'name': 'my_app',
  'organization': 'com.example',
  'description': 'A new Flutter app',
  'generation_mode': 'project',
  'platforms': ['ios', 'android'],
  'preset': 'starter',
});

// Only project brick is invoked
expect(result.brickInvocations.length, 1);
expect(result.brickInvocations.first.brickId, 'project');
```

### Project with Features

```dart
final result = composer.composeBricks({
  'name': 'my_app',
  'organization': 'com.example',
  'generation_mode': 'project',
  'platforms': ['ios', 'android'],
  'features': [
    {
      'name': 'home',
      'type': 'feature',
      'params': {
        'feature': 'home',
        'screen_type': 'list',
        'with_viewmodel': true,
        'with_tests': true,
        'with_validation': false,
        'with_navigation': true,
      },
    },
    {
      'name': 'profile',
      'type': 'feature',
      'params': {
        'feature': 'profile',
        'screen_type': 'detail',
        'with_viewmodel': true,
        'with_tests': true,
        'with_validation': false,
        'with_navigation': false,
      },
    },
  ],
});

// Project + 2 features
expect(result.brickInvocations.length, 3);

// Phase 0: Project
expect(result.brickInvocations[0].phase, 0);
expect(result.brickInvocations[0].brickId, 'project');

// Phase 1: Features
expect(result.brickInvocations[1].phase, 1);
expect(result.brickInvocations[1].brickId, 'feature');
expect(result.brickInvocations[1].displayName, 'feature:home:home');
expect(result.brickInvocations[1].targetDir, 'lib/features/home');

expect(result.brickInvocations[2].phase, 1);
expect(result.brickInvocations[2].displayName, 'feature:profile:profile');
expect(result.brickInvocations[2].targetDir, 'lib/features/profile');
```

### Project with Features and Services

```dart
final result = composer.composeBricks({
  'name': 'my_app',
  'organization': 'com.example',
  'generation_mode': 'project',
  'platforms': ['ios', 'android', 'web'],
  'features': [
    {
      'name': 'home',
      'type': 'feature',
      'params': {
        'feature': 'home',
        'screen_type': 'list',
        'with_viewmodel': true,
      },
    },
  ],
  'services': [
    {
      'name': 'api',
      'type': 'service',
      'params': {
        'feature': 'core',
        'service_type': 'api',
        'with_tests': true,
        'with_interceptors': true,
        'with_retry_logic': true,
        'api_base_url': 'https://api.example.com',
      },
    },
    {
      'name': 'cache',
      'type': 'service',
      'params': {
        'feature': 'core',
        'service_type': 'cache',
        'with_tests': true,
        'with_caching': true,
      },
    },
  ],
});

// Project + 1 feature + 2 services
expect(result.brickInvocations.length, 4);

// Verify phases
expect(result.brickInvocations[0].phase, 0); // Project
expect(result.brickInvocations[1].phase, 1); // Feature
expect(result.brickInvocations[2].phase, 2); // Service 1
expect(result.brickInvocations[3].phase, 2); // Service 2
```

## Using ComposerRequest

### Explicit Workflow ID

```dart
final request = ComposerRequest(
  workflowId: WorkflowId.foundationProject,
  raw: {
    'name': 'my_app',
    'organization': 'com.example',
    'platforms': ['ios', 'android'],
    'features': [...],
  },
);

final result = composer.planFromRequest(request);
```

### Inferred Workflow ID

```dart
final request = ComposerRequest.fromVars({
  'name': 'home_screen',
  'generation_mode': 'feature',  // Infers WorkflowId.featureOnly
  'feature': 'home',
  'screen_type': 'list',
});

final result = composer.planFromRequest(request);
```

## Accessing Variables

### From Planning Result

```dart
final result = composer.composeBricks({...});

// All derived variables
final allVars = result.derivedVars;
print(allVars['project_name_snake']);  // my_app
print(allVars['supports_ios']);        // true

// Brick-specific variables (from invocations)
for (final invocation in result.brickInvocations) {
  print('${invocation.displayName}:');
  print('  Variables: ${invocation.vars.keys.join(", ")}');
  print('  Target Dir: ${invocation.targetDir ?? "root"}');
}
```

### From Brick Invocation

```dart
final invocation = result.brickInvocations.first;

// Access variables passed to brick
final componentName = invocation.vars['component_name'];
final feature = invocation.vars['feature'];
final screenType = invocation.vars['screen_type'];

// Check target directory
if (invocation.targetDir != null) {
  print('Will generate to: ${invocation.targetDir}');
}
```

## Custom Workflow

### Creating a Custom Workflow

```dart
// Register custom workflow
final workflowRegistry = WorkflowRegistry();
workflowRegistry.register(WorkflowDefinition(
  id: WorkflowId.customWorkflow,
  steps: [
    WorkflowStep(
      id: 'project',
      brickId: 'project',
      defaultPhase: 0,
      repeatable: false,
    ),
    WorkflowStep(
      id: 'custom_step',
      brickId: 'my_custom_brick',
      defaultPhase: 1,
      repeatable: true,
      selectionKey: 'custom_items',
    ),
  ],
));

// Use custom composer
final composer = BrickComposer(
  workflowRegistry: workflowRegistry,
);

final result = composer.planFromRequest(ComposerRequest(
  workflowId: WorkflowId.customWorkflow,
  raw: {
    'name': 'my_app',
    'custom_items': [
      {'name': 'item1', 'type': 'custom', 'params': {...}},
    ],
  },
));
```

## Error Handling

### Invalid Workflow

```dart
try {
  final result = composer.composeBricks({
    'name': 'test',
    'generation_mode': 'invalid_mode',
  });
} on ComposerException catch (e) {
  print('Planning failed: ${e.message}');
}
```

### Missing Brick

```dart
try {
  final workflow = WorkflowDefinition(
    id: WorkflowId.foundationProject,
    steps: [
      WorkflowStep(
        id: 'invalid',
        brickId: 'nonexistent_brick',
        defaultPhase: 0,
        repeatable: false,
      ),
    ],
  );
  
  final registry = BrickRegistry.defaultRegistry();
  workflow.validateBrickIds(registry);  // Throws ComposerException
} on ComposerException catch (e) {
  print('Validation failed: ${e.message}');
}
```

## Integration with CLI

### From Command Flags

```dart
// In GenerateProjectCommand
final rawVars = {
  'name': projectName,
  'organization': organization,
  'description': description,
  'platforms': platforms,
  'generation_mode': 'project',
  'features': features.map((name) => {
    return {
      'name': name,
      'type': 'feature',
      'params': {
        'feature': name,
        'screen_type': 'list',
        'with_viewmodel': true,
      },
    };
  }).toList(),
};

final result = composer.composeBricks(rawVars);
```

### From Manifest File

```dart
// Parse YAML manifest
final manifest = loadYaml(manifestFile);
final rawVars = {
  'name': manifest['name'],
  'organization': manifest['organization'],
  'generation_mode': 'project',
  'platforms': manifest['platforms'],
  'features': (manifest['features'] as List).map((f) => {
    'name': f['name'],
    'type': 'feature',
    'params': f['params'],
  }).toList(),
  'services': (manifest['services'] as List).map((s) => {
    'name': s['name'],
    'type': 'service',
    'params': s['params'],
  }).toList(),
};

final result = composer.composeBricks(rawVars);
```

## Testing Examples

### Unit Test: Planning

```dart
test('compose project correctly', () {
  final composer = BrickComposer();
  
  final result = composer.composeBricks({
    'name': 'test_app',
    'organization': 'com.test',
    'generation_mode': 'project',
    'platforms': ['ios'],
  });
  
  expect(result.brickInvocations.length, 1);
  expect(result.brickInvocations.first.brickId, 'project');
  expect(result.brickInvocations.first.phase, 0);
});
```

### Unit Test: Workflow Expansion

```dart
test('expands workflow with multiple features', () {
  final composer = BrickComposer();
  
  final result = composer.composeBricks({
    'name': 'test',
    'generation_mode': 'project',
    'features': [
      {'name': 'home', 'type': 'feature', 'params': {'feature': 'home'}},
      {'name': 'profile', 'type': 'feature', 'params': {'feature': 'profile'}},
    ],
  });
  
  expect(result.brickInvocations.length, 3);  // Project + 2 features
  
  final featureInvocations = result.brickInvocations
      .where((inv) => inv.brickId == 'feature')
      .toList();
  
  expect(featureInvocations.length, 2);
  expect(featureInvocations[0].displayName, 'feature:home:home');
  expect(featureInvocations[1].displayName, 'feature:profile:profile');
});
```

### Integration Test: Full Pipeline

```dart
test('full composition and execution pipeline', () async {
  final composer = BrickComposer();
  final orchestrator = BrickOrchestrator(
    templateManager: templateManager,
    logger: logger,
    composer: composer,
  );
  
  final result = await orchestrator.generate(
    rawVars: {
      'name': 'test_app',
      'generation_mode': 'project',
      'platforms': ['ios'],
    },
    outputDirectory: testDir.path,
  );
  
  expect(result.success, true);
  expect(result.files, isNotEmpty);
});
```

## Advanced Patterns

### Conditional Features

```dart
final features = <Map<String, dynamic>>[];

if (includeHome) {
  features.add({
    'name': 'home',
    'type': 'feature',
    'params': {'feature': 'home', 'screen_type': 'list'},
  });
}

if (includeAuth) {
  features.add({
    'name': 'auth',
    'type': 'feature',
    'params': {'feature': 'auth', 'screen_type': 'auth'},
  });
}

final result = composer.composeBricks({
  'name': 'my_app',
  'generation_mode': 'project',
  'features': features,
});
```

### Dynamic Service Configuration

```dart
final services = serviceConfigs.map((config) {
  return {
    'name': config.name,
    'type': 'service',
    'params': {
      'feature': config.feature,
      'service_type': config.type.key,
      'with_tests': config.withTests,
      'with_interceptors': config.type == ServiceType.api && config.withInterceptors,
      'api_base_url': config.baseUrl,
    },
  };
}).toList();

final result = composer.composeBricks({
  'name': 'my_app',
  'generation_mode': 'project',
  'services': services,
});
```

