import 'package:mason/mason.dart';

import 'planner.dart';
import 'presets.dart';

class ServiceModePlanner implements PlannerPlugin {
  @override
  bool canHandle(Vars vars) {
    try {
      return GenerationMode.fromVars(vars) == GenerationMode.service;
    } catch (_) {
      return false;
    }
  }

  @override
  Vars derive(Vars vars, Logger logger) {
    // These vars are now derived by PresetPlanner/CoreVarsPlanner
    final serviceType = (vars['service_type'] as String?)?.toLowerCase() ?? 'api';
    final withRetry = vars['with_retry_logic'] == true;
    final withCaching = vars['with_caching'] == true;
    final withInterceptors = vars['with_interceptors'] == true;
    final withMocks = vars['with_mocks'] == true;

    final isApiService = serviceType == 'api';
    final isLocalService = serviceType == 'local';
    final isCacheService = serviceType == 'cache';
    final isAnalyticsService = serviceType == 'analytics';
    final isStorageService = serviceType == 'storage';

    // Validation example: analytics + caching not supported (adjust as needed)
    if (isAnalyticsService && withCaching) {
      throw const HookException(
        'Invalid combination: service_type=analytics does not support with_caching=true.',
      );
    }

    // Note: is_project/is_feature/is_service are already set by CoreVarsPlanner
    return <String, dynamic>{
      'active_mode': 'service',
      'is_project': vars['is_project'] ?? false,
      'is_feature': vars['is_feature'] ?? false,
      'is_service': vars['is_service'] ?? true,
      'is_api_service': isApiService,
      'is_local_service': isLocalService,
      'is_cache_service': isCacheService,
      'is_analytics_service': isAnalyticsService,
      'is_storage_service': isStorageService,
      'supports_retry': withRetry && isApiService,
      'supports_caching': withCaching && (isApiService || isLocalService || isCacheService),
      'supports_interceptors': withInterceptors && isApiService,
      'generate_mocks': withMocks,
    };
  }
}


