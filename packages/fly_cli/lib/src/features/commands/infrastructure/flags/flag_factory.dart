import 'package:args/args.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';

/// Factory for converting CliFlag enums to ArgParser options
/// Follows industry standards (POSIX/GNU conventions)
class FlagFactory {
  /// Add a single flag to an ArgParser
  static void addFlagToParser(ArgParser parser, CliFlag flag) {
    switch (flag.type) {
      case FlagType.boolean:
        _safeAdd(() {
          parser.addFlag(
            flag.name,
            abbr: flag.abbreviation,
            help: flag.description,
            negatable: flag.isNegatable,
            defaultsTo: flag.defaultValue as bool? ?? false,
          );
        });

      case FlagType.singleValue:
        _safeAdd(() {
          parser.addOption(
            flag.name,
            abbr: flag.abbreviation,
            help: flag.description,
            allowed: flag.allowedValues,
            defaultsTo: flag.defaultValue as String?,
          );
        });

      case FlagType.multiValue:
        _safeAdd(() {
          parser.addMultiOption(
            flag.name,
            abbr: flag.abbreviation,
            help: flag.description,
            allowed: flag.allowedValues,
            defaultsTo: flag.defaultValue as List<String>? ?? [],
          );
        });
    }
  }

  static void _safeAdd(void Function() addOperation) {
    try {
      addOperation();
    } on ArgumentError catch (e) {
      final message = e.message?.toString() ?? '';
      if (message.contains('Duplicate option or alias')) {
        return;
      }
      rethrow;
    }
  }

  /// Create an ArgParser from a list of flags
  static ArgParser createParser(List<CliFlag> flags) {
    validateAbbreviations(flags);
    final parser = ArgParser();
    for (final flag in flags) {
      addFlagToParser(parser, flag);
    }
    return parser;
  }

  /// Validate abbreviation conflicts
  static void validateAbbreviations(List<CliFlag> flags) {
    final abbreviations = <String, List<String>>{};

    for (final flag in flags) {
      if (flag.abbreviation != null) {
        abbreviations.putIfAbsent(flag.abbreviation!, () => []).add(flag.name);
      }
    }

    final conflicts = abbreviations.entries
        .where((e) => e.value.length > 1)
        .toList();

    if (conflicts.isNotEmpty) {
      throw ArgumentError(
        'Abbreviation conflicts detected:\n'
        '${conflicts.map((e) => '-${e.key}: ${e.value.join(", ")}').join("\n")}',
      );
    }
  }

  /// Apply flags to existing parser
  static void applyFlagsToParser(ArgParser parser, List<CliFlag> flags) {
    validateAbbreviations(flags);
    for (final flag in flags) {
      addFlagToParser(parser, flag);
    }
  }
}
