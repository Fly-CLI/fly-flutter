# Complete Compatibility Removal and Migration Plan

## Overview

This plan covers the complete removal of all compatibility layers and migration to the new Clean Architecture structure. The goal is to eliminate `BrickInfo`, `BrickMetadata`, and all adapter/wrapper classes, migrating everything to use the unified `Brick` entity directly.

## Current State Analysis

### Compatibility Layers to Remove

1. **Adapter/Wrapper Classes:**
   - `BrickRepositoryImpl` - wraps `BrickRegistry`, converts `BrickInfo` ↔ `Brick`
   - `TemplateRepositoryImpl` - wraps `TemplateManager`
   - `WorkflowOrchestratorImpl` - wraps `TemplateGenerationOrchestrator`

2. **Old Type Classes:**
   - `BrickInfo` - old brick representation (in `brick/brick_info.dart`)
   - `BrickMetadata` - old brick metadata (in `brick/brick_metadata.dart`)
   - Both have duplicate `BrickType` enums that conflict

3. **Compatibility Methods in Brick Entity:**
   - `Brick.fromBrickInfo()` - factory method
   - `Brick.fromBrickMetadata()` - factory method
   - `Brick.toBrickInfo()` - conversion method

4. **Classes Still Using Old Types:**
   - `BrickRegistry` - returns `BrickInfo`
   - `TemplateManager` - uses `BrickInfo`
   - `BrickDiscoveryService` - returns `BrickMetadata`
   - All interfaces (`IBrickRepository`, `IGenerationEngine`, `IVariableProcessor`) use `BrickInfo`
   - All implementations use `BrickInfo`
   - Cache managers use `BrickInfo`
   - Validation services use `BrickInfo`

## Migration Strategy

### Phase 1: Refactor Core Infrastructure Classes (Priority: Critical)

**Goal:** Make `BrickRegistry` and `BrickDiscoveryService` work directly with `Brick` entity

**Tasks:**

1. **Refactor BrickRegistry:**
   - Change return types from `BrickInfo` to `Brick`
   - Change cache from `Map<String, BrickInfo>` to `Map<String, Brick>`
   - Update `_loadBrickFromDirectory()` to create `Brick` directly from YAML
   - Remove all `BrickInfo` creation and conversion
   - Update `discoverBricks()`, `getBrick()`, `getBricksByType()` methods
   - Update `validateBrickByName()` to work with `Brick`

2. **Refactor BrickDiscoveryService:**
   - Change return types from `BrickMetadata` to `Brick`
   - Update `loadBrickMetadata()` to return `Brick` instead of `BrickMetadata`
   - Update `_discoverBricksInCategory()` to return `List<Brick>`
   - Remove all `BrickMetadata` creation

3. **Update BrickValidationResult:**
   - Move `BrickValidationResult` to domain layer if needed
   - Ensure it works with `Brick` entity

**Files to Modify:**
- `packages/fly_cli/lib/src/core/scaffolding/brick/brick_registry.dart`
- `packages/fly_cli/lib/src/core/scaffolding/brick/brick_discovery_service.dart`
- `packages/fly_cli/lib/src/core/scaffolding/brick/brick_validation_service.dart`

**Key Changes:**
```dart
// Before
Future<List<BrickInfo>> discoverBricks({bool forceRefresh = false}) async {
  // ... creates BrickInfo
}

// After
Future<List<Brick>> discoverBricks({bool forceRefresh = false}) async {
  // ... creates Brick directly from YAML
  return Brick(
    name: parsedName,
    version: Version.parse(versionStr),
    // ... other fields
  );
}
```

### Phase 2: Update All Interfaces (Priority: Critical)

**Goal:** Change all interfaces to use `Brick` entity instead of `BrickInfo`

**Tasks:**

1. **Update IBrickRepository:**
   - Change `getBrick()` return type: `Future<Brick?>`
   - Change `discoverBricks()` return type: `Future<List<Brick>>`
   - Change `validateBrick()` parameter: `Future<BrickValidationResultVO> validateBrick(Brick brick)`
   - Change `getBricksByType()` return type: `Future<List<Brick>>`
   - Use `BrickType` from `brick_metadata.dart` (already in `Brick` entity)

