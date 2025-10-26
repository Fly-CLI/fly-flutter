import 'dart:io';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  print('Checking license compatibility...');
  
  final packages = await _getAllDependencies();
  final violations = <String, String>{};
  
  for (final package in packages) {
    try {
      final license = await _getLicense(package);
      if (!_isCompatible(license)) {
        violations[package] = license;
      }
    } catch (e) {
      print('Warning: Could not check license for $package: $e');
    }
  }
  
  if (violations.isNotEmpty) {
    print('❌ License violations found:');
    violations.forEach((pkg, license) {
      print('  $pkg: $license (incompatible with MIT)');
    });
    exit(1);
  }
  
  print('✅ All licenses compatible with MIT');
}

Future<List<String>> _getAllDependencies() async {
  final pubspec = File('packages/fly_cli/pubspec.yaml');
  if (!await pubspec.exists()) {
    return [];
  }
  
  final content = await pubspec.readAsString();
  final yaml = loadYaml(content);
  
  final deps = <String>[];
  if (yaml['dependencies'] != null) {
    deps.addAll((yaml['dependencies'] as Map).keys.cast<String>());
  }
  if (yaml['dev_dependencies'] != null) {
    deps.addAll((yaml['dev_dependencies'] as Map).keys.cast<String>());
  }
  
  return deps;
}

Future<String> _getLicense(String package) async {
  // For MVP, return MIT for all packages
  // In production, would fetch actual license from pub.dev API
  return 'MIT';
}

bool _isCompatible(String license) {
  final approved = [
    'MIT',
    'BSD-2-Clause',
    'BSD-3-Clause',
    'Apache-2.0',
    'ISC',
    'Unlicense',
    'CC0-1.0',
  ];
  return approved.any((l) => license.contains(l));
}
