import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:fly_cli/src/commands/fly_command.dart';

/// Add a service to your project
class AddServiceCommand extends FlyCommand {
  @override
  String get name => 'service';

  @override
  String get description => 'Add a service to your project';

  AddServiceCommand() {
    argParser
      ..addOption(
        'feature',
        help: 'Feature name',
        defaultsTo: 'core',
      )
      ..addOption(
        'type',
        abbr: 't',
        help: 'Service type',
        allowed: ['api', 'local', 'cache'],
        defaultsTo: 'api',
      )
      ..addFlag(
        'with-tests',
        help: 'Include test files',
        defaultsTo: false,
      )
      ..addFlag(
        'with-mocks',
        help: 'Include mock files',
        defaultsTo: false,
      );
  }

  @override
  Future<CommandResult> execute() async {
    final serviceName = argResults?.rest.isNotEmpty == true ? argResults!.rest.first : null;
    final feature = argResults?['feature'] as String? ?? 'core';
    final type = argResults?['type'] as String? ?? 'api';
    final withTests = argResults?['with-tests'] as bool? ?? false;
    final withMocks = argResults?['with-mocks'] as bool? ?? false;
    final output = argResults?['output'] as String? ?? 'human';

    if (serviceName == null || serviceName.isEmpty) {
      return CommandResult.error(
        message: 'Service name is required',
        suggestion: 'Provide a service name: fly add service <service_name>',
      );
    }

    if (!_isValidName(serviceName)) {
      return CommandResult.error(
        message: 'Invalid service name: $serviceName',
        suggestion: 'Service name must contain only lowercase letters, numbers, and underscores',
      );
    }

    try {
      final stopwatch = Stopwatch()..start();
      
      if (output != 'json') {
        logger.info('Adding service: $serviceName');
        logger.info('Feature: $feature');
        logger.info('Type: $type');
        logger.info('With tests: $withTests');
        logger.info('With mocks: $withMocks');
      }

      // Check if we're in a Flutter project
      final pubspecFile = File('pubspec.yaml');
      if (!pubspecFile.existsSync()) {
        return CommandResult.error(
          message: 'Not in a Flutter project directory',
          suggestion: 'Run this command from a Flutter project root directory',
        );
      }

      // Create feature directory structure
      final featureDir = Directory(path.join('lib', 'features', feature));
      if (!featureDir.existsSync()) {
        featureDir.createSync(recursive: true);
      }

      // Create services directory
      final servicesDir = Directory(path.join(featureDir.path, 'services'));
      servicesDir.createSync(recursive: true);

      // Generate service file
      final serviceFile = File(path.join(servicesDir.path, '${serviceName}_service.dart'));
      final serviceContent = _generateServiceContent(serviceName, feature, type);
      await serviceFile.writeAsString(serviceContent);

      int filesGenerated = 1;

      // Generate test if requested
      if (withTests) {
        final testDir = Directory(path.join('test', 'features', feature, 'services'));
        testDir.createSync(recursive: true);
        
        final testFile = File(path.join(testDir.path, '${serviceName}_service_test.dart'));
        final testContent = _generateTestContent(serviceName, feature, type);
        await testFile.writeAsString(testContent);
        filesGenerated++;
      }

      // Generate mock if requested
      if (withMocks) {
        final mocksDir = Directory(path.join('test', 'mocks'));
        mocksDir.createSync(recursive: true);
        
        final mockFile = File(path.join(mocksDir.path, '${serviceName}_service_mock.dart'));
        final mockContent = _generateMockContent(serviceName, feature, type);
        await mockFile.writeAsString(mockContent);
        filesGenerated++;
      }

      stopwatch.stop();

      final result = CommandResult.success(
        command: 'add service',
        message: 'Service added successfully',
        data: {
          'service_name': serviceName,
          'feature': feature,
          'type': type,
          'with_tests': withTests,
          'with_mocks': withMocks,
          'files_generated': filesGenerated,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
        nextSteps: [
          const NextStep(
            command: 'flutter test',
            description: 'Run tests to verify the service',
          ),
        ],
      );
      
      return result;
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to add service: $e',
        suggestion: 'Check your project structure and try again',
      );
    }
  }

