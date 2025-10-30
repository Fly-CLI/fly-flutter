import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A simple queued mock adapter for Dio that returns pre-configured
/// responses or errors in order. Useful for interceptor testing.
class QueuedMockAdapter implements HttpClientAdapter {
  final List<_Planned> _queue = <_Planned>[];

  void enqueueResponse(
    ResponseBody body, {
    int statusCode = 200,
    Map<String, List<String>>? headers,
  }) {
    // We enqueue the provided body directly. Callers can construct the desired
    // ResponseBody (status code, headers, etc.) before enqueuing.
    _queue.add(_Planned.response(body));
  }

  void enqueueError(DioException error) {
    _queue.add(_Planned.error(error));
  }

  @override
  void close({bool force = false}) {
    _queue.clear();
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_queue.isEmpty) {
      return ResponseBody.fromString('', 200);
    }

    final planned = _queue.removeAt(0);
    if (planned.isError) {
      throw planned.error!;
    }
    return planned.body!;
  }
}

class _Planned {
  _Planned.response(this.body)
      : error = null,
        isError = false;

  _Planned.error(this.error)
      : body = null,
        isError = true;

  final ResponseBody? body;
  final DioException? error;
  final bool isError;
}


