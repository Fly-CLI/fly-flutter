part of '../cli_flags.dart';

// ============================================================================
// Generate Screen Command Flags
// ============================================================================

/// Generate screen feature flag
class GenerateScreenFeatureFlag extends CliFlag {
  const GenerateScreenFeatureFlag()
    : super(
        name: 'feature',
        description: 'Feature name',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        defaultValue: 'home',
      );
}

/// Generate screen type flag (-t, --type)
class GenerateScreenTypeFlag extends CliFlag {
  const GenerateScreenTypeFlag()
    : super(
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

/// Generate screen with viewmodel flag
class GenerateScreenWithViewModelFlag extends CliFlag {
  const GenerateScreenWithViewModelFlag()
    : super(
        name: 'with-viewmodel',
        description: 'Include viewmodel/provider',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Generate screen with tests flag
class GenerateScreenWithTestsFlag extends CliFlag {
  const GenerateScreenWithTestsFlag()
    : super(
        name: 'with-tests',
        description: 'Include test files',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Generate screen with validation flag
class GenerateScreenWithValidationFlag extends CliFlag {
  const GenerateScreenWithValidationFlag()
    : super(
        name: 'with-validation',
        description: 'Include form validation (for form screens)',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Generate screen with navigation flag
class GenerateScreenWithNavigationFlag extends CliFlag {
  const GenerateScreenWithNavigationFlag()
    : super(
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
// Generate Service Command Flags
// ============================================================================

/// Generate service feature flag
class GenerateServiceFeatureFlag extends CliFlag {
  const GenerateServiceFeatureFlag()
    : super(
        name: 'feature',
        description: 'Feature name',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        defaultValue: 'core',
      );
}

/// Generate service type flag (-t, --type)
class GenerateServiceTypeFlag extends CliFlag {
  const GenerateServiceTypeFlag()
    : super(
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

/// Generate service with tests flag
class GenerateServiceWithTestsFlag extends CliFlag {
  const GenerateServiceWithTestsFlag()
    : super(
        name: 'with-tests',
        description: 'Include test files',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Generate service with mocks flag
class GenerateServiceWithMocksFlag extends CliFlag {
  const GenerateServiceWithMocksFlag()
    : super(
        name: 'with-mocks',
        description: 'Include mock files',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Generate service with interceptors flag
class GenerateServiceWithInterceptorsFlag extends CliFlag {
  const GenerateServiceWithInterceptorsFlag()
    : super(
        name: 'with-interceptors',
        description: 'Include HTTP interceptors (for API services)',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Generate service base URL flag
class GenerateServiceBaseUrlFlag extends CliFlag {
  const GenerateServiceBaseUrlFlag()
    : super(
        name: 'base-url',
        description: 'Base URL for API services',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        defaultValue: 'https://api.example.com',
      );
}
