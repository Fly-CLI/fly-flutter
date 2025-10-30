import 'dart:collection';

import 'package:dio/dio.dart';

/// Simple circuit breaker interceptor with failure accrual per host+path.
///
/// States:
/// - Closed: normal traffic. Failures are counted in a sliding window.
/// - Open: requests are short-circuited for a cool-down period.
/// - Half-Open: next trial request is allowed; success closes, failure reopens.
class CircuitBreakerInterceptor extends Interceptor {
  CircuitBreakerInterceptor({
    this.failureThreshold = 5,
    this.windowSize = 10,
    this.openDuration = const Duration(seconds: 30),
    this.evaluateOnStatus = const {500, 502, 503, 504},
    this.enabled = true,
  });

  final int failureThreshold;
  final int windowSize;
  final Duration openDuration;
  final Set<int> evaluateOnStatus;
  final bool enabled;

  final Map<String, _BreakerState> _states = HashMap();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) {
      handler.next(options);
      return;
    }
    final key = _keyFor(options);
    final state = _states.putIfAbsent(key, () => _BreakerState.closed());
    final now = DateTime.now();

    switch (state.state) {
      case _State.closed:
        handler.next(options);
        break;
      case _State.open:
        if (now.isAfter(state.openUntil)) {
          // Move to half-open and allow a trial
          state.state = _State.halfOpen;
          handler.next(options);
        } else {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              message: 'Circuit open; request short-circuited',
            ),
          );
        }
        break;
      case _State.halfOpen:
        // Allow single in-flight trial; serialize by marking trialInFlight
        if (state.trialInFlight) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              message: 'Circuit half-open; trial in flight',
            ),
          );
        } else {
          state.trialInFlight = true;
          handler.next(options);
        }
        break;
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enabled) {
      handler.next(response);
      return;
    }
    final key = _keyFor(response.requestOptions);
    final state = _states.putIfAbsent(key, _BreakerState.closed)

    // Success resets window and potentially closes breaker
    ..record(success: true);
    if (state.state == _State.halfOpen) {
      state.close();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) {
      handler.next(err);
      return;
    }
    final key = _keyFor(err.requestOptions);
    final state = _states.putIfAbsent(key, _BreakerState.closed);

    // Consider server errors and network errors as failures
    final statusCode = err.response?.statusCode;
    final isServerFailure = statusCode != null && evaluateOnStatus.contains(statusCode);
    final isNetworkFailure = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;

    if (isServerFailure || isNetworkFailure) {
      state.record(success: false);
      if (state.shouldOpen(failureThreshold)) {
        state.open(openDuration);
      }
      if (state.state == _State.halfOpen) {
        // Trial failed -> reopen
        state.open(openDuration);
      }
    } else {
      // Non-failure errors (e.g., 4xx) count as success for breaker purposes
      state.record(success: true);
      if (state.state == _State.halfOpen) {
        state.close();
      }
    }

    handler.next(err);
  }

  String _keyFor(RequestOptions options) {
    // Group by host+path; adjust granularity as needed
    final uri = options.uri;
    return '${uri.host}:${uri.port}${uri.path}';
  }
}

enum _State { closed, open, halfOpen }

class _BreakerState {
  _BreakerState.closed()
      : state = _State.closed,
        openUntil = DateTime.fromMillisecondsSinceEpoch(0),
        trialInFlight = false;

  _State state;
  DateTime openUntil;
  bool trialInFlight;
  final List<bool> _window = <bool>[];

  void record({required bool success}) {
    _window.add(success);
    if (_window.length > 10) {
      _window.removeAt(0);
    }
    if (state == _State.halfOpen) {
      trialInFlight = false;
    }
  }

  bool shouldOpen(int failureThreshold) {
    final failures = _window.where((e) => e == false).length;
    return failures >= failureThreshold;
  }

  void open(Duration duration) {
    state = _State.open;
    openUntil = DateTime.now().add(duration);
    trialInFlight = false;
    _window.clear();
  }

  void close() {
    state = _State.closed;
    trialInFlight = false;
    _window.clear();
  }
}


