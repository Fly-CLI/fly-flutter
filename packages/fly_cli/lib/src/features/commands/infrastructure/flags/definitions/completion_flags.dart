part of '../cli_flags.dart';

// ============================================================================
// Completion Command Flags
// ============================================================================

/// Completion shell flag (-s, --shell)
class CompletionShellFlag extends CliFlag {
  const CompletionShellFlag()
    : super(
        name: 'shell',
        abbreviation: 's',
        description: 'Target shell for completion script',
        isGlobal: false,
        category: CliFlagCategory.ui,
        type: FlagType.singleValue,
        allowedValues: const ['bash', 'zsh', 'fish', 'powershell'],
        defaultValue: 'bash',
      );
}

/// Completion install flag
class CompletionInstallFlag extends CliFlag {
  const CompletionInstallFlag()
    : super(
        name: 'install',
        description: 'Install completion script to shell configuration',
        isGlobal: false,
        category: CliFlagCategory.ui,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}

/// Completion uninstall flag
class CompletionUninstallFlag extends CliFlag {
  const CompletionUninstallFlag()
    : super(
        name: 'uninstall',
        description: 'Remove completion script from shell configuration',
        isGlobal: false,
        category: CliFlagCategory.ui,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: false,
      );
}
