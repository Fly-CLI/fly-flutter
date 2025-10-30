import 'dart:io';

import '../../domain/appender.dart';
import '../../domain/formatter.dart';
import '../../domain/log_event.dart';

class FileAppender implements Appender {
  FileAppender(this.formatter, {required this.path, this.maxBytes = 5 * 1024 * 1024, this.maxFiles = 3});

  final LogFormatter formatter;
  final String path;
  final int maxBytes;
  final int maxFiles;

  IOSink? _sink;

  @override
  String get name => 'file';

  Future<void> _ensureOpen() async {
    _sink ??= File(path).openWrite(mode: FileMode.append);
  }

  @override
  Future<void> append(LogEvent event) async {
    await _ensureOpen();
    final line = formatter.formatToString(event);
    _sink!.writeln(line);
    await _maybeRotate();
  }

  Future<void> _maybeRotate() async {
    final file = File(path);
    if (!await file.exists()) return;
    final stat = await file.stat();
    if (stat.size < maxBytes) return;

    await _sink?.flush();
    await _sink?.close();
    _sink = null;

    // Rotate: file -> file.1, file.1 -> file.2 ...
    for (int i = maxFiles - 1; i >= 1; i--) {
      final older = File('$path.$i');
      final newer = File('$path.${i + 1}');
      if (await older.exists()) {
        if (await newer.exists()) {
          await newer.delete();
        }
        await older.rename(newer.path);
      }
    }
    final first = File('$path.1');
    if (await first.exists()) {
      await first.delete();
    }
    await file.rename(first.path);
    // reopen new file
    _sink = File(path).openWrite(mode: FileMode.writeOnlyAppend);
  }

  @override
  Future<void> flush() async {
    await _sink?.flush();
  }

  @override
  Future<void> dispose() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }
}


