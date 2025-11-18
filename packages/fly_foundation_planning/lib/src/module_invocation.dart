import 'package:fly_foundation_planning/src/foundation_model.dart';

/// Represents a module brick invocation that should be executed.
///
/// This class encapsulates which brick should be run, with what variables,
/// and where the output should be generated.
class ModuleInvocation {
  const ModuleInvocation({
    required this.moduleName,
    required this.brickId,
    required this.vars,
    this.targetDir,
  });

  /// The name of the module (e.g., 'project', 'feature', 'service').
  final String moduleName;

  /// The Mason brick identifier to use for generation.
  final String brickId;

  /// The variables to pass to the brick.
  final Map<String, dynamic> vars;

  /// Optional target directory. If null, uses the default output directory.
  final String? targetDir;

  @override
  String toString() => 'ModuleInvocation(module: $moduleName, brick: $brickId)';
}

/// Maps a generation mode to its corresponding module brick ID.
String getBrickIdForMode(GenerationMode mode) {
  switch (mode) {
    case GenerationMode.project:
      return 'fly_foundation_project';
    case GenerationMode.feature:
      return 'fly_foundation_feature';
    case GenerationMode.service:
      return 'fly_foundation_service';
  }
}

