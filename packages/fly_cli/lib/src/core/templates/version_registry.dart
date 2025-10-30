import 'dart:io';

import 'package:fly_cli/src/core/templates/template_info.dart';
import 'package:fly_cli/src/core/templates/template_version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Registry for managing template versions
class VersionRegistry {
  VersionRegistry({
    required this.templatesDirectory,
    required this.logger,
    required this.loadTemplateInfo,
  });

  final String templatesDirectory;
  final Logger logger;
  final Future<TemplateInfo?> Function(String templatePath) loadTemplateInfo;

  /// Cache for version information with timestamps
  final Map<String, _CachedVersions> _versionsCache = {};

  /// Cache expiration time in milliseconds (default: 5 minutes)
  static const int cacheExpirationMs = 5 * 60 * 1000;

  /// Validate and sanitize template name to prevent path traversal
  String _sanitizeTemplateName(String templateName) {
    // Remove any path separators and parent directory references
    final sanitized = templateName
        .replaceAll(RegExp(r'[\\/]'), '')
        .replaceAll('..', '')
        .trim();
    
    if (sanitized.isEmpty) {
      throw ArgumentError('Template name cannot be empty');
    }
    
    if (sanitized != templateName) {
      logger.warn(
        'Template name sanitized from "$templateName" to "$sanitized"',
      );
    }
    
    return sanitized;
  }

  /// Find template path in projects or components subdirectories
  /// Returns the path to the template directory, or null if not found
  Future<String?> _findTemplatePath(String sanitizedName) async {
    // Check projects subdirectory
    final projectsPath = path.join(templatesDirectory, 'projects', sanitizedName);
    if (await Directory(projectsPath).exists()) {
      return projectsPath;
    }
    
    // Check components subdirectory
    final componentsPath = path.join(templatesDirectory, 'components', sanitizedName);
    if (await Directory(componentsPath).exists()) {
      return componentsPath;
    }
    
    // Fallback: check directly in templatesDirectory (for test compatibility and flexibility)
    final directPath = path.join(templatesDirectory, sanitizedName);
    if (await Directory(directPath).exists()) {
      return directPath;
    }
    
    return null;
  }

