part of '../cli_flags.dart';

// ============================================================================
// Version Command Flags
// ============================================================================

/// Version check updates flag
class VersionCheckUpdatesFlag extends CliFlag {
  const VersionCheckUpdatesFlag()
    : super(
        name: 'check-updates',
        description: 'Check for available updates',
        isGlobal: false,
        category: CliFlagCategory.helpVersion,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}