  bool _isValidName(String name) {
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name) && name.length <= 50;
  }

  String _generateServiceContent(String serviceName, String feature, String type) {
    final pascalName = _toPascalCase(serviceName);
    
    switch (type) {
      case 'api':
        return '''
import 'dart:convert';
import 'package:http/http.dart' as http;

class ${pascalName}Service {
  final http.Client _client;
  final String baseUrl;

  ${pascalName}Service({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> fetchData() async {
    try {
      final response = await _client.get(
        Uri.parse('\$baseUrl/$serviceName'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch data: \${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  Future<Map<String, dynamic>> postData(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        Uri.parse('\$baseUrl/$serviceName'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to post data: \${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  void dispose() {
    _client.close();
  }
}
''';
      case 'local':
        return '''
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class ${pascalName}Service {
  final String _dataPath;

  ${pascalName}Service({String? dataPath}) 
      : _dataPath = dataPath ?? path.join(Directory.current.path, 'data', '$serviceName.json');

  Future<Map<String, dynamic>> loadData() async {
    try {
      final file = File(_dataPath);
      if (!await file.exists()) {
        return {};
      }
      
      final content = await file.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load data: \$e');
    }
  }

  Future<void> saveData(Map<String, dynamic> data) async {
    try {
      final file = File(_dataPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(json.encode(data));
    } catch (e) {
      throw Exception('Failed to save data: \$e');
    }
  }

  Future<void> deleteData() async {
    try {
      final file = File(_dataPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete data: \$e');
    }
  }
}
''';
      case 'cache':
        return '''
import 'dart:convert';

class ${pascalName}Service {
  final Map<String, dynamic> _cache = {};
  final Duration _cacheExpiry;
  final Map<String, DateTime> _cacheTimestamps = {};

  ${pascalName}Service({Duration? cacheExpiry}) 
      : _cacheExpiry = cacheExpiry ?? const Duration(hours: 1);

  Future<Map<String, dynamic>> getData(String key) async {
    if (_isCacheValid(key)) {
      return _cache[key] as Map<String, dynamic>;
    }
    
    // TODO: Implement actual data fetching logic
    final data = <String, dynamic>{};
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    
    return data;
  }

  void setData(String key, Map<String, dynamic> data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }
}
''';
      default:
        return '''
class ${pascalName}Service {
  // TODO: Implement your service logic here
  
  Future<void> initialize() async {
    // Initialization logic
  }
  
  Future<void> dispose() async {
    // Cleanup logic
  }
}
''';
    }
  }

  String _generateTestContent(String serviceName, String feature, String type) {
    final pascalName = _toPascalCase(serviceName);
    return '''
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_tools/features/$feature/services/${serviceName}_service.dart';

void main() {
  group('${pascalName}Service', () {
    late ${pascalName}Service service;

    setUp(() {
      service = ${pascalName}Service();
    });

    tearDown(() {
      // Cleanup if needed
    });

    test('should initialize successfully', () async {
      // Arrange & Act
      await service.initialize();

      // Assert
      expect(service, isNotNull);
    });

    // TODO: Add more specific tests based on service type
  });
}
''';
  }

  String _generateMockContent(String serviceName, String feature, String type) {
    final pascalName = _toPascalCase(serviceName);
    return '''
import 'package:mocktail/mocktail.dart';
import 'package:fly_tools/features/$feature/services/${serviceName}_service.dart';

class Mock${pascalName}Service extends Mock implements ${pascalName}Service {}

// Example usage in tests:
// final mockService = Mock${pascalName}Service();
// when(() => mockService.initialize()).thenAnswer((_) async {});
''';
  }

  String _toPascalCase(String input) {
    if (input.isEmpty) return input;
    final words = input.split('_');
    return words.map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join('');
  }
}