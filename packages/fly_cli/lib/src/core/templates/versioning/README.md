# Template Versioning System

## Overview

The Template Versioning System provides robust, powerful version management for Fly CLI templates. It enables semantic versioning, compatibility checking, version discovery, and supports future migration capabilities.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Template Versioning System                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐ │
│  │   Models     │     │   Services   │     │    Utils     │ │
│  ├──────────────┤     ├──────────────┤     ├──────────────┤ │
│  │ Template     │     │ Version      │     │ Version      │ │
│  │ Version      │     │ Registry     │     │ Parser       │ │
│  │              │     │              │     │              │ │
│  │ Template     │     │ Compatibility│     │              │ │
│  │ Compatibility│     │  Checker     │     │              │ │
│  │              │     │              │     │              │ │
│  │ Compatibility│     │              │     │              │ │
│  │ Result       │     │              │     │              │ │
│  │              │     │              │     │              │ │
│  │ Template     │     │              │     │              │ │
│  │ Info         │     │              │     │              │ │
│  │ Extended     │     │              │     │              │ │
│  └──────────────┘     └──────────────┘     └──────────────┘ │
│         │                     │                    │        │
│         └─────────────────────┼────────────────────┘        │
│                               │                             │
│         ┌─────────────────────▼────────────────────┐        │
│         │      TemplateManager Integration         │        │
│         └──────────────────────────────────────────┘        │
│                               │                             │
│         ┌─────────────────────▼─────────────────────┐       │
│         │      Template Generation Flow             │       │
│         └───────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

## Component Structure

### Models Layer

#### `template_version.dart`
Semantic version wrapper using `pub_semver`.

**Responsibilities:**
- Parse SemVer strings (MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD])
- Compare versions (>, <, >=, <=, ==)
- Support version constraints (^2.1.0, ~2.1.0, >=2.0.0 <3.0.0)
- Validate version formats

**Key Methods:**
- `TemplateVersion.parse(String)` - Parse version string
- `compareTo(TemplateVersion)` - Compare versions
- `satisfies(VersionConstraint)` - Check constraint satisfaction
- `isCompatibleWith(TemplateVersion)` - Check compatibility

#### `template_compatibility.dart`
Compatibility requirements and metadata model.

**Responsibilities:**
- Store CLI version constraints (min/max)
- Store SDK requirements (Flutter/Dart)
- Track deprecation status and dates
- Perform compatibility checks

**Key Fields:**
- `cliMinVersion: Version?` - Minimum CLI version required
- `cliMaxVersion: VersionConstraint?` - Maximum CLI version allowed
- `flutterMinSdk: Version?` - Minimum Flutter SDK version
- `dartMinSdk: Version?` - Minimum Dart SDK version
- `deprecated: bool` - Deprecation status
- `deprecationDate: DateTime?` - When deprecated
- `eolDate: DateTime?` - End of life date

**Key Methods:**
- `checkCompatibility()` - Validate against current environment
- `fromYaml()` - Parse from template.yaml
- `fromJson()` - Deserialize from JSON (for caching)

#### `compatibility_result.dart`
Sealed class representing compatibility check results.

**Types:**
- `Compatible` - Template is compatible (may have warnings)
- `Incompatible` - Template is incompatible (has errors)

**Key Properties:**
- `errors: List<String>` - Incompatibility errors
- `warnings: List<String>` - Non-blocking warnings
- `isCompatible: bool` - Convenience check

#### `template_info.dart` (Enhanced)
TemplateInfo model with integrated compatibility support.

**Responsibilities:**
- Store template metadata (name, version, description, path)
- Include optional compatibility data directly
- Support JSON serialization with compatibility

**Key Features:**
- Optional `compatibility` field for full versioning checks
- Compatibility parsing integrated into `fromYaml` factory
- Backward compatible - templates without compatibility work as before

### Services Layer

#### `version_registry.dart`
Version discovery and management service.

**Responsibilities:**
- Discover available template versions
- Query specific template versions
- Maintain version cache
- Support multi-version templates

