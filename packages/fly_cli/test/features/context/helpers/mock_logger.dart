import 'package:mason_logger/mason_logger.dart';

/// Mock logger for testing
class MockLogger implements Logger {
  final List<String> _logs = [];
  final List<String> _errors = [];
  final List<String> _warnings = [];
  final List<String> _infos = [];

  @override
  Level level = Level.info;

  @override
  LogTheme theme = LogTheme();

  @override
  ProgressOptions progressOptions = ProgressOptions();

  @override
  void alert(String? message, {LogStyle? style}) {
    _logs.add('ALERT: $message');
  }

  @override
  void err(String? message, {LogStyle? style}) {
    _errors.add(message ?? '');
    _logs.add('ERROR: $message');
  }

  @override
  void warn(String? message, {String tag = 'WARN', LogStyle? style}) {
    _warnings.add(message ?? '');
    _logs.add('WARN: $message');
  }

  @override
  void info(String? message, {LogStyle? style}) {
    _infos.add(message ?? '');
    _logs.add('INFO: $message');
  }

  @override
  void detail(String? message, {LogStyle? style}) {
    _logs.add('DETAIL: $message');
  }

  @override
  void trace(String? message) {
    _logs.add('TRACE: $message');
  }

  @override
  void success(String? message, {LogStyle? style}) {
    _logs.add('SUCCESS: $message');
  }

  @override
  Progress progress(String message, {ProgressOptions? options}) {
    _logs.add('PROGRESS: $message');
    // Return a mock progress object
    return MockProgress();
  }

  @override
  void write(String? message) {
    _logs.add(message ?? '');
  }

  @override
  void writeln(String? message) {
    _logs.add(message ?? '');
  }

  @override
  void newline() {
    _logs.add('');
  }

  @override
  void clear() {
    _logs.clear();
    _errors.clear();
    _warnings.clear();
    _infos.clear();
  }

  @override
  void flush([void Function(String?)? print]) {
    // Mock implementation - do nothing
  }

  @override
  void delayed(String? message) {
    _logs.add('DELAYED: $message');
  }

  @override
  String prompt(String? message, {Object? defaultValue, bool hidden = false}) {
    _logs.add('PROMPT: $message');
    return defaultValue?.toString() ?? '';
  }

  @override
  List<String> promptAny(String? message, {String separator = ','}) {
    _logs.add('PROMPT_ANY: $message');
    return [];
  }

  @override
  bool confirm(String? message, {bool defaultValue = false}) {
    _logs.add('CONFIRM: $message');
    return defaultValue;
  }

  @override
  T chooseOne<T extends Object?>(
    String? message, {
    required List<T> choices,
    T? defaultValue,
    bool oneBased = true,
    String Function(T)? display,
  }) {
    _logs.add('CHOOSE_ONE: $message');
    return defaultValue ?? choices.first;
  }

  @override
  List<T> chooseAny<T extends Object?>(
    String? message, {
    required List<T> choices,
    List<T>? defaults,
    List<T>? defaultValues,
    bool oneBased = true,
    String Function(T)? display,
  }) {
    _logs.add('CHOOSE_ANY: $message');
    return defaults ?? defaultValues ?? [];
  }

  // Test helper methods
  List<String> get logs => List.unmodifiable(_logs);
  List<String> get errors => List.unmodifiable(_errors);
  List<String> get warnings => List.unmodifiable(_warnings);
  List<String> get infos => List.unmodifiable(_infos);

  bool hasError(String message) => _errors.any((e) => e.contains(message));
  bool hasWarning(String message) => _warnings.any((w) => w.contains(message));
  bool hasInfo(String message) => _infos.any((i) => i.contains(message));
  bool hasLog(String message) => _logs.any((l) => l.contains(message));

  void reset() {
    clear();
  }
}

/// Mock progress for testing
class MockProgress implements Progress {
  @override
  void complete([String? message]) {
    // Mock implementation
  }

  @override
  void fail([String? update]) {
    // Mock implementation
  }

  @override
  void cancel() {
    // Mock implementation
  }

  @override
  void update(String message) {
    // Mock implementation
  }
}