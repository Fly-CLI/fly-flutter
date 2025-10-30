import 'package:fly_mcp_server/src/config/server_config.dart';

/// Path sandbox for workspace security
class PathSandbox {
  final String workspaceRoot;
  final SecurityConfig? securityConfig;

  PathSandbox({
    required this.workspaceRoot,
    this.securityConfig,
  });

  /// Resolve and validate a path is within workspace root
  /// Returns null if path is invalid or outside workspace
  String? resolvePath(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }

    try {
      final resolved = path.startsWith('/') || path.startsWith(workspaceRoot)
          ? path
          : '$workspaceRoot/$path';
      
      final normalized = _normalizePath(resolved);
      final rootNormalized = _normalizePath(workspaceRoot);

      // Ensure path is within workspace root
      if (!normalized.startsWith(rootNormalized)) {
        return null;
      }

      // Deny traversal attempts (after normalization, .. should be removed)
      if (resolved.contains('..')) {
        return null;
      }

      return normalized;
    } catch (_) {
      return null;
    }
  }

  /// Simple path normalization helper
  /// Preserves leading slash for absolute paths
  String _normalizePath(String path) {
    final isAbsolute = path.startsWith('/');
    final parts = <String>[];
    for (final part in path.split('/')) {
      if (part == '.' || part.isEmpty) {
        continue;
      } else if (part == '..') {
        if (parts.isNotEmpty) {
          parts.removeLast();
        }
      } else {
        parts.add(part);
      }
    }
    final normalized = parts.join('/');
    return isAbsolute ? '/$normalized' : normalized;
  }

  /// Check if a path is safe to read (within allowlist)
  ///
  /// Uses SecurityConfig to determine allowed file suffixes and filenames.
  /// If SecurityConfig is null or has no restrictions, all files are allowed.
  /// If SecurityConfig is provided with null/empty lists, strict mode is enforced (deny all).
  bool isAllowedRead(String path) {
    final resolved = resolvePath(path);
    if (resolved == null) return false;

    // If no security config, allow all files
    if (securityConfig == null) {
      return true;
    }

    // If security config has no restrictions (null lists), enforce strict mode (deny all)
    if (securityConfig!.allowedFileSuffixes == null &&
        securityConfig!.allowedFileNames == null) {
      return false;
    }

    // Check filename allowlist
    final filename = resolved.split('/').last;
    if (securityConfig!.allowedFileNames?.contains(filename) ?? false) {
      return true;
    }

    // Check suffix allowlist
    if (securityConfig!.allowedFileSuffixes != null) {
      for (final suffix in securityConfig!.allowedFileSuffixes!) {
        if (resolved.endsWith(suffix)) {
          return true;
        }
      }
    }

    // No matches found, deny access
    return false;
  }

  /// Check if a path is safe to write (within workspace, not in protected directories)
  ///
  /// Uses SecurityConfig to check protected directories.
  /// If SecurityConfig is null or has no protected directories, all paths are allowed.
  bool isAllowedWrite(String path) {
    final resolved = resolvePath(path);
    if (resolved == null) return false;

    // If no security config, allow all writes
    if (securityConfig == null) {
      return true;
    }

    // Check protected directories
    if (securityConfig!.protectedDirectories != null) {
      final normalizedResolved = _normalizePath(resolved);
      for (final protected in securityConfig!.protectedDirectories!) {
        final normalizedProtected = _normalizePath(protected);
        // Check if resolved path contains protected directory (normalized comparison)
        if (normalizedResolved.contains(normalizedProtected)) {
          return false;
        }
      }
    }

    return true;
  }
}