2. **Update IGenerationEngine:**
   - Change `generate()` parameter: `required Brick brick`
   - Change `preview()` parameter: `required Brick brick`
   - Remove `BrickInfo` import

3. **Update IVariableProcessor:**
   - Change `process()` parameter: `required Brick brick`
   - Remove `BrickInfo` import

4. **Update ITemplateManager (if still used):**
   - Change all methods to use `Brick` instead of `BrickInfo`

**Files to Modify:**
- `packages/fly_cli/lib/src/core/scaffolding/domain/repositories/ibrick_repository.dart`
- `packages/fly_cli/lib/src/core/scaffolding/application/ports/igeneration_engine.dart`
- `packages/fly_cli/lib/src/core/scaffolding/application/ports/ivariable_processor.dart`
- `packages/fly_cli/lib/src/core/scaffolding/domain/repositories/itemplate_manager.dart`

**Key Changes:**
```dart
// Before
abstract class IBrickRepository {
  Future<BrickInfo?> getBrick(String name);
  Future<List<BrickInfo>> discoverBricks({bool forceRefresh = false});
}

// After
abstract class IBrickRepository {
  Future<Brick?> getBrick(String name);
  Future<List<Brick>> discoverBricks({bool forceRefresh = false});
}
```

### Phase 3: Refactor Repository Implementation (Priority: Critical)

**Goal:** Remove adapter pattern, make `BrickRepositoryImpl` work directly with refactored `BrickRegistry`

**Tasks:**

1. **Refactor BrickRepositoryImpl:**
   - Remove adapter pattern - it should directly implement `IBrickRepository`
   - Use refactored `BrickRegistry` that returns `Brick`
   - Remove all `BrickInfo` ↔ `Brick` conversions
   - Directly return `Brick` from `BrickRegistry` methods
   - Update to use `BrickValidationResultVO` from domain layer

2. **Update Service Registration:**
   - `BrickRepositoryImpl` no longer needs to wrap `BrickRegistry`
   - Can either merge `BrickRepositoryImpl` into `BrickRegistry` or keep separate
   - If keeping separate, `BrickRegistry` becomes the implementation detail

**Files to Modify:**
- `packages/fly_cli/lib/src/core/scaffolding/infrastructure/brick/brick_repository_impl.dart`
- `packages/fly_cli/lib/src/core/cli/bootstrapping/service_bootstrapper.dart`

**Key Changes:**
```dart
// Before (adapter pattern)
class BrickRepositoryImpl implements IBrickRepository {
  final BrickRegistry _brickRegistry;
  
  @override
  Future<BrickInfo?> getBrick(String name) async {
    final brickInfo = await _brickRegistry.getBrick(name);
    return brickInfo; // Already BrickInfo
  }
}

// After (direct implementation)
class BrickRepositoryImpl implements IBrickRepository {
  final BrickRegistry _brickRegistry;
  
  @override
  Future<Brick?> getBrick(String name) async {
    return await _brickRegistry.getBrick(name); // Returns Brick
  }
}
```

### Phase 4: Refactor TemplateManager (Priority: High)

**Goal:** Make `TemplateManager` work with `Brick` entity

**Tasks:**

1. **Update TemplateManager:**
   - Change all `BrickInfo` references to `Brick`
   - Update `getBrick()`, `getProjectBricks()`, `getFeatureBricks()`, `getServiceBricks()` to return `Brick`
   - Update `generateFromBrick()` to accept `Brick` parameter
   - Remove `BrickInfo` imports and conversions

2. **Update TemplateRepositoryImpl:**
   - Remove adapter pattern if possible
   - Or update to work with refactored `TemplateManager`

**Files to Modify:**
- `packages/fly_cli/lib/src/core/scaffolding/template/template_manager.dart`
- `packages/fly_cli/lib/src/core/scaffolding/infrastructure/template/template_repository_impl.dart`

### Phase 5: Update All Application Layer Components (Priority: Critical)

**Goal:** Update all use cases, services, and engines to use `Brick` entity

**Tasks:**

1. **Update Use Cases:**
   - `GenerateFeatureUseCase` - use `Brick` instead of `BrickInfo`
   - `GenerateServiceUseCase` - use `Brick` instead of `BrickInfo`
   - `GenerateProjectUseCase` - use `Brick` instead of `BrickInfo`
   - Update all method calls and variable types

