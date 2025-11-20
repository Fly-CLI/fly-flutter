import 'package:fly_foundation_planning/src/foundation_model.dart';

/// Represents a brick invocation that should be executed.
///
/// This is the primary model for workflow-agnostic brick invocations.
/// It encapsulates which brick should be run, with what variables,
/// and where the output should be generated.
class BrickInvocation {
  const BrickInvocation({
    required this.invocationId,
    required this.brickId,
    required this.displayName,
    required this.phase,
    required this.vars,
    this.targetDir,
  });

  /// Unique identifier for this invocation (for logging/tracking).
  final String invocationId;

  /// The Mason brick identifier to use for generation.
  final String brickId;

  /// Human-readable display name (e.g., 'project', 'feature:home', 'service:api:core').
  final String displayName;

  /// Phase/ordering group (lower numbers run earlier).
  final int phase;

  /// The variables to pass to the brick.
  final Map<String, dynamic> vars;

  /// Optional target directory (relative to overall output dir).
  /// If null, uses the default output directory.
  final String? targetDir;

  @override
  String toString() =>
      'BrickInvocation(id: $invocationId, brick: $brickId, phase: $phase)';
}