**Key Methods:**
- `getVersions(String templateName)` - List all versions
- `getTemplateVersion(String name, String version)` - Get specific version
- `getLatestVersion(String templateName)` - Get latest version
- `versionExists(String name, String version)` - Check version existence

**Storage Strategies:**
1. **Single Version** (default): `templates/{name}/template.yaml`
2. **Multi-Version**: `templates/{name}/versions/{version}/template.yaml`
3. **Versions Registry**: `templates/{name}/versions.yaml`

#### `compatibility_checker.dart`
Compatibility validation service.

**Responsibilities:**
- Validate template compatibility with current environment
- Check CLI version constraints
- Check SDK version requirements
- Provide actionable error messages

**Key Methods:**
- `checkTemplateCompatibility(TemplateInfo)` - Full compatibility check using TemplateInfo.compatibility
- `checkBrickCompatibility(BrickInfo)` - Brick compatibility check

### Utils Layer

#### `version_parser.dart`
YAML parsing utilities for version-related data.

**Responsibilities:**
- Parse version strings from YAML
- Parse version constraints from YAML
- Parse compatibility data from YAML
- Extract and validate version strings

**Key Methods:**
- `parseVersion(String?)` - Parse Version object
- `parseVersionConstraint(String?)` - Parse VersionConstraint
- `parseTemplateVersion(String?)` - Parse TemplateVersion
- `parseCompatibility(Map)` - Parse TemplateCompatibility from YAML

## Data Flow

### Template Loading Flow

```
┌─────────────────┐
│ TemplateManager │
│  .getTemplate() │
└────────┬────────┘
         │
         ├─► Check cache
         │   └─► Cache hit? ──► Return cached
         │
         ├─► Load from filesystem
         │   └─► _loadTemplateInfo()
         │
         ├─► Parse template.yaml
         │   └─► VersionParser.parseCompatibility()
         │
         ├─► Create TemplateInfo
         │   └─► TemplateInfo.fromYaml()
         │
         └─► Cache template
             └─► Return TemplateInfo
```

### Compatibility Checking Flow

```
┌──────────────────────┐
│  Template Generation │
│  Request              │
└───────────┬──────────┘
            │
            ▼
┌──────────────────────┐
│  TemplateManager     │
│  .generateProject()  │
└───────────┬──────────┘
            │
            ├─► Get template
            │   └─► getTemplate(name, version?)
            │
            ▼
┌──────────────────────┐
│  Compatibility       │
│  Checker             │
│  .checkCompatibility()│
└───────────┬──────────┘
            │
            ├─► Check CLI version
            │   ├─► Min version check
            │   └─► Max version check
            │
            ├─► Check Flutter SDK
            │   └─► Compare versions
            │
            ├─► Check Dart SDK
            │   └─► Compare versions
            │
            ├─► Check deprecation
            │   └─► Warning if deprecated
            │
            └─► Check EOL
                └─► Error if EOL
                    │
                    ▼
         ┌──────────────────┐
         │ Compatibility    │
         │ Result           │
         └─────────┬────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
   ┌─────────┐          ┌──────────┐
   │ Compatible│         │Incompatible│
   │ (warnings?)│        │ (errors)  │
   └─────────┘          └──────────┘
        │                     │
        └──────────┬──────────┘
                   │
                   ▼
         ┌──────────────────┐
         │ Continue/Block   │
         │ Generation       │
         └──────────────────┘
```

### Version Discovery Flow

```
┌──────────────────────────┐
│  VersionRegistry         │
│  .getVersions(name)      │
└────────────┬─────────────┘
             │
             ├─► Check cache
             │   └─► Cache hit? ──► Return cached
             │
             ├─► Check versions.yaml
             │   └─► Parse versions list
             │
             ├─► Check versioned directories
             │   └─► Scan templates/{name}/versions/
             │
             └─► Fallback: template.yaml
                 └─► Extract version from template.yaml
                     │
                     ▼
              ┌──────────────┐
              │ List<String> │
              │ versions     │
              └──────────────┘
```

### Template Validation Flow

