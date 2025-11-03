part of '../cli_flags.dart';

// ============================================================================
// Doctor Command Flags
// ============================================================================

/// Doctor fix flag
class DoctorFixFlag extends CliFlag {
  const DoctorFixFlag() : super(
        name: 'fix',
        description: 'Attempt to fix common issues',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}
