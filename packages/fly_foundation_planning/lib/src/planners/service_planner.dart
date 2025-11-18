import '../foundation_model.dart';
import '../planning_exception.dart';
import '../naming_utils.dart';
import '../variables/mode_specific_variables.dart';
import '../variables/service_variables.dart';
import '../logger.dart';
import 'mode_specific_planner.dart';

/// Planner that derives service-specific variables.
class ServicePlanner implements ModeSpecificPlanner {
  @override
  GenerationMode get supportedMode => GenerationMode.service;

  @override
  ServiceVariables derive(
    BaseTemplateVariables base,
    PlanningLogger logger,
  ) {
    final serviceType = base.serviceType ?? ServiceType.api;
    final withRetry = base.serviceRetry;
    final withCaching = base.serviceCaching;
    final withInterceptors = base.serviceInterceptors;
    final withMocks = base.serviceMocks;
    final snakeName = NamingUtils.toSnakeCase(base.name);

    final isApiService = serviceType == ServiceType.api;
    final isLocalService = serviceType == ServiceType.local;
    final isCacheService = serviceType == ServiceType.cache;
    final isAnalyticsService = serviceType == ServiceType.analytics;
    final isStorageService = serviceType == ServiceType.storage;

    // Validation: analytics + caching not supported
    if (isAnalyticsService && withCaching) {
      throw const PlanningException(
        'Invalid combination: service_type=analytics does not support with_caching=true.',
      );
    }

    return ServiceVariables(
      isService: true,
      serviceType: serviceType,
      isApiService: isApiService,
      isLocalService: isLocalService,
      isCacheService: isCacheService,
      isAnalyticsService: isAnalyticsService,
      isStorageService: isStorageService,
      supportsRetry: withRetry && isApiService,
      supportsCaching:
          withCaching && (isApiService || isLocalService || isCacheService),
      supportsInterceptors: withInterceptors && isApiService,
      generateMocks: withMocks,
      feature: snakeName,
      componentName: snakeName,
    );
  }
}

