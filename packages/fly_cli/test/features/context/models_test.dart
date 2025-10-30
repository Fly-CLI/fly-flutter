import 'package:test/test.dart';

import 'package:fly_cli/src/features/context/domain/models/models.dart';

void main() {
  group('Analysis Models', () {
    group('ContextGeneratorConfig', () {
      test('should have correct default values', () {
        const config = ContextGeneratorConfig();

        expect(config.includeCode, isFalse);
        expect(config.includeDependencies, isFalse);
        expect(config.maxFileSize, equals(10000));
        expect(config.maxFiles, equals(50));
        expect(config.includeArchitecture, isTrue);
        expect(config.includeSuggestions, isTrue);
      });

      test('should create copy with modified fields', () {
        const original = ContextGeneratorConfig();
        final modified = original.copyWith(
          includeCode: true,
          maxFileSize: 5000,
        );

        expect(modified.includeCode, isTrue);
        expect(modified.includeDependencies, isFalse); // Unchanged
        expect(modified.maxFileSize, equals(5000));
        expect(modified.maxFiles, equals(50)); // Unchanged
        expect(modified.includeArchitecture, isTrue); // Unchanged
        expect(modified.includeSuggestions, isTrue); // Unchanged
      });

      test('should handle null values in copyWith', () {
        const original = ContextGeneratorConfig(
          includeCode: true,
          maxFileSize: 5000,
        );
        final modified = original.copyWith(
          includeCode: null,
          maxFiles: 25,
        );

        expect(modified.includeCode, isTrue); // Unchanged
        expect(modified.maxFileSize, equals(5000)); // Unchanged
        expect(modified.maxFiles, equals(25)); // Changed
      });
    });

    group('ProjectInfo', () {
      test('should create with required fields', () {
        const projectInfo = ProjectInfo(
          name: 'test_project',
          type: 'flutter',
          version: '1.0.0+1',
        );

        expect(projectInfo.name, equals('test_project'));
        expect(projectInfo.type, equals('flutter'));
        expect(projectInfo.version, equals('1.0.0+1'));
        expect(projectInfo.platforms, equals(['ios', 'android']));
        expect(projectInfo.isFlyProject, isFalse);
        expect(projectInfo.hasManifest, isFalse);
      });

      test('should create Fly project', () {
        const projectInfo = ProjectInfo(
          name: 'fly_project',
          type: 'flutter',
          version: '1.0.0+1',
          template: 'riverpod',
          organization: 'test_org',
          isFlyProject: true,
          hasManifest: true,
        );

        expect(projectInfo.name, equals('fly_project'));
        expect(projectInfo.type, equals('flutter'));
        expect(projectInfo.template, equals('riverpod'));
        expect(projectInfo.organization, equals('test_org'));
        expect(projectInfo.isFlyProject, isTrue);
        expect(projectInfo.hasManifest, isTrue);
      });

      test('should serialize to JSON correctly', () {
        const projectInfo = ProjectInfo(
          name: 'test_project',
          type: 'flutter',
          version: '1.0.0+1',
          description: 'A test project',
          flutterVersion: '>=3.0.0',
          dartVersion: '>=3.0.0',
          isFlyProject: false,
          hasManifest: false,
        );

        final json = projectInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['name'], equals('test_project'));
        expect(json['type'], equals('flutter'));
        expect(json['version'], equals('1.0.0+1'));
        expect(json['description'], equals('A test project'));
        expect(json['flutter_version'], equals('>=3.0.0'));
        expect(json['dart_version'], equals('>=3.0.0'));
        expect(json['is_fly_project'], isFalse);
        expect(json['has_manifest'], isFalse);
        expect(json['platforms'], equals(['ios', 'android']));
      });

      test('should exclude null fields from JSON', () {
        const projectInfo = ProjectInfo(
          name: 'test_project',
          type: 'flutter',
          version: '1.0.0+1',
        );

        final json = projectInfo.toJson();

        expect(json.containsKey('template'), isFalse);
        expect(json.containsKey('organization'), isFalse);
        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('flutter_version'), isFalse);
        expect(json.containsKey('dart_version'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
      });

      test('should include creation date when provided', () {
        final creationDate = DateTime(2024, 1, 1);
        final projectInfo = ProjectInfo(
          name: 'test_project',
          type: 'flutter',
          version: '1.0.0+1',
          creationDate: creationDate,
        );

        final json = projectInfo.toJson();

        expect(json.containsKey('created_at'), isTrue);
        expect(json['created_at'], equals(creationDate.toIso8601String()));
      });
    });

    group('StructureInfo', () {
      test('should create with required fields', () {
        final directories = <String, DirectoryInfo>{
          'lib': const DirectoryInfo(files: 10, dartFiles: 8),
          'test': const DirectoryInfo(files: 5, dartFiles: 5),
        };
        final fileTypes = <String, int>{
          '.dart': 13,
          '.yaml': 1,
        };

        final structureInfo = StructureInfo(
          rootDirectory: '/test/project',
          directories: directories,
          features: ['home', 'profile'],
          totalFiles: 15,
          linesOfCode: 1000,
          fileTypes: fileTypes,
          architecturePattern: 'riverpod',
          conventions: ['feature-first', 'test-driven'],
        );

        expect(structureInfo.rootDirectory, equals('/test/project'));
        expect(structureInfo.directories.length, equals(2));
        expect(structureInfo.features, equals(['home', 'profile']));
        expect(structureInfo.totalFiles, equals(15));
        expect(structureInfo.linesOfCode, equals(1000));
        expect(structureInfo.fileTypes.length, equals(2));
        expect(structureInfo.architecturePattern, equals('riverpod'));
        expect(structureInfo.conventions, equals(['feature-first', 'test-driven']));
      });

      test('should serialize to JSON correctly', () {
        final directories = <String, DirectoryInfo>{
          'lib': const DirectoryInfo(files: 10, dartFiles: 8),
        };
        final fileTypes = <String, int>{
          '.dart': 8,
        };

        final structureInfo = StructureInfo(
          rootDirectory: '/test/project',
          directories: directories,
          features: ['home'],
          totalFiles: 10,
          linesOfCode: 500,
          fileTypes: fileTypes,
          architecturePattern: 'riverpod',
          conventions: ['feature-first'],
        );

        final json = structureInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['root_directory'], equals('/test/project'));
        expect(json['directories'], isA<Map<String, dynamic>>());
        expect(json['features'], equals(['home']));
        expect(json['total_files'], equals(10));
        expect(json['lines_of_code'], equals(500));
        expect(json['file_types'], equals({'.dart': 8}));
        expect(json['architecture_pattern'], equals('riverpod'));
        expect(json['conventions'], equals(['feature-first']));
      });

      test('should exclude null architecture pattern from JSON', () {
        final directories = <String, DirectoryInfo>{
          'lib': const DirectoryInfo(files: 10, dartFiles: 8),
        };
        final fileTypes = <String, int>{
          '.dart': 8,
        };

        final structureInfo = StructureInfo(
          rootDirectory: '/test/project',
          directories: directories,
          features: ['home'],
          totalFiles: 10,
          linesOfCode: 500,
          fileTypes: fileTypes,
        );

        final json = structureInfo.toJson();

        expect(json.containsKey('architecture_pattern'), isFalse);
      });
    });

    group('DirectoryInfo', () {
      test('should create with required fields', () {
        const directoryInfo = DirectoryInfo(
          files: 10,
          dartFiles: 8,
          subdirectories: ['features', 'core'],
        );

        expect(directoryInfo.files, equals(10));
        expect(directoryInfo.dartFiles, equals(8));
        expect(directoryInfo.subdirectories, equals(['features', 'core']));
      });

      test('should have empty subdirectories by default', () {
        const directoryInfo = DirectoryInfo(
          files: 10,
          dartFiles: 8,
        );

        expect(directoryInfo.subdirectories, isEmpty);
      });

      test('should serialize to JSON correctly', () {
        const directoryInfo = DirectoryInfo(
          files: 10,
          dartFiles: 8,
          subdirectories: ['features', 'core'],
        );

        final json = directoryInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['files'], equals(10));
        expect(json['dart_files'], equals(8));
        expect(json['subdirectories'], equals(['features', 'core']));
      });
    });

    group('DependencyInfo', () {
      test('should create with required fields', () {
        final dependencies = <String, String>{
          'flutter': '^1.0.0',
          'flutter_riverpod': '^2.4.0',
        };
        final devDependencies = <String, String>{
          'flutter_test': '^1.0.0',
        };
        final categories = <String, List<String>>{
          'state_management': ['flutter_riverpod'],
        };
        final flyPackages = <String>['fly_core'];
        final warnings = <DependencyWarning>[
          const DependencyWarning(
            package: 'test_package',
            message: 'Test warning',
            severity: 'medium',
          ),
        ];
        final conflicts = <String>['Test conflict'];

        final dependencyInfo = DependencyInfo(
          dependencies: dependencies,
          devDependencies: devDependencies,
          categories: categories,
          flyPackages: flyPackages,
          warnings: warnings,
          conflicts: conflicts,
        );

        expect(dependencyInfo.dependencies, equals(dependencies));
        expect(dependencyInfo.devDependencies, equals(devDependencies));
        expect(dependencyInfo.categories, equals(categories));
        expect(dependencyInfo.flyPackages, equals(flyPackages));
        expect(dependencyInfo.warnings, equals(warnings));
        expect(dependencyInfo.conflicts, equals(conflicts));
      });

      test('should have empty warnings and conflicts by default', () {
        final dependencies = <String, String>{
          'flutter': '^1.0.0',
        };
        final devDependencies = <String, String>{};
        final categories = <String, List<String>>{};
        final flyPackages = <String>[];

        final dependencyInfo = DependencyInfo(
          dependencies: dependencies,
          devDependencies: devDependencies,
          categories: categories,
          flyPackages: flyPackages,
        );

        expect(dependencyInfo.warnings, isEmpty);
        expect(dependencyInfo.conflicts, isEmpty);
      });

      test('should serialize to JSON correctly', () {
        final dependencies = <String, String>{
          'flutter': '^1.0.0',
        };
        final devDependencies = <String, String>{
          'flutter_test': '^1.0.0',
        };
        final categories = <String, List<String>>{};
        final flyPackages = <String>[];
        final warnings = <DependencyWarning>[
          const DependencyWarning(
            package: 'test_package',
            message: 'Test warning',
            severity: 'medium',
          ),
        ];
        final conflicts = <String>['Test conflict'];

        final dependencyInfo = DependencyInfo(
          dependencies: dependencies,
          devDependencies: devDependencies,
          categories: categories,
          flyPackages: flyPackages,
          warnings: warnings,
          conflicts: conflicts,
        );

        final json = dependencyInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['dependencies'], equals(dependencies));
        expect(json['dev_dependencies'], equals(devDependencies));
        expect(json['categories'], equals(categories));
        expect(json['fly_packages'], equals(flyPackages));
        expect(json['warnings'], isA<List<dynamic>>());
        expect(json['conflicts'], equals(conflicts));
      });
    });

    group('DependencyWarning', () {
      test('should create with required fields', () {
        const warning = DependencyWarning(
          package: 'test_package',
          message: 'Test warning message',
          severity: 'high',
        );

        expect(warning.package, equals('test_package'));
        expect(warning.message, equals('Test warning message'));
        expect(warning.severity, equals('high'));
      });

      test('should serialize to JSON correctly', () {
        const warning = DependencyWarning(
          package: 'test_package',
          message: 'Test warning message',
          severity: 'high',
        );

        final json = warning.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['package'], equals('test_package'));
        expect(json['message'], equals('Test warning message'));
        expect(json['severity'], equals('high'));
      });
    });

    group('CodeInfo', () {
      test('should create with required fields', () {
        final keyFiles = <SourceFile>[
          const SourceFile(
            path: 'main.dart',
            name: 'main.dart',
            type: 'main',
            linesOfCode: 50,
            importance: 'high',
            description: 'Application entry point',
          ),
        ];
        final fileContents = <String, String>{
          'main.dart': 'import \'package:flutter/material.dart\';',
        };
        final metrics = <String, int>{
          'total_dart_files': 1,
          'total_lines_of_code': 50,
        };
        final imports = <String, List<String>>{
          'main.dart': ['package:flutter/material.dart'],
        };
        final patterns = <String>['material_design'];

        final codeInfo = CodeInfo(
          keyFiles: keyFiles,
          fileContents: fileContents,
          metrics: metrics,
          imports: imports,
          patterns: patterns,
        );

        expect(codeInfo.keyFiles, equals(keyFiles));
        expect(codeInfo.fileContents, equals(fileContents));
        expect(codeInfo.metrics, equals(metrics));
        expect(codeInfo.imports, equals(imports));
        expect(codeInfo.patterns, equals(patterns));
      });

      test('should serialize to JSON correctly', () {
        final keyFiles = <SourceFile>[
          const SourceFile(
            path: 'main.dart',
            name: 'main.dart',
            type: 'main',
            linesOfCode: 50,
            importance: 'high',
            description: 'Application entry point',
          ),
        ];
        final fileContents = <String, String>{
          'main.dart': 'import \'package:flutter/material.dart\';',
        };
        final metrics = <String, int>{
          'total_dart_files': 1,
          'total_lines_of_code': 50,
        };
        final imports = <String, List<String>>{
          'main.dart': ['package:flutter/material.dart'],
        };
        final patterns = <String>['material_design'];

        final codeInfo = CodeInfo(
          keyFiles: keyFiles,
          fileContents: fileContents,
          metrics: metrics,
          imports: imports,
          patterns: patterns,
        );

        final json = codeInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['key_files'], isA<List<dynamic>>());
        expect(json['file_contents'], equals(fileContents));
        expect(json['metrics'], equals(metrics));
        expect(json['imports'], equals(imports));
        expect(json['patterns'], equals(patterns));
      });
    });

    group('SourceFile', () {
      test('should create with required fields', () {
        const sourceFile = SourceFile(
          path: 'main.dart',
          name: 'main.dart',
          type: 'main',
          linesOfCode: 50,
          importance: 'high',
          description: 'Application entry point',
        );

        expect(sourceFile.path, equals('main.dart'));
        expect(sourceFile.name, equals('main.dart'));
        expect(sourceFile.type, equals('main'));
        expect(sourceFile.linesOfCode, equals(50));
        expect(sourceFile.importance, equals('high'));
        expect(sourceFile.description, equals('Application entry point'));
      });

      test('should have medium importance by default', () {
        const sourceFile = SourceFile(
          path: 'test.dart',
          name: 'test.dart',
          type: 'other',
          linesOfCode: 10,
        );

        expect(sourceFile.importance, equals('medium'));
        expect(sourceFile.description, isNull);
      });

      test('should serialize to JSON correctly', () {
        const sourceFile = SourceFile(
          path: 'main.dart',
          name: 'main.dart',
          type: 'main',
          linesOfCode: 50,
          importance: 'high',
          description: 'Application entry point',
        );

        final json = sourceFile.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['path'], equals('main.dart'));
        expect(json['name'], equals('main.dart'));
        expect(json['type'], equals('main'));
        expect(json['lines_of_code'], equals(50));
        expect(json['importance'], equals('high'));
        expect(json['description'], equals('Application entry point'));
      });

      test('should exclude null description from JSON', () {
        const sourceFile = SourceFile(
          path: 'test.dart',
          name: 'test.dart',
          type: 'other',
          linesOfCode: 10,
        );

        final json = sourceFile.toJson();

        expect(json.containsKey('description'), isFalse);
      });
    });

    group('ArchitectureInfo', () {
      test('should create with required fields', () {
        const architectureInfo = ArchitectureInfo(
          pattern: 'riverpod',
          conventions: ['feature-first'],
          stateManagement: 'riverpod',
          routing: 'go_router',
          dependencyInjection: 'riverpod',
          frameworks: ['flutter_riverpod', 'go_router'],
        );

        expect(architectureInfo.pattern, equals('riverpod'));
        expect(architectureInfo.conventions, equals(['feature-first']));
        expect(architectureInfo.stateManagement, equals('riverpod'));
        expect(architectureInfo.routing, equals('go_router'));
        expect(architectureInfo.dependencyInjection, equals('riverpod'));
        expect(architectureInfo.frameworks, equals(['flutter_riverpod', 'go_router']));
      });

      test('should have empty frameworks by default', () {
        const architectureInfo = ArchitectureInfo(
          pattern: 'riverpod',
          conventions: ['feature-first'],
          stateManagement: 'riverpod',
          routing: 'go_router',
          dependencyInjection: 'riverpod',
        );

        expect(architectureInfo.frameworks, isEmpty);
      });

      test('should serialize to JSON correctly', () {
        const architectureInfo = ArchitectureInfo(
          pattern: 'riverpod',
          conventions: ['feature-first'],
          stateManagement: 'riverpod',
          routing: 'go_router',
          dependencyInjection: 'riverpod',
          frameworks: ['flutter_riverpod'],
        );

        final json = architectureInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['pattern'], equals('riverpod'));
        expect(json['conventions'], equals(['feature-first']));
        expect(json['state_management'], equals('riverpod'));
        expect(json['routing'], equals('go_router'));
        expect(json['dependency_injection'], equals('riverpod'));
        expect(json['frameworks'], equals(['flutter_riverpod']));
      });
    });

    group('ManifestInfo', () {
      test('should create with required fields', () {
        final screens = <ManifestScreen>[
          const ManifestScreen(
            name: 'home',
            type: 'screen',
            features: ['navigation'],
          ),
        ];
        final services = <ManifestService>[
          const ManifestService(
            name: 'api',
            type: 'rest',
            apiBase: 'https://api.example.com',
            features: ['authentication'],
          ),
        ];
        final packages = <String>['dio', 'flutter_riverpod'];

        final manifestInfo = ManifestInfo(
          name: 'test_project',
          template: 'riverpod',
          organization: 'test_org',
          description: 'A test project',
          platforms: ['ios', 'android', 'web'],
          screens: screens,
          services: services,
          packages: packages,
        );

        expect(manifestInfo.name, equals('test_project'));
        expect(manifestInfo.template, equals('riverpod'));
        expect(manifestInfo.organization, equals('test_org'));
        expect(manifestInfo.description, equals('A test project'));
        expect(manifestInfo.platforms, equals(['ios', 'android', 'web']));
        expect(manifestInfo.screens, equals(screens));
        expect(manifestInfo.services, equals(services));
        expect(manifestInfo.packages, equals(packages));
      });

      test('should have default platforms and empty collections', () {
        const manifestInfo = ManifestInfo(
          name: 'test_project',
          template: 'riverpod',
          organization: 'test_org',
        );

        expect(manifestInfo.platforms, equals(['ios', 'android']));
        expect(manifestInfo.screens, isEmpty);
        expect(manifestInfo.services, isEmpty);
        expect(manifestInfo.packages, isEmpty);
        expect(manifestInfo.description, isNull);
      });

      test('should serialize to JSON correctly', () {
        final screens = <ManifestScreen>[
          const ManifestScreen(
            name: 'home',
            type: 'screen',
            features: ['navigation'],
          ),
        ];
        final services = <ManifestService>[
          const ManifestService(
            name: 'api',
            type: 'rest',
            apiBase: 'https://api.example.com',
            features: ['authentication'],
          ),
        ];
        final packages = <String>['dio'];

        final manifestInfo = ManifestInfo(
          name: 'test_project',
          template: 'riverpod',
          organization: 'test_org',
          description: 'A test project',
          platforms: ['ios', 'android'],
          screens: screens,
          services: services,
          packages: packages,
        );

        final json = manifestInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['name'], equals('test_project'));
        expect(json['template'], equals('riverpod'));
        expect(json['organization'], equals('test_org'));
        expect(json['description'], equals('A test project'));
        expect(json['platforms'], equals(['ios', 'android']));
        expect(json['screens'], isA<List<dynamic>>());
        expect(json['services'], isA<List<dynamic>>());
        expect(json['packages'], equals(packages));
      });

      test('should exclude null description from JSON', () {
        const manifestInfo = ManifestInfo(
          name: 'test_project',
          template: 'riverpod',
          organization: 'test_org',
        );

        final json = manifestInfo.toJson();

        expect(json.containsKey('description'), isFalse);
      });
    });

    group('ManifestScreen', () {
      test('should create with required fields', () {
        const screen = ManifestScreen(
          name: 'home',
          type: 'screen',
          features: ['navigation', 'user_data'],
        );

        expect(screen.name, equals('home'));
        expect(screen.type, equals('screen'));
        expect(screen.features, equals(['navigation', 'user_data']));
      });

      test('should have empty features by default', () {
        const screen = ManifestScreen(name: 'home');

        expect(screen.features, isEmpty);
        expect(screen.type, isNull);
      });

      test('should serialize to JSON correctly', () {
        const screen = ManifestScreen(
          name: 'home',
          type: 'screen',
          features: ['navigation'],
        );

        final json = screen.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['name'], equals('home'));
        expect(json['type'], equals('screen'));
        expect(json['features'], equals(['navigation']));
      });

      test('should exclude null type from JSON', () {
        const screen = ManifestScreen(name: 'home');

        final json = screen.toJson();

        expect(json.containsKey('type'), isFalse);
      });
    });

    group('ManifestService', () {
      test('should create with required fields', () {
        const service = ManifestService(
          name: 'api',
          type: 'rest',
          apiBase: 'https://api.example.com',
          features: ['authentication', 'data_fetching'],
        );

        expect(service.name, equals('api'));
        expect(service.type, equals('rest'));
        expect(service.apiBase, equals('https://api.example.com'));
        expect(service.features, equals(['authentication', 'data_fetching']));
      });

      test('should have empty features by default', () {
        const service = ManifestService(name: 'api');

        expect(service.features, isEmpty);
        expect(service.type, isNull);
        expect(service.apiBase, isNull);
      });

      test('should serialize to JSON correctly', () {
        const service = ManifestService(
          name: 'api',
          type: 'rest',
          apiBase: 'https://api.example.com',
          features: ['authentication'],
        );

        final json = service.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['name'], equals('api'));
        expect(json['type'], equals('rest'));
        expect(json['api_base'], equals('https://api.example.com'));
        expect(json['features'], equals(['authentication']));
      });

      test('should exclude null fields from JSON', () {
        const service = ManifestService(name: 'api');

        final json = service.toJson();

        expect(json.containsKey('type'), isFalse);
        expect(json.containsKey('api_base'), isFalse);
      });
    });

    group('PubspecInfo', () {
      test('should create with required fields', () {
        final dependencies = <String, String>{
          'flutter': '^1.0.0',
        };
        final devDependencies = <String, String>{
          'flutter_test': '^1.0.0',
        };
        final environment = <String, String>{
          'sdk': '>=3.0.0',
        };

        final pubspecInfo = PubspecInfo(
          name: 'test_project',
          version: '1.0.0+1',
          description: 'A test project',
          homepage: 'https://example.com',
          repository: 'https://github.com/test/project',
          environment: environment,
          dependencies: dependencies,
          devDependencies: devDependencies,
        );

        expect(pubspecInfo.name, equals('test_project'));
        expect(pubspecInfo.version, equals('1.0.0+1'));
        expect(pubspecInfo.description, equals('A test project'));
        expect(pubspecInfo.homepage, equals('https://example.com'));
        expect(pubspecInfo.repository, equals('https://github.com/test/project'));
        expect(pubspecInfo.environment, equals(environment));
        expect(pubspecInfo.dependencies, equals(dependencies));
        expect(pubspecInfo.devDependencies, equals(devDependencies));
      });

      test('should have empty collections by default', () {
        final pubspecInfo = PubspecInfo(
          name: 'test_project',
          version: '1.0.0+1',
        );

        expect(pubspecInfo.dependencies, isEmpty);
        expect(pubspecInfo.devDependencies, isEmpty);
        expect(pubspecInfo.description, isNull);
        expect(pubspecInfo.homepage, isNull);
        expect(pubspecInfo.repository, isNull);
        expect(pubspecInfo.environment, isNull);
      });

      test('should serialize to JSON correctly', () {
        final dependencies = <String, String>{
          'flutter': '^1.0.0',
        };
        final devDependencies = <String, String>{
          'flutter_test': '^1.0.0',
        };
        final environment = <String, String>{
          'sdk': '>=3.0.0',
        };

        final pubspecInfo = PubspecInfo(
          name: 'test_project',
          version: '1.0.0+1',
          description: 'A test project',
          homepage: 'https://example.com',
          repository: 'https://github.com/test/project',
          environment: environment,
          dependencies: dependencies,
          devDependencies: devDependencies,
        );

        final json = pubspecInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['name'], equals('test_project'));
        expect(json['version'], equals('1.0.0+1'));
        expect(json['description'], equals('A test project'));
        expect(json['homepage'], equals('https://example.com'));
        expect(json['repository'], equals('https://github.com/test/project'));
        expect(json['environment'], equals(environment));
        expect(json['dependencies'], equals(dependencies));
        expect(json['dev_dependencies'], equals(devDependencies));
      });

      test('should exclude null fields from JSON', () {
        final pubspecInfo = PubspecInfo(
          name: 'test_project',
          version: '1.0.0+1',
        );

        final json = pubspecInfo.toJson();

        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('homepage'), isFalse);
        expect(json.containsKey('repository'), isFalse);
        expect(json.containsKey('environment'), isFalse);
      });
    });
  });
}