```
┌──────────────────────────┐
│  TemplateManager         │
│  .validateTemplate()     │
└────────────┬─────────────┘
             │
             ├─► Load template
             │   └─► getTemplate(name)
             │
             ├─► Parse template.yaml
             │   └─► Validate YAML structure
             │
             ├─► Validate version format
             │   └─► VersionParser.parseTemplateVersion()
             │
             ├─► Check compatibility
             │   └─► CompatibilityChecker.checkCompatibility()
             │
             └─► Return TemplateValidationResult
                 └─► Contains issues and warnings
```

## Template YAML Schema

### Basic Template (Backward Compatible)

```yaml
name: minimal
version: 1.0.0
description: Bare-bones Flutter structure
min_flutter_sdk: "3.10.0"
min_dart_sdk: "3.0.0"

variables:
  project_name:
    type: string
    required: true
```

### Extended Template (With Versioning)

```yaml
name: riverpod
version: 2.1.3
description: Production-ready Riverpod architecture

# Compatibility & Requirements
compatibility:
  cli_min_version: "1.0.0"        # Minimum CLI version required
  cli_max_version: "<3.0.0"        # Maximum CLI version (optional)
  flutter_min_sdk: "3.10.0"
  dart_min_sdk: "3.0.0"

# Version Metadata
deprecated: false
deprecation_date: null
eol_date: null

# Migration Paths (Future)
migrations:
  - from_version: "2.0.0"
    to_version: "2.1.0"
    migration_script: migrations/2.0.0_to_2.1.0.dart
    breaking: true
    instructions: |
      Run: fly template migrate riverpod 2.0.0 2.1.0

variables:
  project_name:
    type: string
    required: true
```

## Usage Examples

### Basic Template Loading

```dart
// Load default/latest version
final template = await templateManager.getTemplate('riverpod');

// Load specific version
final template = await templateManager.getTemplate('riverpod', version: '2.1.0');
```

### Compatibility Checking

```dart
// Check compatibility before generation
final result = await templateManager.checkTemplateCompatibility('riverpod');

if (result.isIncompatible) {
  print('Errors:');
  for (final error in result.errors) {
    print('  - $error');
  }
}

if (result.warnings.isNotEmpty) {
  print('Warnings:');
  for (final warning in result.warnings) {
    print('  - $warning');
  }
}
```

### Version Discovery

```dart
// Get all available versions
final versions = await templateManager.getTemplateVersions('riverpod');
// Returns: ['2.1.3', '2.1.0', '2.0.0']

// Get latest version
final latest = await templateManager.getLatestTemplateVersion('riverpod');
// Returns: '2.1.3'
```

### Version Comparison

```dart
final v1 = TemplateVersion.parse('2.1.0');
final v2 = TemplateVersion.parse('2.1.3');

if (v2.isGreaterThan(v1)) {
  print('v2 is newer');
}

// Check if version satisfies constraint
final constraint = VersionConstraint.parse('^2.0.0');
if (v1.satisfies(constraint)) {
  print('v1 satisfies constraint');
}
```

## Integration Points

### TemplateManager Integration

```dart
class TemplateManager {
  // Version registry (lazy initialized)
  VersionRegistry? _versionRegistry;
  CompatibilityChecker? _compatibilityChecker;

  // Extended getTemplate with version support
  Future<TemplateInfo?> getTemplate(String name, {String? version});

  // Version management methods
  Future<List<String>> getTemplateVersions(String templateName);
  Future<String?> getLatestTemplateVersion(String templateName);
  Future<CompatibilityResult> checkTemplateCompatibility(String templateName);

  // Enhanced validation with compatibility checking
  Future<TemplateValidationResult> validateTemplate(String templateName);

  // Enhanced generation with compatibility checking
  Future<TemplateGenerationResult> generateProject({
    required String templateName,
    String? version,  // Optional version pinning
    // ... other parameters
  });
}
```

### Error Handling Integration

```dart
enum MasonErrorType {
  // ... existing types
  versionIncompatible,  // Template version incompatible
  versionNotFound,      // Requested version not found
}

// Error messages and recovery strategies automatically handled
```

## Version Constraint Examples

### Supported Formats

