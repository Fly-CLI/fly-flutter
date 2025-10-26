import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

import 'package:fly_cli/src/features/context/domain/models/models.dart';

/// Analyzes project dependencies from pubspec.yaml
class DependencyAnalyzer {
  const DependencyAnalyzer();

  /// Analyze dependencies from pubspec.yaml
  Future<DependencyInfo> analyzeDependencies(File pubspecFile) async {
    try {
      final content = await pubspecFile.readAsString();
      final pubspec = Pubspec.parse(content);

      final dependencies = _extractDependencies(pubspec.dependencies);
      final devDependencies = _extractDependencies(pubspec.devDependencies);
      
      final categories = categorizeDependencies(dependencies);
      final flyPackages = detectFlyPackages(dependencies);
      final warnings = checkForWarnings(dependencies, devDependencies);
      final conflicts = checkForConflicts(dependencies);

      return DependencyInfo(
        dependencies: dependencies,
        devDependencies: devDependencies,
        categories: categories,
        flyPackages: flyPackages,
        warnings: warnings,
        conflicts: conflicts,
      );
    } catch (e) {
      throw Exception('Failed to analyze dependencies: $e');
    }
  }

  /// Categorize dependencies by type
  Map<String, List<String>> categorizeDependencies(Map<String, String> dependencies) {
    final categories = <String, List<String>>{
      'state_management': [],
      'networking': [],
      'ui': [],
      'utilities': [],
      'testing': [],
      'development': [],
      'platform': [],
      'other': [],
    };

    for (final entry in dependencies.entries) {
      final package = entry.key;
      final category = _categorizePackage(package);
      categories[category]!.add(package);
    }

    // Remove empty categories
    categories.removeWhere((key, value) => value.isEmpty);
    return categories;
  }

  /// Detect Fly packages
  List<String> detectFlyPackages(Map<String, String> dependencies) {
    final flyPackages = <String>[];
    
    for (final package in dependencies.keys) {
      if (package.startsWith('fly_')) {
        flyPackages.add(package);
      }
    }

    return flyPackages;
  }

  /// Check for dependency warnings
  List<DependencyWarning> checkForWarnings(
    Map<String, String> dependencies,
    Map<String, String> devDependencies,
  ) {
    final warnings = <DependencyWarning>[];

    // Skip warnings if no dependencies
    if (dependencies.isEmpty && devDependencies.isEmpty) {
      return warnings;
    }

    // Check for outdated packages
    for (final entry in dependencies.entries) {
      final package = entry.key;
      final version = entry.value;

      // Check for version constraints that might be too restrictive
      if (version.startsWith('^') && _isOldVersion(version)) {
        warnings.add(DependencyWarning(
          package: package,
          message: 'Consider updating to a newer version',
          severity: 'low',
        ));
      }

      // Check for known problematic packages
      if (_isProblematicPackage(package)) {
        warnings.add(DependencyWarning(
          package: package,
          message: 'Known issues with this package version',
          severity: 'medium',
        ));
      }
    }

    // Check for missing dev dependencies
    if (!devDependencies.containsKey('flutter_test')) {
      warnings.add(const DependencyWarning(
        package: 'flutter_test',
        message: 'Missing flutter_test dependency for testing',
        severity: 'high',
      ));
    }

    return warnings;
  }

  /// Check for version conflicts
  List<String> checkForConflicts(Map<String, String> dependencies) {
    final conflicts = <String>[];

    // Check for conflicting state management packages
    final stateManagementPackages = [
      'flutter_riverpod',
      'flutter_bloc',
      'provider',
      'get',
    ];

    final foundStatePackages = stateManagementPackages
        .where((pkg) => dependencies.containsKey(pkg))
        .toList();

    if (foundStatePackages.length > 1) {
      conflicts.add('Multiple state management packages detected: ${foundStatePackages.join(', ')}');
    }

    // Check for conflicting HTTP clients
    final httpClients = [
      'dio',
      'http',
      'chopper',
    ];

    final foundHttpClients = httpClients
        .where((pkg) => dependencies.containsKey(pkg))
        .toList();

    if (foundHttpClients.length > 1) {
      conflicts.add('Multiple HTTP client packages detected: ${foundHttpClients.join(', ')}');
    }

    return conflicts;
  }