2. **Update Services:**
   - `VariableProcessingService` - use `Brick` parameter
   - `MasonGenerationEngine` - use `Brick` parameter
   - Update all internal logic to work with `Brick`

3. **Update Validation Services:**
   - `BrickValidator` - use `Brick` instead of `BrickInfo`
   - `VariableValidationService` - use `Brick` instead of `BrickInfo`
   - Update all validation logic

**Files to Modify:**
- `packages/fly_cli/lib/src/core/scaffolding/application/use_cases/generate_feature_use_case.dart`
- `packages/fly_cli/lib/src/core/scaffolding/application/use_cases/generate_service_use_case.dart`
- `packages/fly_cli/lib/src/core/scaffolding/application/use_cases/generate_project_use_case.dart`
- `packages/fly_cli/lib/src/core/scaffolding/application/services/variable_processing_service.dart`
- `packages/fly_cli/lib/src/core/scaffolding/infrastructure/generation/mason_generation_engine.dart`
- `packages/fly_cli/lib/src/core/scaffolding/domain/services/brick_validator.dart`
- `packages/fly_cli/lib/src/core/scaffolding/variables/validation/variable_validation_service.dart`

**Key Changes:**
```dart
// Before
final brick = await _brickRepository.getBrick(brickName);
if (brick == null) { // brick is BrickInfo?
  // ...
}
final processed = await _variableProcessor.process(
  brick: brick, // BrickInfo
);

// After
final brick = await _brickRepository.getBrick(brickName);
if (brick == null) { // brick is Brick
  // ...
}
final processed = await _variableProcessor.process(
  brick: brick, // Brick
);
```

### Phase 6: Update Legacy Generation Services (Priority: High)

**Goal:** Update `GenerationService` and related classes to use `Brick` entity

**Tasks:**

1. **Update GenerationService:**
   - Change all `BrickInfo` references to `Brick`
   - Update `generate()` method to use `Brick`
   - Update internal logic

2. **Update GenerationPreview:**
   - Change `BrickInfo` references to `Brick` if any
   - Update preview generation logic

3. **Update Foundation Classes:**
   - `FoundationBrickExecutor` - use `Brick` instead of `BrickInfo`
   - Any other foundation-related classes

**Files to Modify:**
- `packages/fly_cli/lib/src/core/scaffolding/generation/generation_service.dart`
- `packages/fly_cli/lib/src/core/scaffolding/generation/generation_preview.dart`
- `packages/fly_cli/lib/src/core/scaffolding/foundation/foundation_brick_executor.dart`

### Phase 7: Update Cache Managers (Priority: Medium)

**Goal:** Update cache managers to work with `Brick` entity

**Tasks:**

1. **Update BrickCacheManager:**
   - Change `loadBrickRegistry()` to return `List<Brick>?`
   - Update JSON serialization/deserialization to use `Brick`
   - Update cache storage to use `Brick`

2. **Update Other Cache Classes:**
   - Any other cache classes that use `BrickInfo`

**Files to Modify:**
- `packages/fly_cli/lib/src/core/cache/brick_cache_manager.dart`

**Key Changes:**
```dart
// Before
Future<List<BrickInfo>?> loadBrickRegistry() async {
  final bricks = bricksJson
      .map((json) => BrickInfo.fromJson(json as Map<String, dynamic>))
      .toList();
}

// After
Future<List<Brick>?> loadBrickRegistry() async {
  final bricks = bricksJson
      .map((json) => Brick.fromJson(json as Map<String, dynamic>))
      .toList();
}
```

### Phase 8: Remove Compatibility Methods from Brick Entity (Priority: High)

**Goal:** Remove all backward compatibility methods from `Brick` entity

**Tasks:**

1. **Remove Factory Methods:**
   - Delete `Brick.fromBrickInfo()` factory method
   - Delete `Brick.fromBrickMetadata()` factory method

2. **Remove Conversion Methods:**
   - Delete `Brick.toBrickInfo()` method
   - Delete `_convertToBrickInfoType()` helper method
   - Delete `_convertBrickType()` helper method (if only used for compatibility)
   - Delete `_inferCategoryFromBrickInfoType()` helper method (if only used for compatibility)

