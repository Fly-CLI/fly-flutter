import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_networking/src/interceptors/retry_interceptor.dart';

import 'helpers/mock_adapter.dart';

void main() {
  group('RetryInterceptor', () {
    test('does not retry POST without idempotency key', () async {
      final dio = Dio();
      final adapter = QueuedMockAdapter();
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(RetryInterceptor(dio: dio));

      // First request fails with 500. Without idempotency key, no retry should happen.
      adapter.enqueueError(DioException(
        requestOptions: RequestOptions(path: '/post'),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(path: '/post'), statusCode: 500),
      ));

      expect(
        () => dio.post('/post', data: {'x': 1}),
        throwsA(isA<DioException>()),
      );
    });

    test('retries POST when Idempotency-Key is present', () async {
      final dio = Dio();
      final adapter = QueuedMockAdapter();
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(RetryInterceptor(dio: dio, maxRetries: 1));

      // First attempt -> 500
      adapter.enqueueError(DioException(
        requestOptions: RequestOptions(path: '/post'),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(path: '/post'), statusCode: 500),
      ));
      // Second attempt -> 200
      adapter.enqueueResponse(ResponseBody.fromString('ok', 200));

      final res = await dio.post(
        '/post',
        data: {'x': 1},
        options: Options(headers: {'Idempotency-Key': 'abc'}),
      );
      expect(res.statusCode, 200);
    });

    test('honors Retry-After header for 429/503 (no assertion on time)', () async {
      final dio = Dio();
      final adapter = QueuedMockAdapter();
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(RetryInterceptor(dio: dio, maxRetries: 1));

      // First attempt -> 429 with Retry-After
      adapter.enqueueError(DioException(
        requestOptions: RequestOptions(path: '/get'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/get'),
          statusCode: 429,
          headers: Headers.fromMap({'retry-after': ['1']}),
        ),
      ));
      // Second attempt -> 200
      adapter.enqueueResponse(ResponseBody.fromString('ok', 200));

      final res = await dio.get('/get');
      expect(res.statusCode, 200);
    });
  });
}


