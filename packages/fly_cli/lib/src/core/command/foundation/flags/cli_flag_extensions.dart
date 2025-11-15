import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/metadata/command_definition.dart';

/// Conversion helpers between [CliFlag] and metadata objects.
extension CliFlagMetadataExtensions on CliFlag {
  /// Convert a [CliFlag] to an [OptionDefinition] for schema export.
  OptionDefinition toOptionDefinition({bool? isGlobalOverride}) {
    return OptionDefinition(
      name: name,
      description: description,
      short: abbreviation,
      type: switch (type) {
        FlagType.boolean => OptionType.flag,
        FlagType.singleValue => OptionType.value,
        FlagType.multiValue => OptionType.multiple,
      },
      defaultValue: defaultValue,
      allowedValues: allowedValues,
      isGlobal: isGlobalOverride ?? isGlobal,
    );
  }
}