```dart
// Exact version
"2.1.3"

// Caret range (compatible versions)
"^2.1.0"  // >=2.1.0 <3.0.0

// Tilde range (approximately equivalent)
"~2.1.0"  // >=2.1.0 <2.2.0

// Comparison operators
">=2.0.0 <3.0.0"
">=2.1.0"
"<3.0.0"

// Combined ranges
">=2.0.0 <3.0.0 || >=4.0.0"
```

## Template Storage Strategies

### Strategy 1: Single Version (Default)

```
templates/
└── riverpod/
    ├── template.yaml          # Contains version 2.1.3
    └── __brick__/
        └── ...
```

**Usage:**
- Simple templates with one version
- Backward compatible with existing templates
- Version stored in `template.yaml`

### Strategy 2: Versioned Directories

```
templates/
└── riverpod/
    ├── template.yaml          # Default/latest version
    ├── __brick__/
    └── versions/
        ├── 2.1.3/
        │   ├── template.yaml
        │   └── __brick__/
        └── 2.0.0/
            ├── template.yaml
            └── __brick__/
```

**Usage:**
- Multiple versions maintained
- Easy to manage version history
- Supports version-specific migrations

### Strategy 3: Versions Registry

```
templates/
└── riverpod/
    ├── template.yaml          # Current version
    ├── versions.yaml          # Version registry
    └── __brick__/
```

**versions.yaml:**
```yaml
versions:
  - "2.1.3"
  - "2.1.0"
  - "2.0.0"
```

**Usage:**
- Clean structure
- Centralized version management
- Easy to query available versions

## Compatibility Checking Logic

### Check Priority

1. **CLI Version Check**
   - Check minimum CLI version requirement
   - Check maximum CLI version constraint
   - Block if incompatible

2. **Flutter SDK Check**
   - Compare current Flutter version with minimum required
   - Provide upgrade instructions if incompatible

3. **Dart SDK Check**
   - Compare current Dart version with minimum required
   - Provide upgrade instructions if incompatible

4. **Deprecation Warning**
   - Warn if template is deprecated
   - Show deprecation date if available
   - Non-blocking (warning only)

5. **EOL Check**
   - Error if template reached end of life
   - Warning if approaching EOL date
   - Provide days remaining

### Compatibility Matrix

```
┌─────────────────┬──────────────┬──────────────┬──────────────┐
│ Check Type      │ Compatible   │ Warning      │ Error        │
├─────────────────┼──────────────┼──────────────┼──────────────┤
│ CLI Min Version │ >= required  │ -            │ < required   │
│ CLI Max Version │ In range     │ -            │ Out of range │
│ Flutter SDK     │ >= required  │ -            │ < required   │
│ Dart SDK        │ >= required  │ -            │ < required   │
│ Deprecated      │ false        │ true         │ -            │
│ EOL Date        │ Before EOL  │ Approaching  │ After EOL    │
└─────────────────┴──────────────┴──────────────┴──────────────┘
```

## Error Handling

### Error Types

#### `versionIncompatible`
**Trigger:** Template compatibility check fails

**Example:**
```
Template version incompatible: CLI version 0.9.0 is less than required minimum 1.0.0
```

**Recovery Strategies:**
- Check template compatibility: `fly template check riverpod`
- Upgrade CLI: `dart pub global activate fly_cli`
- Upgrade Flutter SDK: `flutter upgrade`
- Try different template version: `fly template list --show-versions`

#### `versionNotFound`
**Trigger:** Requested template version doesn't exist

**Example:**
```
Template version not found: riverpod@2.5.0 not found
```

**Recovery Strategies:**
- List available versions: `fly template list --show-versions`
- Use latest version: `fly create riverpod`
- Check template name spelling

## Caching Strategy

### Version Cache

```
┌─────────────────────┐
│ Version Registry    │
│ Cache               │
├─────────────────────┤
│ Map<String,         │
│  List<String>>      │
│                     │
│ "riverpod" ->      │
│   ["2.1.3",        │
│    "2.1.0",        │
│    "2.0.0"]        │
└─────────────────────┘
```

**Cache Invalidation:**
- Manual: `versionRegistry.clearCache()`
- Automatic: On template directory changes
- Expiration: Not implemented (can be added)