  /// Categorize a package by its purpose
  String _categorizePackage(String package) {
    // State management
    if (_isStateManagementPackage(package)) {
      return 'state_management';
    }

    // Networking
    if (_isNetworkingPackage(package)) {
      return 'networking';
    }

    // UI packages
    if (_isUIPackage(package)) {
      return 'ui';
    }

    // Testing packages
    if (_isTestingPackage(package)) {
      return 'testing';
    }

    // Development tools
    if (_isDevelopmentPackage(package)) {
      return 'development';
    }

    // Platform-specific
    if (_isPlatformPackage(package)) {
      return 'platform';
    }

    return 'other';
  }

  /// Check if package is for state management
  bool _isStateManagementPackage(String package) {
    const stateManagementPackages = {
      'flutter_riverpod',
      'riverpod',
      'flutter_bloc',
      'bloc',
      'provider',
      'get',
      'mobx',
      'flutter_mobx',
      'flutter_redux',
      'redux',
      'fish_redux',
      'flutter_hooks',
      'hooks_riverpod',
    };

    return stateManagementPackages.contains(package);
  }

  /// Check if package is for networking
  bool _isNetworkingPackage(String package) {
    const networkingPackages = {
      'dio',
      'http',
      'chopper',
      'retrofit',
      'graphql',
      'web_socket_channel',
      'connectivity_plus',
      'internet_connection_checker',
    };

    return networkingPackages.contains(package) || package.startsWith('fly_networking');
  }

  /// Check if package is for UI
  bool _isUIPackage(String package) {
    const uiPackages = {
      'flutter_screenutil',
      'responsive_framework',
      'flutter_staggered_grid_view',
      'flutter_slidable',
      'flutter_spinkit',
      'lottie',
      'shimmer',
      'cached_network_image',
      'photo_view',
      'image_picker',
      'file_picker',
    };

    return uiPackages.contains(package);
  }

  /// Check if package is for testing
  bool _isTestingPackage(String package) {
    const testingPackages = {
      'flutter_test',
      'mockito',
      'mocktail',
      'integration_test',
      'patrol',
      'golden_toolkit',
    };

    return testingPackages.contains(package);
  }

  /// Check if package is for development
  bool _isDevelopmentPackage(String package) {
    const developmentPackages = {
      'build_runner',
      'json_annotation',
      'json_serializable',
      'freezed',
      'freezed_annotation',
      'injectable',
      'auto_route',
      'go_router',
      'flutter_gen',
      'flutter_launcher_icons',
      'flutter_native_splash',
    };

    return developmentPackages.contains(package);
  }

  /// Check if package is platform-specific
  bool _isPlatformPackage(String package) {
    const platformPackages = {
      'permission_handler',
      'device_info_plus',
      'package_info_plus',
      'url_launcher',
      'share_plus',
      'path_provider',
      'shared_preferences',
      'sqflite',
      'hive',
      'isar',
    };

    return platformPackages.contains(package);
  }

  /// Check if version is old
  bool _isOldVersion(String version) {
    // Simple heuristic: versions starting with ^1.0 or ^0. are considered old
    return version.contains('^1.') || version.contains('^0.');
  }

  /// Check if package is known to have issues
  bool _isProblematicPackage(String package) {
    const problematicPackages = {
      'flutter_webview_plugin', // Deprecated
      'webview_flutter', // Old version
    };

    return problematicPackages.contains(package);
  }

  /// Extract dependencies as string map
  Map<String, String> _extractDependencies(Map<String, Dependency> dependencies) {
    return dependencies.map((key, value) => MapEntry(key, value.toString()));
  }
}
