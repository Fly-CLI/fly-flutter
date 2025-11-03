import 'dart:convert';
import 'dart:io';

import 'package:fly_cli/src/core/telemetry/domain/metric.dart';
import 'metric_exporter.dart';

/// JSON exporter that writes metrics to a file
class JsonExporter implements MetricExporter {
  JsonExporter({this.filePath});

  final String? filePath;
  final List<Metric> _metrics = [];

  @override
  Future<void> export(List<Metric> metrics) async {
    _metrics.addAll(metrics);

    if (filePath != null) {
      final file = File(filePath!);
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'count': _metrics.length,
        'metrics': _metrics.map((m) => m.toJson()).toList(),
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getExportedData() async {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'count': _metrics.length,
      'metrics': _metrics.map((m) => m.toJson()).toList(),
    };
  }

  /// Get exported metrics
  List<Metric> get metrics => List.unmodifiable(_metrics);

  /// Clear exported metrics
  void clear() {
    _metrics.clear();
  }
}