### Template Cache Integration

Existing template cache includes version information:

```dart
class CachedTemplate {
  final String name;
  final String version;  // Version tracked
  final DateTime cachedAt;
  final DateTime expiresAt;
  final String checksum;
  final Map<String, dynamic> templateData;
}
```

## Design Decisions

### 1. Use VersionConstraint Instead of VersionRange

**Decision:** Use `VersionConstraint` for max version instead of `VersionRange`

**Rationale:**
- `VersionConstraint` directly supports common constraint formats (^, ~, >=, <)
- `VersionRange` constructor doesn't accept `VersionConstraint` directly
- Simpler API: `constraint.allows(version)` vs complex range logic

**Example:**
```dart
// Max version constraint in template.yaml
cli_max_version: "<3.0.0"

// Parsed as VersionConstraint
final constraint = VersionConstraint.parse("<3.0.0");
final compatible = constraint.allows(currentVersion);
```

### 2. Simplified Compatibility Checking

**Decision:** Always use full compatibility checking when compatibility data exists

**Rationale:**
- Clean, direct approach for greenfield project
- No fallback complexity
- Templates without compatibility data are considered compatible (no constraints)

**Implementation:**
- `compatibility` field nullable in `TemplateInfo`
- `checkTemplateCompatibility` uses `TemplateCompatibility.checkCompatibility` when available
- Returns compatible result if no compatibility data (no constraints = compatible)

### 3. Lazy Initialization

**Decision:** Version services initialized lazily

**Rationale:**
- Reduces startup overhead
- Only initialized when versioning features used
- Better performance for simple operations

**Implementation:**
```dart
VersionRegistry? _versionRegistry;
CompatibilityChecker? _compatibilityChecker;

VersionRegistry get _versionRegistryInstance {
  _versionRegistry ??= VersionRegistry(...);
  return _versionRegistry!;
}
```

### 4. Sealed Class Pattern

**Decision:** Use sealed classes for result types

**Rationale:**
- Type-safe exhaustiveness checking
- Clear intent (compatible vs incompatible)
- Matches existing codebase patterns

**Implementation:**
```dart
sealed class CompatibilityResult {
  const factory CompatibilityResult.compatible({List<String> warnings}) = Compatible;
  const factory CompatibilityResult.incompatible({
    required List<String> errors,
    List<String> warnings,
  }) = Incompatible;
}
```

## Future Enhancements (Phase 3+)

### Migration System

**Planned Features:**
- Migration script execution
- Dry-run mode for migration preview
- Migration history tracking
- Rollback capability

**Migration Script Structure:**
```dart
// migrations/2.0.0_to_2.1.0.dart
Future<void> migrate(String projectPath) async {
  // Migration logic
  // Update files, dependencies, etc.
}
```

### Template Lock Files

**Planned Features:**
- `.fly/template.lock` in generated projects
- Pin exact template versions
- Reproducible builds
- `fly template update` command

### Remote Template Repository

**Planned Features:**
- Fetch templates from remote source
- Version discovery from remote
- Template cache with remote sync
- Offline fallback

### Version Analytics

**Planned Features:**
- Track template version usage
- Report deprecated template usage
- Suggest version upgrades
- Migration path recommendations

## Testing Strategy

### Unit Tests

**Models:**
- Version parsing and comparison
- Compatibility checking logic
- YAML parsing edge cases

**Services:**
- Version registry discovery
- Compatibility checker validation
- Error handling

### Integration Tests

**TemplateManager:**
- Version-aware template loading
- Compatibility checking integration
- Version discovery flow

**End-to-End:**
- Template generation with versioning
- Compatibility error handling
- Version pinning in CLI commands

## Performance Considerations

### Caching

- **Version Registry:** Cache version lists per template
- **Template Cache:** Include version in cache key
- **Compatibility Checker:** Cache SDK version detection

### Lazy Loading

- Services initialized only when needed
- Template metadata parsed on demand
- Version discovery deferred until required

### Optimizations

- Single-pass YAML parsing
- Efficient version comparison using `pub_semver`
- Minimal file system operations

