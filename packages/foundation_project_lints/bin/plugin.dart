import 'dart:io';
import 'dart:isolate';

import 'package:analyzer_plugin/starter.dart';
import 'package:foundation_project_lints/analyzer_plugin/foundation_project_lints_analyzer.dart';

/// Entry point for the standard analyzer plugin
///
/// This creates a standard analyzer plugin that works with flutter analyze.
/// The plugin is started by the analysis server when it detects the plugin
/// in analysis_options.yaml.
void main(List<String> args, SendPort sendPort) {
  // Debug: Log plugin startup
  try {
    final debugFile = File('/tmp/foundation_project_lints_debug.log');
    debugFile.writeAsStringSync(
      'Plugin started at ${DateTime.now()}\nArgs: $args\n',
      mode: FileMode.append,
    );
  } catch (e) {
    // Ignore debug logging errors
  }

  final plugin = FoundationProjectLintsAnalyzerPlugin();
  final starter = ServerPluginStarter(plugin);
  starter.start(sendPort);
}

