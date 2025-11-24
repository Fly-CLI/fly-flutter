import 'package:args/args.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';

/// Type-safe flag accessor utilities
/// Provides safe access to flag values from ArgResults using CliFlag enums
class FlagAccessor {
  /// Get a flag value with type safety
  ///
  /// Returns the value from ArgResults for the given flag, or null if not set
  static T? getValue<T>(ArgResults? args, CliFlag flag) {
    if (args == null) return null;

    if (!_hasOption(args, flag.name)) {
      return null;
    }

    try {
      if (!args.wasParsed(flag.name)) {
        return null;
      }
    } on ArgumentError {
      return null;
    }

    final value = args[flag.name];
    if (value == null) return null;

    try {
      return value as T;
    } catch (_) {
      return null;
    }
  }

  /// Check if a flag is set in the arguments
  ///
  /// Returns true if the flag was explicitly provided in the command line
  static bool isSet(ArgResults? args, CliFlag flag) {
    if (args == null) return false;
    if (!_hasOption(args, flag.name)) return false;

    try {
      return args.wasParsed(flag.name);
    } on ArgumentError {
      return false;
    }
  }

  /// Get a flag value with a default fallback
  ///
  /// Returns the flag value if set, otherwise returns the provided default
  static T getValueOrDefault<T>(ArgResults? args, CliFlag flag, T defaultValue) {
    final value = getValue<T>(args, flag);
    return value ?? defaultValue;
  }

  /// Get a flag value using the flag's own default value
  ///
  /// Returns the flag value if set, otherwise returns the flag's default value
  static T? getValueWithFlagDefault<T>(ArgResults? args, CliFlag flag) {
    final value = getValue<T>(args, flag);
    if (value != null) return value;

    if (flag.defaultValue != null) {
      try {
        return flag.defaultValue as T?;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Get a boolean flag value (convenience method)
  ///
  /// Returns true if flag is set and truthy, false otherwise
  static bool getBool(ArgResults? args, CliFlag flag) {
    final value = getValue<bool>(args, flag);
    return value ?? false;
  }

  /// Get a string flag value (convenience method)
  ///
  /// Returns the string value or null if not set
  static String? getString(ArgResults? args, CliFlag flag) {
    return getValue<String>(args, flag);
  }

  /// Get a string flag value with default (convenience method)
  ///
  /// Returns the string value or the default if not set
  static String getStringOrDefault(ArgResults? args, CliFlag flag, String defaultValue) {
    return getValueOrDefault<String>(args, flag, defaultValue);
  }

  /// Get a list of strings (for multi-value flags)
  ///
  /// Returns the list of values or empty list if not set
  static List<String> getStringList(ArgResults? args, CliFlag flag) {
    return getValue<List<String>>(args, flag) ?? [];
  }

  static bool _hasOption(ArgResults args, String flagName) {
    try {
      args[flagName];
      return true;
    } on ArgumentError {
      return false;
    }
  }
}

