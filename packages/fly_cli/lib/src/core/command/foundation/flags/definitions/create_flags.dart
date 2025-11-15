part of '../cli_flags.dart';

// ============================================================================
// Create Command Flags
// ============================================================================

/// Create template flag (-t, --template)
class CreateTemplateFlag extends CliFlag {
  const CreateTemplateFlag() : super(
        name: 'template',
        abbreviation: 't',
        description: 'Project template to use',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        allowedValues: const ['fly_foundation'],
        defaultValue: 'fly_foundation',
      );
}

/// Create organization flag
class CreateOrganizationFlag extends CliFlag {
  const CreateOrganizationFlag() : super(
        name: 'organization',
        description: 'Organization identifier',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        defaultValue: 'com.example',
      );
}

/// Create platforms flag (multi-value)
/// Note: Cannot be const because defaultValue is a non-const list
class CreatePlatformsFlag extends CliFlag {
  CreatePlatformsFlag() : super(
        name: 'platforms',
        description: 'Target platforms',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.multiValue,
        allowedValues: const ['ios', 'android', 'web', 'macos', 'windows', 'linux'],
        defaultValue: const ['ios', 'android'],
      );
}

/// Create features flag (multi-value)
class CreateFeaturesFlag extends CliFlag {
  CreateFeaturesFlag() : super(
        name: 'features',
        description: 'Initial feature modules to scaffold',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.multiValue,
        defaultValue: const ['home'],
      );
}

/// Create from manifest flag
class CreateFromManifestFlag extends CliFlag {
  const CreateFromManifestFlag() : super(
        name: 'from-manifest',
        description: 'Create project from manifest file',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
      );
}
