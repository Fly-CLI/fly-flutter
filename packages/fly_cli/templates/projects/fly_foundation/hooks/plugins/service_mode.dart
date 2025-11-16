import 'package:mason/mason.dart';

import 'foundation_model.dart';
import 'planner.dart';

class ServiceModePlanner implements PlannerPlugin {
  @override
  bool canHandle(BaseTemplateVariables base) {
    return base.generationMode == GenerationMode.service;
  }

  @override
  DerivedTemplateVariables derive(
    BaseTemplateVariables base,
    DerivedTemplateVariables acc,
    Logger logger,
  ) {
    final serviceType = base.serviceType ?? ServiceType.api;
    final withRetry = base.serviceRetry;
    final withCaching = base.serviceCaching;
    final withInterceptors = base.serviceInterceptors;
    final withMocks = base.serviceMocks;

    final isApiService = serviceType == ServiceType.api;
    final isLocalService = serviceType == ServiceType.local;
    final isCacheService = serviceType == ServiceType.cache;
    final isAnalyticsService = serviceType == ServiceType.analytics;
    final isStorageService = serviceType == ServiceType.storage;

    // Validation: analytics + caching not supported
    if (isAnalyticsService && withCaching) {
      throw const HookException(
        'Invalid combination: service_type=analytics does not support with_caching=true.',
      );
    }

    return DerivedTemplateVariables(
      isProject: false,
      isFeature: false,
      isService: true,
      activeMode: GenerationMode.service,
      serviceType: serviceType,
      isApiService: isApiService,
      isLocalService: isLocalService,
      isCacheService: isCacheService,
      isAnalyticsService: isAnalyticsService,
      isStorageService: isStorageService,
      supportsRetry: withRetry && isApiService,
      supportsCaching: withCaching &&
          (isApiService || isLocalService || isCacheService),
      supportsInterceptors: withInterceptors && isApiService,
      generateMocks: withMocks,
    );
  }
}


