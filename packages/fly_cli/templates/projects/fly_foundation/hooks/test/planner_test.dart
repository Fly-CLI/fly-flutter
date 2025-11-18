import 'package:mason/mason.dart';
import 'package:test/test.dart';

import '../plugins/foundation_model.dart';
import '../plugins/planner.dart';
import '../plugins/planners/planner_factory.dart';
import '../plugins/variables/composed_derived_variables.dart';
import '../plugins/variables/project_variables.dart';
import '../plugins/variables/feature_variables.dart';
import '../plugins/variables/service_variables.dart';
import '../plugins/hook_exception.dart';

void main() {
  group('CompositePlanner', () {
    late CompositePlanner planner;
    late Logger logger;

    setUp(() {
      planner = CompositePlanner();
      logger = Logger();
    });

    test('derives variables for project mode', () {
      final base = BaseTemplateVariables(
        name: 'test_project',
        organization: 'com.example',
        generationMode: GenerationMode.project,
        platforms: [PlatformType.ios, PlatformType.android],
      );

      final result = planner.run(base, logger);

      expect(result.shared.projectName, equals('test_project'));
      expect(result.shared.supportsIos, isTrue);
      expect(result.shared.supportsAndroid, isTrue);
      expect(result.modeSpecific, isA<ProjectVariables>());
      final projectVars = result.modeSpecific as ProjectVariables;
      expect(projectVars.isProject, isTrue);
    });

    test('derives variables for feature mode', () {
      final base = BaseTemplateVariables(
        name: 'dashboard',
        organization: 'com.example',
        generationMode: GenerationMode.feature,
        platforms: [PlatformType.ios],
        screenType: ScreenType.list,
        stateManagement: StateManagement.riverpod,
      );

      final result = planner.run(base, logger);

      expect(result.modeSpecific, isA<FeatureVariables>());
      final featureVars = result.modeSpecific as FeatureVariables;
      expect(featureVars.isFeature, isTrue);
      expect(featureVars.isListScreen, isTrue);
      expect(featureVars.useRiverpod, isTrue);
      expect(featureVars.feature, equals('dashboard'));
    });

    test('derives variables for service mode', () {
      final base = BaseTemplateVariables(
        name: 'api_service',
        organization: 'com.example',
        generationMode: GenerationMode.service,
        platforms: [PlatformType.ios],
        serviceType: ServiceType.api,
        serviceRetry: true,
        serviceCaching: true,
      );

      final result = planner.run(base, logger);

      expect(result.modeSpecific, isA<ServiceVariables>());
      final serviceVars = result.modeSpecific as ServiceVariables;
      expect(serviceVars.isService, isTrue);
      expect(serviceVars.isApiService, isTrue);
      expect(serviceVars.supportsRetry, isTrue);
      expect(serviceVars.supportsCaching, isTrue);
      expect(serviceVars.componentName, equals('api_service'));
    });

    test('throws HookException for invalid service type combination', () {
      final base = BaseTemplateVariables(
        name: 'analytics_service',
        organization: 'com.example',
        generationMode: GenerationMode.service,
        platforms: [PlatformType.ios],
        serviceType: ServiceType.analytics,
        serviceCaching: true, // Invalid: analytics doesn't support caching
      );

      expect(
        () => planner.run(base, logger),
        throwsA(isA<HookException>().having(
          (e) => e.message,
          'message',
          contains('Invalid combination'),
        )),
      );
    });

    test('throws HookException for unsupported generation mode', () {
      final factory = PlannerFactory.custom(
        modePlanners: {}, // Empty map - no planners registered
        crossCuttingPlanners: [],
      );
      final customPlanner = CompositePlanner.custom(factory);

      final base = BaseTemplateVariables(
        name: 'test',
        organization: 'com.example',
        generationMode: GenerationMode.project,
        platforms: [PlatformType.ios],
      );

      expect(
        () => customPlanner.run(base, logger),
        throwsA(isA<HookException>().having(
          (e) => e.message,
          'message',
          contains('No planner found for generation mode'),
        )),
      );
    });
  });
}