3. **Clean Up Imports:**
   - Remove `brick_info.dart` imports from `Brick` entity
   - Keep only `brick_metadata.dart` imports for enums (`BrickType`, `BrickCategory`)
   - Or move enums to a shared location

**Files to Modify:**
- `packages/fly_cli/lib/src/core/scaffolding/domain/entities/brick.dart`

**Key Changes:**
```dart
// Remove these methods:
// - factory Brick.fromBrickInfo(BrickInfo brickInfo)
// - factory Brick.fromBrickMetadata(BrickMetadata metadata)
// - BrickInfo toBrickInfo()
// - static brick_info.BrickType _convertToBrickInfoType(BrickType type)
```

### Phase 9: Remove Compatibility Adapter Classes (Priority: High)

**Goal:** Remove adapter/wrapper classes and refactor to direct implementations

**Tasks:**

1. **Remove BrickRepositoryImpl Adapter Pattern:**
   - After Phase 3, `BrickRepositoryImpl` should be a direct implementation
   - No longer wraps `BrickRegistry` - either merges with it or `BrickRegistry` becomes implementation detail

2. **Refactor TemplateRepositoryImpl:**
   - Consider if `TemplateManager` can implement `ITemplateRepository` directly
   - Or keep `TemplateRepositoryImpl` as a thin wrapper if needed

3. **Refactor WorkflowOrchestratorImpl:**
   - Consider if `TemplateGenerationOrchestrator` can implement `IWorkflowOrchestrator` directly
   - Or refactor `TemplateGenerationOrchestrator` to work with new architecture

**Files to Modify:**
- `packages/fly_cli/lib/src/core/scaffolding/infrastructure/brick/brick_repository_impl.dart`
- `packages/fly_cli/lib/src/core/scaffolding/infrastructure/template/template_repository_impl.dart`
- `packages/fly_cli/lib/src/core/scaffolding/infrastructure/workflow/workflow_orchestrator_impl.dart`

### Phase 10: Delete or Deprecate Old Classes (Priority: Medium)

**Goal:** Remove `BrickInfo` and `BrickMetadata` classes (or keep only for Mason integration if needed)

**Tasks:**

1. **Assess Mason Integration Needs:**
   - Check if Mason package requires `BrickInfo` or `BrickMetadata`
   - If yes, keep minimal versions only for Mason integration
   - If no, delete completely

2. **Delete Old Classes:**
   - Delete `brick_info.dart` file (or keep minimal version)
   - Delete `brick_metadata.dart` file (or extract only enums)
   - Move `BrickType` and `BrickCategory` enums to a shared location if needed

3. **Update All Imports:**
   - Remove all `brick_info.dart` imports
   - Update imports to use `Brick` entity or shared enums

**Files to Delete (or Deprecate):**
- `packages/fly_cli/lib/src/core/scaffolding/brick/brick_info.dart`
- `packages/fly_cli/lib/src/core/scaffolding/brick/brick_metadata.dart` (or extract enums only)

**Files to Create (if needed):**
- `packages/fly_cli/lib/src/core/scaffolding/domain/value_objects/brick_type.dart` (if extracting enums)
- `packages/fly_cli/lib/src/core/scaffolding/domain/value_objects/brick_category.dart` (if extracting enums)

### Phase 11: Update All Tests (Priority: High)

**Goal:** Update all tests to use `Brick` entity

**Tasks:**

1. **Update Unit Tests:**
   - Update all test files that use `BrickInfo` or `BrickMetadata`
   - Create `Brick` instances directly in tests
   - Update mocks to return `Brick` instead of `BrickInfo`

2. **Update Integration Tests:**
   - Update integration tests to use `Brick` entity
   - Update test data and fixtures

3. **Update Test Utilities:**
   - Update test helpers and factories
   - Remove `BrickInfo` test utilities

**Files to Modify:**
- All test files in `test/core/scaffolding/`
- All test files in `test/integration/scaffolding/`
- Test utility files

### Phase 12: Clean Up Imports and Dependencies (Priority: Medium)

**Goal:** Remove all unused imports and clean up dependencies

**Tasks:**

