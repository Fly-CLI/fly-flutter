part of '../cli_flags.dart';

// ============================================================================
// Add Screen Command Flags
// ============================================================================

/// Add screen feature flag
class AddScreenFeatureFlag extends CliFlag {
  const AddScreenFeatureFlag() : super(
        name: 'feature',
        description: 'Feature name',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        defaultValue: 'home',
      );
}

/// Add screen type flag (-t, --type)
class AddScreenTypeFlag extends CliFlag {
  const AddScreenTypeFlag() : super(
        name: 'type',
        abbreviation: 't',
        description: 'Screen type',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        allowedValues: const ['list', 'detail', 'form', 'auth', 'settings'],
        defaultValue: 'list',
      );
}

/// Add screen with viewmodel flag
class AddScreenWithViewModelFlag extends CliFlag {
  const AddScreenWithViewModelFlag() : super(
        name: 'with-viewmodel',
        description: 'Include viewmodel/provider',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Add screen with tests flag
class AddScreenWithTestsFlag extends CliFlag {
  const AddScreenWithTestsFlag() : super(
        name: 'with-tests',
        description: 'Include test files',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Add screen with validation flag
class AddScreenWithValidationFlag extends CliFlag {
  const AddScreenWithValidationFlag() : super(
        name: 'with-validation',
        description: 'Include form validation (for form screens)',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Add screen with navigation flag
class AddScreenWithNavigationFlag extends CliFlag {
  const AddScreenWithNavigationFlag() : super(
        name: 'with-navigation',
        description: 'Include navigation logic',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: true,
      );
}

// ============================================================================
// Add Service Command Flags
// ============================================================================

/// Add service feature flag
class AddServiceFeatureFlag extends CliFlag {
  const AddServiceFeatureFlag() : super(
        name: 'feature',
        description: 'Feature name',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        defaultValue: 'core',
      );
}

/// Add service type flag (-t, --type)
class AddServiceTypeFlag extends CliFlag {
  const AddServiceTypeFlag() : super(
        name: 'type',
        abbreviation: 't',
        description: 'Service type',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        allowedValues: const ['api', 'local', 'cache', 'analytics', 'storage'],
        defaultValue: 'api',
      );
}

/// Add service with tests flag
class AddServiceWithTestsFlag extends CliFlag {
  const AddServiceWithTestsFlag() : super(
        name: 'with-tests',
        description: 'Include test files',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Add service with mocks flag
class AddServiceWithMocksFlag extends CliFlag {
  const AddServiceWithMocksFlag() : super(
        name: 'with-mocks',
        description: 'Include mock files',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Add service with interceptors flag
class AddServiceWithInterceptorsFlag extends CliFlag {
  const AddServiceWithInterceptorsFlag() : super(
        name: 'with-interceptors',
        description: 'Include HTTP interceptors (for API services)',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Add service base URL flag
class AddServiceBaseUrlFlag extends CliFlag {
  const AddServiceBaseUrlFlag() : super(
        name: 'base-url',
        description: 'Base URL for API services',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        defaultValue: 'https://api.example.com',
      );
}
