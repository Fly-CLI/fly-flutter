/// Immutable representation of all derived variables.
///
/// This is the single source of truth for derived variables throughout the
/// planning pipeline. All brick execution and Mason integration operate on
/// VariableBag → flat Map<String, dynamic>.
class VariableBag {
  final Map<String, dynamic> _values;

  const VariableBag._(this._values);

  /// Creates an empty variable bag.
  factory VariableBag.empty() => const VariableBag._({});

  /// Creates a variable bag from a map of values.
  factory VariableBag.fromMap(Map<String, dynamic> values) =>
      VariableBag._(Map.unmodifiable(values));

  /// Gets a value by key with type inference.
  ///
  /// Returns null if the key is not present or if the value cannot be cast to T.
  T? get<T>(String key) {
    final value = _values[key];
    if (value == null) return null;
    try {
      return value as T;
    } catch (_) {
      return null;
    }
  }

  /// Checks if a key exists in the bag.
  bool containsKey(String key) => _values.containsKey(key);

  /// Gets all keys in the bag.
  Set<String> get keys => _values.keys.toSet();

  /// Sets a value in the bag, returning a new bag.
  ///
  /// If value is null, returns the original bag unchanged.
  VariableBag set(String key, Object? value) {
    if (value == null) return this;
    return VariableBag._({..._values, key: value});
  }

  /// Sets multiple values at once, returning a new bag.
  VariableBag setAll(Map<String, Object?> values) {
    final filtered = <String, dynamic>{};
    for (final entry in values.entries) {
      if (entry.value != null) {
        filtered[entry.key] = entry.value;
      }
    }
    if (filtered.isEmpty) return this;
    return VariableBag._({..._values, ...filtered});
  }

  /// Merges another bag into this one, with the other bag taking precedence.
  VariableBag merge(VariableBag other) =>
      VariableBag._({..._values, ...other._values});

  /// Converts to an unmodifiable map for Mason integration.
  Map<String, dynamic> toMap() => Map.unmodifiable(_values);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariableBag &&
          runtimeType == other.runtimeType &&
          _mapEquals(_values, other._values);

  @override
  int get hashCode => _mapHash(_values);

  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  int _mapHash(Map<String, dynamic> map) {
    var hash = 0;
    for (final entry in map.entries) {
      hash = hash ^ entry.key.hashCode ^ entry.value.hashCode;
    }
    return hash;
  }

  @override
  String toString() => 'VariableBag(${_values.keys.length} keys)';
}

