import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:foundation_project_lints/analyzer_plugin/foundation_project_lints_analyzer.dart';

/// Entry point for the standard analyzer plugin
///
/// This is not used by the standard analyzer plugin - bin/plugin.dart is used instead.
/// This file is kept for potential future use or compatibility.
ServerPlugin createPlugin() {
  return FoundationProjectLintsAnalyzerPlugin();
}

