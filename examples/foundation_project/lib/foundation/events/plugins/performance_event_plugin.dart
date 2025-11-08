import 'dart:async';
import 'package:fly_di/fly_di.dart';
import 'package:fly_events/fly_events.dart';

/// Performance monitoring plugin that tracks async operation metrics
///
/// This plugin demonstrates how to monitor foundation operations
/// without being coupled to the foundation system.
///
/// **Usage:**
/// ```dart
/// final plugin = PerformanceEventPlugin();
/// plugin.initialize();
///
/// // Later, when disposing:
/// plugin.dispose();
///
/// // Get performance metrics:
/// final metrics = plugin.getMetrics();
/// ```
class PerformanceEventPlugin {
  AppEventEmitter? _emitter;
  StreamSubscription<FoundationOperationEvent>? _operationSubscription;
  final Map<String, DateTime> _operationStartTimes = {};
  final List<OperationMetric> _completedOperations = [];
  final List<OperationFailure> _failedOperations = [];

  /// Initialize the plugin and start listening to events
  void initialize() {
    _emitter = DependencyContainer.instance.read(eventEmitterProvider);

    // Listen to foundation operation events
    _operationSubscription = _emitter!.getStreamFor<FoundationOperationEvent>().listen(
      (event) {
        if (event is AsyncOperationStartedEvent) {
          _onOperationStarted(event);
        } else if (event is AsyncOperationCompletedEvent) {
          _onOperationCompleted(event);
        } else if (event is AsyncOperationFailedEvent) {
          _onOperationFailed(event);
        }
      },
    );
  }

  void _onOperationStarted(AsyncOperationStartedEvent event) {
    _operationStartTimes[event.operationId] = DateTime.now();
  }

  void _onOperationCompleted(AsyncOperationCompletedEvent event) {
    _completedOperations.add(
      OperationMetric(
        operationId: event.operationId,
        operationName: event.operationName,
        duration: event.duration,
        success: event.success,
        timestamp: event.timestamp,
      ),
    );
    _operationStartTimes.remove(event.operationId);
  }

  void _onOperationFailed(AsyncOperationFailedEvent event) {
    _failedOperations.add(
      OperationFailure(
        operationId: event.operationId,
        operationName: event.operationName,
        error: event.error,
        duration: event.duration,
        timestamp: event.timestamp,
      ),
    );
    _operationStartTimes.remove(event.operationId);
  }

  /// Get performance metrics
  PerformanceMetrics getMetrics() {
    return PerformanceMetrics(
      completedOperations: List.unmodifiable(_completedOperations),
      failedOperations: List.unmodifiable(_failedOperations),
      averageDuration: _calculateAverageDuration(),
      failureRate: _calculateFailureRate(),
    );
  }

  Duration? _calculateAverageDuration() {
    if (_completedOperations.isEmpty) return null;
    final totalMilliseconds = _completedOperations
        .map((op) => op.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    return Duration(milliseconds: totalMilliseconds ~/ _completedOperations.length);
  }

  double _calculateFailureRate() {
    final total = _completedOperations.length + _failedOperations.length;
    if (total == 0) return 0.0;
    return _failedOperations.length / total;
  }

  /// Dispose the plugin and cancel subscriptions
  void dispose() {
    _operationSubscription?.cancel();
    _operationSubscription = null;
    _emitter = null;
    _operationStartTimes.clear();
    _completedOperations.clear();
    _failedOperations.clear();
  }
}

/// Performance metrics data class
class PerformanceMetrics {
  final List<OperationMetric> completedOperations;
  final List<OperationFailure> failedOperations;
  final Duration? averageDuration;
  final double failureRate;

  PerformanceMetrics({
    required this.completedOperations,
    required this.failedOperations,
    required this.averageDuration,
    required this.failureRate,
  });
}

/// Operation metric data class
class OperationMetric {
  final String operationId;
  final String operationName;
  final Duration duration;
  final bool success;
  final DateTime timestamp;

  OperationMetric({
    required this.operationId,
    required this.operationName,
    required this.duration,
    required this.success,
    required this.timestamp,
  });
}

/// Operation failure data class
class OperationFailure {
  final String operationId;
  final String operationName;
  final String error;
  final Duration duration;
  final DateTime timestamp;

  OperationFailure({
    required this.operationId,
    required this.operationName,
    required this.error,
    required this.duration,
    required this.timestamp,
  });
}

