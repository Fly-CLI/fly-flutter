import 'package:mason/mason.dart';

/// Interface for Mason operations adapter.
///
/// Abstracts Mason-specific operations, allowing for easier testing
/// and potential future replacements.
abstract class IMasonAdapter {
  /// Generate code from a brick.
  ///
  /// [brick] is the Mason brick to use.
  /// [target] is the target directory.
  /// [vars] are the variables to pass to the brick.
  /// [logger] is used for logging progress.
  ///
  /// Returns a list of [GeneratedFile] that were created.
  Future<List<GeneratedFile>> generate({
    required Brick brick,
    required String target,
    required Map<String, dynamic> vars,
    Logger? logger,
  });

  /// Create a brick from a path.
  ///
  /// Returns a [Brick] instance.
  Future<Brick> createBrick(String path);

  /// Check if a brick path is valid.
  Future<bool> isValidBrickPath(String path);
}
