import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../domain/models/models.dart';

/// Enhanced dependency analyzer with pub.dev API integration
class DependencyHealthAnalyzer {
  const DependencyHealthAnalyzer();

  /// Analyze dependency health for a project
  Future<List<DependencyHealth>> analyzeDependencyHealth(Directory projectDir) async {
    final healthReports = <DependencyHealth>[];
    
    try {
      final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
      if (!await pubspecFile.exists()) return healthReports;
      
      final content = await pubspecFile.readAsString();
      final dependencies = _extractDependencies(content);
      
      // Analyze each dependency
      for (final dependency in dependencies) {
        try {
          final health = await _analyzeDependency(dependency);
          healthReports.add(health);
        } catch (e) {
          // Skip dependencies that can't be analyzed
          continue;
        }
      }
      
    } catch (e) {
      // Return empty list if analysis fails
    }
    
    return healthReports;
  }

  /// Extract dependencies from pubspec.yaml content
  List<String> _extractDependencies(String content) {
    final dependencies = <String>[];
    final lines = content.split('\n');
    bool inDependencies = false;
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      if (trimmed == 'dependencies:') {
        inDependencies = true;
        continue;
      }
      
      if (inDependencies) {
        if (trimmed.isEmpty || trimmed.startsWith('dev_dependencies:')) {
          break;
        }
        
        if (trimmed.contains(':')) {
          final parts = trimmed.split(':');
          if (parts.length >= 2) {
            final packageName = parts[0].trim();
            if (packageName.isNotEmpty && !packageName.startsWith('#')) {
              dependencies.add(packageName);
            }
          }
        }
      }
    }
    
    return dependencies;
  }

  /// Analyze a single dependency using pub.dev API
  Future<DependencyHealth> _analyzeDependency(String packageName) async {
    try {
      // Skip Flutter SDK dependencies
      if (packageName.startsWith('flutter') || packageName.startsWith('dart:')) {
        return DependencyHealth(
          package: packageName,
          healthScore: 100.0,
          vulnerabilities: [],
          license: 'BSD-3-Clause',
          isMaintained: true,
          popularity: 100,
        );
      }
      
      // Fetch package info from pub.dev API
      final response = await http.get(
        Uri.parse('https://pub.dev/api/packages/$packageName'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return _parsePackageData(packageName, data);
      } else {
        // Return default health for packages that can't be fetched
        return DependencyHealth(
          package: packageName,
          healthScore: 50.0,
          vulnerabilities: [],
          license: 'Unknown',
          isMaintained: false,
          popularity: 0,
        );
      }
    } catch (e) {
      // Return default health if API call fails
      return DependencyHealth(
        package: packageName,
        healthScore: 50.0,
        vulnerabilities: [],
        license: 'Unknown',
        isMaintained: false,
        popularity: 0,
      );
    }
  }

  /// Parse package data from pub.dev API response
  DependencyHealth _parsePackageData(String packageName, Map<String, dynamic> data) {
    // Extract health score
    final healthScore = _calculateHealthScore(data);
    
    // Extract vulnerabilities
    final vulnerabilities = _extractVulnerabilities(data);
    
    // Extract license
    final license = _extractLicense(data);
    
    // Check if package is maintained
    final isMaintained = _isMaintained(data);
    
    // Extract popularity score
    final popularity = _extractPopularity(data);
    
    return DependencyHealth(
      package: packageName,
      healthScore: healthScore,
      vulnerabilities: vulnerabilities,
      license: license,
      isMaintained: isMaintained,
      popularity: popularity,
    );
  }

  /// Calculate health score based on package data
  double _calculateHealthScore(Map<String, dynamic> data) {
    double score = 100.0;
    
    // Check for maintenance status
    if (!_isMaintained(data)) {
      score -= 30.0;
    }
    
    // Check for recent updates
    final updated = data['updated'] as String?;
    if (updated != null) {
      final updateDate = DateTime.tryParse(updated);
      if (updateDate != null) {
        final daysSinceUpdate = DateTime.now().difference(updateDate).inDays;
        if (daysSinceUpdate > 365) {
          score -= 20.0;
        } else if (daysSinceUpdate > 180) {
          score -= 10.0;
        }
      }
    }
    
    // Check for popularity
    final popularity = _extractPopularity(data);
    if (popularity < 10) {
      score -= 15.0;
    } else if (popularity < 50) {
      score -= 5.0;
    }
    
    // Check for documentation
    final hasDocumentation = data['documentation'] != null;
    if (!hasDocumentation) {
      score -= 10.0;
    }
    
    // Check for example
    final hasExample = data['example'] != null;
    if (!hasExample) {
      score -= 5.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  /// Extract vulnerabilities from package data
  List<String> _extractVulnerabilities(Map<String, dynamic> data) {
    final vulnerabilities = <String>[];
    
    // Check for known security issues
    final securityAdvisories = data['security_advisories'] as List?;
    if (securityAdvisories != null) {
      for (final advisory in securityAdvisories) {
        if (advisory is Map<String, dynamic>) {
          final summary = advisory['summary'] as String?;
          if (summary != null) {
            vulnerabilities.add(summary);
          }
        }
      }
    }
    
    return vulnerabilities;
  }

  /// Extract license from package data
  String _extractLicense(Map<String, dynamic> data) {
    final license = data['license'] as String?;
    return license ?? 'Unknown';
  }

  /// Check if package is maintained
  bool _isMaintained(Map<String, dynamic> data) {
    final updated = data['updated'] as String?;
    if (updated != null) {
      final updateDate = DateTime.tryParse(updated);
      if (updateDate != null) {
        final daysSinceUpdate = DateTime.now().difference(updateDate).inDays;
        return daysSinceUpdate < 365; // Consider maintained if updated within a year
      }
    }
    
    return false;
  }

  /// Extract popularity score from package data
  int _extractPopularity(Map<String, dynamic> data) {
    final popularity = data['popularity'] as double?;
    if (popularity != null) {
      return (popularity * 100).round();
    }
    
    // Fallback to likes count
    final likes = data['likes'] as int?;
    if (likes != null) {
      return likes;
    }
    
    return 0;
  }
}
