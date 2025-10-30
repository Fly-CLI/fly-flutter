import 'dart:io';

import 'package:fly_core/src/environment/env_var.dart';

/// Provides a single source of truth for accessing environment variables
/// from both compile-time defines (-D) and runtime process environment.
class EnvironmentManager {
  const EnvironmentManager();

  /// Whether the code is compiled in product mode.
  bool get isProduct => const bool.fromEnvironment('dart.vm.product');

  /// Returns true if a value exists for the variable in either compile-time
  /// defines or runtime process environment.
  bool has(EnvVar variable) {
    // Synthetic flags are only available via compile-time defines.
    if (variable == EnvVar.productMode) {
      return bool.fromEnvironment(variable.key);
    }
    final fromDefine = _readDefineRaw(variable.key);
    if (fromDefine != null) return true;
    return Platform.environment.containsKey(variable.key);
  }

  /// Get a typed value with optional default.
  /// Get a typed value for [variable]. Returns [defaultValue] when not set.
  T? getValue<T>(EnvVar variable, {T? defaultValue}) {
    final raw = _resolveRaw(variable);
    if (raw == null || raw.isEmpty) return defaultValue;

    switch (variable.type) {
      case EnvType.string:
        return raw as T?;
      case EnvType.boolean:
        final v = _parseBool(raw);
        return v as T?;
      case EnvType.integer:
        final v = int.tryParse(raw);
        return v as T?;
    }
  }

  /// Read [variable] as a [String].
  String? getString(EnvVar variable, {String? defaultValue}) =>
      getValue<String>(variable, defaultValue: defaultValue);

  /// Read [variable] as a [bool].
  bool getBool(EnvVar variable, {bool? defaultValue}) =>
      getValue<bool>(variable, defaultValue: defaultValue) ?? false;

  /// Read [variable] as an [int].
  int? getInt(EnvVar variable, {int? defaultValue}) =>
      getValue<int>(variable, defaultValue: defaultValue);

  /// Returns a snapshot of all runtime environment variables.
  /// Note: compile-time defines are not enumerable at runtime.
  Map<String, String> all() => Map<String, String>.from(Platform.environment);

  /// Convenience flag used widely for CLI output formatting.
  bool get jsonOutputEnabled =>
      getBool(EnvVar.flyJsonOutput, defaultValue: false);

  // Resolve a raw string value with precedence: define > env > null
  String? _resolveRaw(EnvVar variable) {
    if (variable == EnvVar.productMode) {
      return bool.fromEnvironment(variable.key) ? 'true' : 'false';
    }

    final defined = _readDefineRaw(variable.key);
    if (defined != null) return defined;
    return Platform.environment[variable.key];
  }

  // Read compile-time define as raw string, if present.
  String? _readDefineRaw(String key) {
    // Dart offers typed fromEnvironment constructors; emulate string read
    // by trying String.fromEnvironment first with no default (empty means absent).
    const sentinel = '<<__absent__>>';
    final s = String.fromEnvironment(
      key,
      defaultValue: sentinel,
    );
    if (s != sentinel) return s;

    // For booleans and ints, if provided without explicit string, the above
    // already returns sentinel; but also check bool/int fromEnvironment
    final bIsSet = bool.fromEnvironment(key);
    if (bIsSet) return 'true';
    const sentinelInt = -9223372036854775808;
    final i = int.fromEnvironment(
      key,
      defaultValue: sentinelInt,
    );
    if (i != sentinelInt) return i.toString();
    return null;
  }

  static bool _parseBool(String raw) {
    switch (raw.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'y':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'n':
      case 'off':
        return false;
      default:
        return false;
    }
  }
}


