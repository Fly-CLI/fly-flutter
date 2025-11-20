import 'package:fly_foundation_planning/fly_foundation_planning.dart';
import 'package:test/test.dart';

import 'test_helpers/test_pipeline.dart';

void main() {
  group('FoundationPlanner', () {
    late FoundationPlanner planner;
    late TestLogger logger;

    setUp(() {
      logger = TestLogger();
      planner = FoundationPlanner(
        variablePipeline: createTestPipeline(),
        logger: logger,
      );
    });

    test('plans project generation correctly', () {
      final rawVars = <String, dynamic>{
        'name': 'test_project',
        'organization': 'com.example',
        'generation_mode': 'project',
        'platforms': ['ios', 'android'],
        'preset': 'starter',
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.moduleInvocations.length, equals(1));
      expect(result.moduleInvocations.first.moduleName, equals('project'));
      expect(result.moduleInvocations.first.brickId, equals('fly_foundation_project'));
      expect(result.derivedVars['is_project'], isTrue);
      expect(result.derivedVars['supports_ios'], isTrue);
      expect(result.derivedVars['supports_android'], isTrue);
    });

    test('plans feature generation correctly', () {
      final rawVars = <String, dynamic>{
        'name': 'home_screen',
        'generation_mode': 'feature',
        'feature': 'home',
        'screen_type': 'list',
        'with_viewmodel': true,
        'with_tests': true,
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.moduleInvocations.length, equals(1));
      expect(result.moduleInvocations.first.moduleName, equals('feature'));
      expect(result.moduleInvocations.first.brickId, equals('fly_foundation_feature'));
      expect(result.derivedVars['is_feature'], isTrue);
      expect(result.derivedVars['is_list_screen'], isTrue);
    });

    test('plans service generation correctly', () {
      final rawVars = <String, dynamic>{
        'name': 'api_service',
        'generation_mode': 'service',
        'feature': 'core',
        'service_type': 'api',
        'with_retry_logic': true,
        'with_caching': true,
        'with_interceptors': true,
        'with_mocks': true,
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.moduleInvocations.length, equals(1));
      expect(result.moduleInvocations.first.moduleName, equals('service'));
      expect(result.moduleInvocations.first.brickId, equals('fly_foundation_service'));
      expect(result.derivedVars['is_service'], isTrue);
      expect(result.derivedVars['is_api_service'], isTrue);
      expect(result.derivedVars['supports_retry'], isTrue);
      expect(result.derivedVars['supports_caching'], isTrue);
    });

    test('applies preset configuration correctly', () {
      final rawVars = <String, dynamic>{
        'name': 'test_project',
        'organization': 'com.example',
        'generation_mode': 'project',
        'platforms': ['ios'],
        'preset': 'minimal',
      };

      final result = planner.planFoundationGeneration(rawVars);

      // Minimal preset should have fewer features enabled
      expect(result.derivedVars['with_tests'], isFalse);
      expect(result.derivedVars['with_docs'], isFalse);
    });

    test('throws error for invalid service type combination', () {
      final rawVars = <String, dynamic>{
        'name': 'analytics_service',
        'generation_mode': 'service',
        'service_type': 'analytics',
        'with_caching': true, // Invalid: analytics doesn't support caching
      };

      expect(
        () => planner.planFoundationGeneration(rawVars),
        throwsA(isA<PlanningException>()),
      );
    });

    test('plans project with all presets correctly', () {
      final presets = ['minimal', 'starter', 'batteries_included'];
      
      for (final preset in presets) {
        final rawVars = <String, dynamic>{
          'name': 'test_project',
          'organization': 'com.example',
          'generation_mode': 'project',
          'platforms': ['ios', 'android'],
          'preset': preset,
        };

        final result = planner.planFoundationGeneration(rawVars);

        expect(result.moduleInvocations.length, equals(1));
        expect(result.moduleInvocations.first.brickId, equals('fly_foundation_project'));
        expect(result.derivedVars['preset'], equals(preset));
      }
    });

    test('plans project with code generation disabled', () {
      final rawVars = <String, dynamic>{
        'name': 'test_project',
        'organization': 'com.example',
        'generation_mode': 'project',
        'platforms': ['ios', 'android'],
        'code_generation': false,
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.derivedVars['code_generation'], isFalse);
      expect(result.derivedVars.containsKey('build_yaml'), isTrue);
    });

    test('plans project with AI integration disabled', () {
      final rawVars = <String, dynamic>{
        'name': 'test_project',
        'organization': 'com.example',
        'generation_mode': 'project',
        'platforms': ['ios', 'android'],
        'ai_integration': false,
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.derivedVars['ai_integration'], isFalse);
      expect(result.derivedVars['with_mcp'], isFalse);
    });

    test('plans project with tests disabled', () {
      final rawVars = <String, dynamic>{
        'name': 'test_project',
        'organization': 'com.example',
        'generation_mode': 'project',
        'platforms': ['ios', 'android'],
        'with_tests': false,
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.derivedVars['with_tests'], isFalse);
    });

    test('plans project with desktop platforms', () {
      final rawVars = <String, dynamic>{
        'name': 'test_project',
        'organization': 'com.example',
        'generation_mode': 'project',
        'platforms': ['macos', 'windows', 'linux'],
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.derivedVars['supports_macos'], isTrue);
      expect(result.derivedVars['supports_windows'], isTrue);
      expect(result.derivedVars['supports_linux'], isTrue);
    });

    test('plans feature with auth screen type', () {
      final rawVars = <String, dynamic>{
        'name': 'login',
        'generation_mode': 'feature',
        'feature': 'auth',
        'screen_type': 'auth',
        'with_viewmodel': true,
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.moduleInvocations.first.brickId, equals('fly_foundation_feature'));
      expect(result.derivedVars['is_auth_screen'], isTrue);
    });

    test('plans feature with detail screen type', () {
      final rawVars = <String, dynamic>{
        'name': 'product_detail',
        'generation_mode': 'feature',
        'feature': 'products',
        'screen_type': 'detail',
        'with_viewmodel': true,
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.derivedVars['is_detail_screen'], isTrue);
    });

    test('plans feature with form and validation', () {
      final rawVars = <String, dynamic>{
        'name': 'user_form',
        'generation_mode': 'feature',
        'feature': 'users',
        'screen_type': 'form',
        'with_viewmodel': true,
        'with_validation': true,
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.derivedVars['is_form_screen'], isTrue);
      expect(result.derivedVars['with_validation'], isTrue);
    });

    test('plans feature with settings screen type', () {
      final rawVars = <String, dynamic>{
        'name': 'settings',
        'generation_mode': 'feature',
        'feature': 'settings',
        'screen_type': 'settings',
        'with_viewmodel': true,
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.derivedVars['is_settings_screen'], isTrue);
    });

    test('plans service with analytics type', () {
      final rawVars = <String, dynamic>{
        'name': 'analytics_service',
        'generation_mode': 'service',
        'feature': 'analytics',
        'service_type': 'analytics',
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.moduleInvocations.first.brickId, equals('fly_foundation_service'));
      expect(result.derivedVars['is_analytics_service'], isTrue);
    });

    test('plans service with cache type', () {
      final rawVars = <String, dynamic>{
        'name': 'cache_service',
        'generation_mode': 'service',
        'feature': 'core',
        'service_type': 'cache',
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.derivedVars['is_cache_service'], isTrue);
    });

    test('plans service with storage type', () {
      final rawVars = <String, dynamic>{
        'name': 'storage_service',
        'generation_mode': 'service',
        'feature': 'core',
        'service_type': 'storage',
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.derivedVars['is_storage_service'], isTrue);
    });

    test('plans service with local type', () {
      final rawVars = <String, dynamic>{
        'name': 'local_service',
        'generation_mode': 'service',
        'feature': 'core',
        'service_type': 'local',
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.derivedVars['is_local_service'], isTrue);
    });

    test('plans service with API, retry, and cache', () {
      final rawVars = <String, dynamic>{
        'name': 'api_service',
        'generation_mode': 'service',
        'feature': 'core',
        'service_type': 'api',
        'with_retry_logic': true,
        'with_caching': true,
        'with_interceptors': true,
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.derivedVars['is_api_service'], isTrue);
      expect(result.derivedVars['supports_retry'], isTrue);
      expect(result.derivedVars['supports_caching'], isTrue);
      expect(result.derivedVars['supports_interceptors'], isTrue);
    });

    test('plans multi-feature project correctly', () {
      final rawVars = <String, dynamic>{
        'name': 'test_project',
        'organization': 'com.example',
        'generation_mode': 'project',
        'platforms': ['ios', 'android'],
        'features': ['home', 'profile', 'settings'],
      };

      final result = planner.planFoundationGeneration(rawVars);

      expect(result.moduleInvocations.length, equals(1));
      expect(result.derivedVars['features'], isA<List>());
      final features = result.derivedVars['features'] as List;
      expect(features.length, equals(3));
      expect(features, containsAll(['home', 'profile', 'settings']));
    });
  });
}

/// Test logger implementation
class TestLogger implements PlanningLogger {
  final List<String> _infoLogs = [];
  final List<String> _warnLogs = [];
  final List<String> _errLogs = [];
  final List<String> _detailLogs = [];

  @override
  void info(String message) => _infoLogs.add(message);

  @override
  void warn(String message) => _warnLogs.add(message);

  @override
  void err(String message) => _errLogs.add(message);

  @override
  void detail(String message) => _detailLogs.add(message);

  List<String> get infoLogs => List.unmodifiable(_infoLogs);
  List<String> get warnLogs => List.unmodifiable(_warnLogs);
  List<String> get errLogs => List.unmodifiable(_errLogs);
  List<String> get detailLogs => List.unmodifiable(_detailLogs);
}