  /// Get all available versions for a template
  /// 
  /// Supports both single-version (backward compatible) and multi-version templates.
  /// Returns versions sorted semantically (latest first).
  Future<List<String>> getVersions(String templateName) async {
    // Sanitize template name to prevent path traversal
    final sanitizedName = _sanitizeTemplateName(templateName);
    
    // Check cache first
    final cached = _versionsCache[sanitizedName];
    if (cached != null && !cached.isExpired) {
      return List<String>.from(cached.versions);
    }

    final versions = <String>{};

    try {
      // Find template path (checking subdirectories)
      final templatePath = await _findTemplatePath(sanitizedName);
      if (templatePath == null) {
        return [];
      }

      // Check if versions.yaml exists (multi-version template)
      final versionsYamlPath = path.join(templatePath, 'versions.yaml');
      final versionsYamlFile = File(versionsYamlPath);

      if (await versionsYamlFile.exists()) {
        try {
          final yamlContent = await versionsYamlFile.readAsString();
          final yaml = loadYaml(yamlContent) as Map<dynamic, dynamic>;
          
          final versionsList = yaml['versions'] as List<dynamic>?;
          if (versionsList != null) {
            for (final v in versionsList) {
              final versionStr = v.toString().trim();
              if (versionStr.isNotEmpty) {
                // Validate version format
                if (TemplateVersion.tryParse(versionStr) != null) {
                  versions.add(versionStr);
                } else {
                  logger.warn(
                    'Invalid version format "$versionStr" in versions.yaml for $sanitizedName',
                  );
                }
              }
            }
          }
        } catch (e) {
          logger.warn('Error reading versions.yaml for $sanitizedName: $e');
        }
      }

      // Fallback: check for versioned directories
      final templateDir = Directory(templatePath);
      if (await templateDir.exists()) {
        try {
          await for (final entity in templateDir.list()) {
            if (entity is Directory) {
              final dirName = path.basename(entity.path);
              // Check if directory name looks like a version
              if (TemplateVersion.tryParse(dirName) != null) {
                versions.add(dirName);
              }
            }
          }
        } catch (e) {
          logger.warn(
            'Error reading version directories for $sanitizedName: $e',
          );
        }
      }

      // Fallback: get version from template.yaml (single version)
      if (versions.isEmpty) {
        try {
          final template = await loadTemplateInfo(templatePath);
          if (template != null && template.version.isNotEmpty) {
            // Validate version format
            if (TemplateVersion.tryParse(template.version) != null) {
              versions.add(template.version);
            }
          }
        } catch (e) {
          logger.warn(
            'Error loading template.yaml for $sanitizedName: $e',
          );
        }
      }
    } catch (e) {
      logger.err('Error discovering versions for $sanitizedName: $e');
      return [];
    }

    // Convert to list, deduplicate, and sort semantically
    final versionsList = versions.toList();
    final sortedVersions = _sortVersionsSemantically(versionsList);

    // Cache results with timestamp
    _versionsCache[sanitizedName] = _CachedVersions(
      versions: sortedVersions,
      cachedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    return sortedVersions;
  }

  /// Sort versions semantically (latest first)
  List<String> _sortVersionsSemantically(List<String> versions) {
    final parsedVersions = versions
        .map((v) => TemplateVersion.tryParse(v))
        .whereType<TemplateVersion>()
        .toList();

    if (parsedVersions.isEmpty) {
      return versions;
    }

    // Sort: latest first
    parsedVersions.sort((a, b) => b.compareTo(a));
    
    // Map back to strings, preserving invalid versions at the end
    final sorted = parsedVersions.map((v) => v.versionString).toList();
    final invalidVersions = versions
        .where((v) => TemplateVersion.tryParse(v) == null)
        .toList();
    
    return [...sorted, ...invalidVersions];
  }

  /// Get template for a specific version
  Future<TemplateInfo?> getTemplateVersion(
    String templateName,
    String version,
  ) async {
    // Sanitize template name
    final sanitizedName = _sanitizeTemplateName(templateName);
    
    // Validate version format
    if (TemplateVersion.tryParse(version) == null) {
      logger.warn('Invalid version format: "$version" for template $sanitizedName');
      return null;
    }

    try {
      // First check if template name@version format directory exists
      // (this can exist independently without a base template)
      // Try in both subdirectories and direct path (for test compatibility)
      final possiblePaths = [
        path.join(templatesDirectory, 'projects', '$sanitizedName@$version'),
        path.join(templatesDirectory, 'components', '$sanitizedName@$version'),
        path.join(templatesDirectory, '$sanitizedName@$version'),
      ];

      for (final templateVersionPath in possiblePaths) {
        final templateVersionDir = Directory(templateVersionPath);
        if (await templateVersionDir.exists()) {
          return await loadTemplateInfo(templateVersionPath);
        }
      }

      // Find base template path (checking subdirectories)
      final basePath = await _findTemplatePath(sanitizedName);
      if (basePath == null) {
        return null;
      }

      // Check if versioned directory exists
      final versionedPath = path.join(basePath, 'versions', version);
      final versionedDir = Directory(versionedPath);

      if (await versionedDir.exists()) {
        // Load template from versioned directory
        return await loadTemplateInfo(versionedPath);
      }

      // Fallback: check if requested version matches current template version
      final template = await loadTemplateInfo(basePath);
      if (template != null && template.version == version) {
        return template;
      }
    } catch (e) {
      logger.warn(
        'Error loading template version $sanitizedName@$version: $e',
      );
    }

    return null;
  }

  /// Get the latest version of a template
  /// 
  /// Returns the highest semantic version. Versions are already sorted
  /// semantically in getVersions() (latest first).
  Future<String?> getLatestVersion(String templateName) async {
    final versions = await getVersions(templateName);
    if (versions.isEmpty) return null;

    // Versions are already sorted semantically (latest first)
    return versions.first;
  }

  /// Get versions within a specified range
  /// 
  /// Returns all versions that satisfy the given version constraint.
  Future<List<String>> getVersionsInRange(
    String templateName,
    String versionConstraint,
  ) async {
    try {
      final constraint = VersionConstraint.parse(versionConstraint);
      final versions = await getVersions(templateName);
      
      return versions.where((versionStr) {
        final version = TemplateVersion.tryParse(versionStr);
        if (version == null) return false;
        return constraint.allows(version.version);
      }).toList();
    } catch (e) {
      logger.warn(
        'Invalid version constraint "$versionConstraint" for $templateName: $e',
      );
      return [];
    }
  }

  /// Get the next version after the specified version
  Future<String?> getNextVersion(String templateName, String currentVersion) async {
    final versions = await getVersions(templateName);
    if (versions.isEmpty) return null;

    final current = TemplateVersion.tryParse(currentVersion);
    if (current == null) return null;

    // Versions are sorted latest first, so find first version greater than current
    for (final versionStr in versions) {
      final version = TemplateVersion.tryParse(versionStr);
      if (version != null && version.isGreaterThan(current)) {
        return versionStr;
      }
    }

    return null;
  }

  /// Get the previous version before the specified version
  Future<String?> getPreviousVersion(String templateName, String currentVersion) async {
    final versions = await getVersions(templateName);
    if (versions.isEmpty) return null;

    final current = TemplateVersion.tryParse(currentVersion);
    if (current == null) return null;

    // Versions are sorted latest first, so find first version less than current
    for (final versionStr in versions) {
      final version = TemplateVersion.tryParse(versionStr);
      if (version != null && version.isLessThan(current)) {
        return versionStr;
      }
    }

    return null;
  }

  /// Check if a specific version exists
  Future<bool> versionExists(String templateName, String version) async {
    final versions = await getVersions(templateName);
    return versions.contains(version);
  }

  /// Clear version cache
  void clearCache() {
    _versionsCache.clear();
  }

  /// Clear cache for a specific template
  void clearCacheForTemplate(String templateName) {
    final sanitizedName = _sanitizeTemplateName(templateName);
    _versionsCache.remove(sanitizedName);
  }
}

/// Internal cache entry with timestamp
class _CachedVersions {
  _CachedVersions({
    required this.versions,
    required this.cachedAt,
  });

  final List<String> versions;
  final int cachedAt;

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - cachedAt) > VersionRegistry.cacheExpirationMs;
  }
}