## Migration Guide

### Updating Existing Templates

**Step 1:** Add version to `template.yaml` (if not present)
```yaml
version: 1.0.0
```

**Step 2:** Add compatibility section (optional)
```yaml
compatibility:
  cli_min_version: "1.0.0"
  flutter_min_sdk: "3.10.0"
  dart_min_sdk: "3.0.0"
```

**Step 3:** Add deprecation info (if applicable)
```yaml
deprecated: false
deprecation_date: null
eol_date: null
```

### Creating Multi-Version Templates

**Step 1:** Create versioned directory structure
```
templates/riverpod/versions/2.1.3/
```

**Step 2:** Create `versions.yaml` registry
```yaml
versions:
  - "2.1.3"
  - "2.1.0"
  - "2.0.0"
```

**Step 3:** Use version-specific template.yaml files

## Troubleshooting

### Common Issues

#### Issue: Version format not recognized
**Symptom:** `Invalid version format` error

**Solution:**
- Ensure version follows SemVer: `MAJOR.MINOR.PATCH`
- Examples: `1.0.0`, `2.1.3`, `3.0.0-beta.1`

#### Issue: Compatibility check fails
**Symptom:** `Template compatibility check failed` error

**Solution:**
1. Check CLI version: `fly --version`
2. Check Flutter version: `flutter --version`
3. Check Dart version: `dart --version`
4. Upgrade if below minimum requirements

#### Issue: Version not found
**Symptom:** `Template version not found` error

**Solution:**
1. List available versions: `fly template list --show-versions`
2. Use latest version: `fly create riverpod`
3. Check template name spelling

## API Reference

### TemplateVersion

```dart
class TemplateVersion {
  /// Parse version string
  static TemplateVersion parse(String versionString);
  
  /// Try parse (returns null if invalid)
  static TemplateVersion? tryParse(String versionString);
  
  /// Parse version constraint
  static VersionConstraint? parseRange(String rangeString);
  
  /// Compare versions
  int compareTo(TemplateVersion other);
  
  /// Check constraint satisfaction
  bool satisfies(VersionConstraint constraint);
  
  /// Check compatibility
  bool isCompatibleWith(TemplateVersion other);
}
```

### TemplateCompatibility

```dart
class TemplateCompatibility {
  /// Create from YAML
  factory TemplateCompatibility.fromYaml(Map<dynamic, dynamic> yaml);
  
  /// Check compatibility
  CompatibilityResult checkCompatibility({
    required Version currentCliVersion,
    required Version currentFlutterVersion,
    required Version currentDartVersion,
  });
}
```

### CompatibilityChecker

```dart
class CompatibilityChecker {
  /// Check template compatibility
  /// Uses TemplateInfo.compatibility for full checks when available.
  /// Returns compatible if no compatibility data (no constraints).
  CompatibilityResult checkTemplateCompatibility(TemplateInfo template);
  
  /// Check brick compatibility
  CompatibilityResult checkBrickCompatibility(BrickInfo brick);
}
```

### VersionRegistry

```dart
class VersionRegistry {
  /// Get all versions for template
  Future<List<String>> getVersions(String templateName);
  
  /// Get specific version
  Future<TemplateInfo?> getTemplateVersion(String name, String version);
  
  /// Get latest version
  Future<String?> getLatestVersion(String templateName);
  
  /// Check version exists
  Future<bool> versionExists(String name, String version);
  
  /// Clear cache
  void clearCache();
}
```

## Related Documentation

- [Template System Architecture](../../docs/technical/architecture-and-analysis.md)
- [Command System](../../docs/architecture/command-system.md)
- [Error Handling](../../docs/core/errors/README.md)

## Contributing

When adding new versioning features:

1. **Follow SemVer:** Use semantic versioning for all versions
2. **Use Full Versioning:** Always use compatibility data when available
3. **Add Tests:** Include unit and integration tests
4. **Update Documentation:** Keep this file and related docs updated
5. **Error Messages:** Provide clear, actionable error messages
6. **Performance:** Consider caching and lazy loading

## License

Part of the Fly CLI project. See main LICENSE file for details.

