typedef JsonMap = Map<String, Object?>;

class RedactionPolicy {
  RedactionPolicy({List<Pattern>? redactKeys, List<Pattern>? redactValues})
      : _redactKeyPatterns = redactKeys ?? _defaultKeyPatterns,
        _redactValuePatterns = redactValues ?? _defaultValuePatterns;

  static final List<Pattern> _defaultKeyPatterns = <Pattern>[
    RegExp('token', caseSensitive: false),
    RegExp('secret', caseSensitive: false),
    RegExp('password', caseSensitive: false),
    RegExp('api[_-]?key', caseSensitive: false),
  ];

  static final List<Pattern> _defaultValuePatterns = <Pattern>[
    RegExp(r'Bearer\s+[A-Za-z0-9\-_.]+'),
  ];

  final List<Pattern> _redactKeyPatterns;
  final List<Pattern> _redactValuePatterns;

  JsonMap scrub(JsonMap input) {
    final out = <String, Object?>{};
    input.forEach((k, v) {
      if (_matchesAny(k, _redactKeyPatterns)) {
        out[k] = _mask(v);
      } else if (v is String && _matchesAny(v, _redactValuePatterns)) {
        out[k] = _mask(v);
      } else if (v is Map<String, Object?>) {
        out[k] = scrub(v);
      } else if (v is List) {
        out[k] = v.map((e) => e is Map<String, Object?> ? scrub(e) : e).toList();
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  bool _matchesAny(String text, List<Pattern> patterns) {
    for (final p in patterns) {
      if (p is RegExp) {
        if (p.hasMatch(text)) return true;
      } else if (text.contains(p)) {
        return true;
      }
    }
    return false;
  }

  String _mask(Object? value) {
    final s = value?.toString() ?? '';
    if (s.length <= 4) return '****';
    return '${s.substring(0, 2)}****${s.substring(s.length - 2)}';
  }
}


