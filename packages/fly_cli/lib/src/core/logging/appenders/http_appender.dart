import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fly_cli/src/core/logging/appender.dart';
import 'package:fly_cli/src/core/logging/formatter.dart';
import 'package:fly_cli/src/core/logging/log_event.dart';

class HttpAppender implements Appender {
  HttpAppender(this.formatter, {required this.endpoint, this.token, this.requestTimeout = const Duration(seconds: 2)});

  final LogFormatter formatter;
  final Uri endpoint;
  final String? token;
  final Duration requestTimeout;

  DateTime _cooldownUntil = DateTime.fromMillisecondsSinceEpoch(0);
  int _backoffMs = 500;
  static const int _maxBackoffMs = 15000;

  @override
  String get name => 'http';

  @override
  Future<void> append(LogEvent event) async {
    final now = DateTime.now();
    if (now.isBefore(_cooldownUntil)) return;

    final bodyMap = formatter.formatToJson(event);
    final body = jsonEncode(bodyMap);

    final client = HttpClient();
    client.connectionTimeout = requestTimeout;
    try {
      final request = await client.postUrl(endpoint);
      request.headers.contentType = ContentType.json;
      if (token != null && token!.isNotEmpty) {
        request.headers.add('Authorization', 'Bearer $token');
      }
      request.write(body);
      final response = await request.close().timeout(requestTimeout);
      if (response.statusCode >= 400) {
        _scheduleBackoff();
      } else {
        _resetBackoff();
      }
    } catch (_) {
      _scheduleBackoff();
    } finally {
      client.close(force: true);
    }
  }

  void _scheduleBackoff() {
    _cooldownUntil = DateTime.now().add(Duration(milliseconds: _backoffMs));
    _backoffMs = (_backoffMs * 2).clamp(500, _maxBackoffMs);
  }

  void _resetBackoff() {
    _cooldownUntil = DateTime.fromMillisecondsSinceEpoch(0);
    _backoffMs = 500;
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> dispose() async {}
}