1. **Remove Unused Imports:**
   - Remove all `brick_info.dart` imports
   - Remove all `brick_metadata.dart` imports (except for enums if kept)
   - Clean up any other unused imports

2. **Update Dependencies:**
   - Ensure no circular dependencies
   - Verify all imports are correct

3. **Run Analysis:**
   - Run `dart analyze` to find unused imports
   - Fix all analysis issues

**Files to Modify:**
- All files that had `BrickInfo` or `BrickMetadata` imports

## Implementation Order

1. **Phase 1** - Refactor core infrastructure (BrickRegistry, BrickDiscoveryService)
2. **Phase 2** - Update all interfaces
3. **Phase 3** - Refactor repository implementation
4. **Phase 4** - Refactor TemplateManager
5. **Phase 5** - Update application layer
6. **Phase 6** - Update legacy generation services
7. **Phase 7** - Update cache managers
8. **Phase 8** - Remove compatibility methods
9. **Phase 9** - Remove adapter classes
10. **Phase 10** - Delete old classes
11. **Phase 11** - Update tests
12. **Phase 12** - Clean up

## Key Considerations

### Enum Consolidation

- `BrickType` exists in both `brick_info.dart` and `brick_metadata.dart`
- `Brick` entity uses `BrickType` from `brick_metadata.dart`
- Need to ensure all code uses the same enum
- Consider moving enums to domain layer

### Mason Integration

- Mason package might require specific types
- Check if `BrickInfo` is needed for Mason integration
- If yes, create minimal adapter only for Mason calls

### Validation Results

- `BrickValidationResult` is in `brick_registry.dart`
- `BrickValidationResultVO` is in domain layer
- Consolidate to use domain value object

### TemplateInfo vs Brick

- `TemplateInfo` is for project templates
- `Brick` is for all brick types
- Ensure clear separation or consolidation

## Success Criteria

1. **Zero `BrickInfo` usage:** All code uses `Brick` entity
2. **Zero `BrickMetadata` usage:** All code uses `Brick` entity
3. **Zero compatibility methods:** No `fromBrickInfo()`, `toBrickInfo()`, etc.
4. **Zero adapter patterns:** Direct implementations, no wrappers
5. **All interfaces use `Brick`:** No `BrickInfo` in interfaces
6. **All tests pass:** Updated and passing
7. **No compilation errors:** All code compiles
8. **Clean imports:** No unused or deprecated imports

## Risk Mitigation

### Testing Strategy

1. Update tests incrementally with each phase
2. Run tests after each major change
3. Add integration tests for critical paths

### Rollback Plan

1. Commit after each phase
2. Tag commits for easy rollback
3. Keep old code in separate branch until validated

### Validation Checklist

- [ ] All interfaces use `Brick` entity
- [ ] All implementations use `Brick` entity
- [ ] No `BrickInfo` or `BrickMetadata` references (except Mason if needed)
- [ ] No compatibility methods in `Brick` entity
- [ ] No adapter wrapper classes
- [ ] All tests pass
- [ ] No compilation errors
- [ ] All imports cleaned up

## Timeline Estimate

- **Phase 1 (Core Infrastructure):** 4-6 hours
- **Phase 2 (Interfaces):** 2-3 hours
- **Phase 3 (Repository):** 2-3 hours
- **Phase 4 (TemplateManager):** 3-4 hours
- **Phase 5 (Application Layer):** 4-6 hours
- **Phase 6 (Legacy Services):** 2-3 hours
- **Phase 7 (Cache Managers):** 2-3 hours
- **Phase 8 (Remove Methods):** 1-2 hours
- **Phase 9 (Remove Adapters):** 2-3 hours
- **Phase 10 (Delete Classes):** 1-2 hours
- **Phase 11 (Tests):** 4-6 hours
- **Phase 12 (Cleanup):** 1-2 hours

**Total:** 28-42 hours of focused work

## Dependencies

- All new architecture components must be complete (already done)
- `Brick` entity must be fully functional
- Domain value objects must be in place
- Service container must support the changes

## Notes

- This is a complete migration with no backward compatibility
- All changes should be made incrementally, phase by phase
- Test after each phase before proceeding
- Consider doing this in a feature branch for safety
- Keep commits atomic and well-documented

