import 'package:test/test.dart';
import 'package:mason_logger/mason_logger.dart';

/// Mock logger for testing that captures log messages
class MockLogger extends Logger {
  final List<LogMessage> _messages = [];

  /// All logged messages
  List<LogMessage> get messages => List.unmodifiable(_messages);

  /// Info messages only
  List<String> get infoMessages => _messages
      .where((m) => m.level == Level.info)
      .map((m) => m.message)
      .toList();

  /// Warning messages only
  List<String> get warningMessages => _messages
      .where((m) => m.level == Level.warning)
      .map((m) => m.message)
      .toList();

  /// Error messages only
  List<String> get errorMessages => _messages
      .where((m) => m.level == Level.error)
      .map((m) => m.message)
      .toList();

  /// Detail messages only
  List<String> get detailMessages => _messages
      .where((m) => m.level == Level.info) // Use info level since detail doesn't exist
      .map((m) => m.message)
      .toList();

  /// Clear all logged messages
  void clear() {
    _messages.clear();
  }

  /// Check if a specific message was logged
  bool hasMessage(String message, {Level? level}) {
    return _messages.any((m) {
      final messageMatch = m.message.contains(message);
      if (level != null) {
        return messageMatch && m.level == level;
      }
      return messageMatch;
    });
  }

  /// Check if any message contains the given text
  bool containsMessage(String text) {
    return _messages.any((m) => m.message.contains(text));
  }

  /// Get the last message of a specific level
  String? getLastMessage({Level? level}) {
    final filteredMessages = level != null
        ? _messages.where((m) => m.level == level).toList()
        : _messages;
    
    if (filteredMessages.isEmpty) return null;
    return filteredMessages.last.message;
  }

  @override
  void info(String? message, {LogStyle? style}) {
    if (message != null) {
      _messages.add(LogMessage(Level.info, message));
    }
  }

  @override
  void warn(String? message, {String tag = 'WARN', LogStyle? style}) {
    if (message != null) {
      _messages.add(LogMessage(Level.warning, message));
    }
  }

  @override
  void err(String? message, {LogStyle? style}) {
    if (message != null) {
      _messages.add(LogMessage(Level.error, message));
    }
  }

  @override
  void detail(String? message, {LogStyle? style}) {
    if (message != null) {
      _messages.add(LogMessage(Level.info, message)); // Use info level since detail doesn't exist
    }
  }

  @override
  void alert(String? message, {LogStyle? style}) {
    if (message != null) {
      _messages.add(LogMessage(Level.error, message)); // Use error level since alert doesn't exist
    }
  }

  @override
  void write(String? message) {
    if (message != null) {
      _messages.add(LogMessage(Level.info, message));
    }
  }

  @override
  void writeln(String message) {
    _messages.add(LogMessage(Level.info, message));
  }

  /// Verify that specific messages were logged
  void verifyMessages({
    List<String>? expectedInfo,
    List<String>? expectedWarnings,
    List<String>? expectedErrors,
    List<String>? expectedDetails,
  }) {
    if (expectedInfo != null) {
      for (final expected in expectedInfo) {
        expect(hasMessage(expected, level: Level.info), isTrue,
            reason: 'Expected info message: $expected');
      }
    }

    if (expectedWarnings != null) {
      for (final expected in expectedWarnings) {
        expect(hasMessage(expected, level: Level.warning), isTrue,
            reason: 'Expected warning message: $expected');
      }
    }

    if (expectedErrors != null) {
      for (final expected in expectedErrors) {
        expect(hasMessage(expected, level: Level.error), isTrue,
            reason: 'Expected error message: $expected');
      }
    }

    if (expectedDetails != null) {
      for (final expected in expectedDetails) {
        expect(hasMessage(expected, level: Level.info), isTrue, // Use info level since detail doesn't exist
            reason: 'Expected detail message: $expected');
      }
    }
  }

  /// Verify that no error messages were logged
  void verifyNoErrors() {
    expect(errorMessages, isEmpty, reason: 'Expected no error messages');
  }

  /// Verify that no warning messages were logged
  void verifyNoWarnings() {
    expect(warningMessages, isEmpty, reason: 'Expected no warning messages');
  }

  /// Print all messages for debugging
  void printAllMessages() {
    for (final message in _messages) {
      print('${message.level.name.toUpperCase()}: ${message.message}');
    }
  }
}

/// Represents a logged message with its level
class LogMessage {
  final Level level;
  final String message;

  LogMessage(this.level, this.message);

  @override
  String toString() => '${level.name}: $message';
}

/// Extension methods for easier testing
extension MockLoggerMatchers on MockLogger {
  /// Expect that a specific message was logged
  void expectMessage(String message, {Level? level}) {
    expect(hasMessage(message, level: level), isTrue,
        reason: 'Expected message: $message${level != null ? ' (${level.name})' : ''}');
  }

  /// Expect that no messages were logged
  void expectNoMessages() {
    expect(_messages, isEmpty, reason: 'Expected no messages to be logged');
  }

  /// Expect that exactly N messages were logged
  void expectMessageCount(int count) {
    expect(_messages.length, equals(count),
        reason: 'Expected $count messages, got ${_messages.length}');
  }
}
