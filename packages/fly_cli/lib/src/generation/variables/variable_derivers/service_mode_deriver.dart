import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';

/// Deriver that sets service-mode-specific variables.
class ServiceModeDeriver implements VariableDeriver {
  const ServiceModeDeriver();

  @override
  String get id => 'service_mode';

  @override
  bool supports(GenerationContext ctx) => ctx.mode == GenerationMode.service;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    ComposerLogger logger,
  ) {
    final serviceTypeStr =
        ctx.rawVars[ServiceVarKey.serviceType.key] as String? ??
        ctx.rawVars['service_type'] as String?;
    final serviceType = serviceTypeStr != null
        ? ServiceType.fromKey(serviceTypeStr)
        : ServiceType.api;

    final withRetry =
        ctx.rawVars[ServiceVarKey.withRetryLogic.key] as bool? ??
        ctx.rawVars['with_retry_logic'] as bool? ??
        false;

    final withCaching =
        ctx.rawVars[ServiceVarKey.withCaching.key] as bool? ??
        ctx.rawVars['with_caching'] as bool? ??
        false;

    final withInterceptors =
        ctx.rawVars[ServiceVarKey.withInterceptors.key] as bool? ??
        ctx.rawVars['with_interceptors'] as bool? ??
        false;

    final withMocks =
        ctx.rawVars[ServiceVarKey.withMocks.key] as bool? ??
        ctx.rawVars['with_mocks'] as bool? ??
        false;

    final name =
        ctx.rawVars[BaseVarKey.name.key] as String? ??
        ctx.rawVars['name'] as String? ??
        'unnamed';
    final snakeName = NamingUtils.toSnakeCase(name);

    // Get feature from input vars or current bag, defaulting to 'core' if not provided
    final feature =
        ctx.rawVars[BaseVarKey.feature.key] as String? ??
        ctx.rawVars['feature'] as String? ??
        current.get<String>(BaseVarKey.feature.key) ??
        'core';

    final isApiService = serviceType == ServiceType.api;
    final isLocalService = serviceType == ServiceType.local;
    final isCacheService = serviceType == ServiceType.cache;
    final isAnalyticsService = serviceType == ServiceType.analytics;
    final isStorageService = serviceType == ServiceType.storage;

    // Validation: analytics + caching not supported
    if (isAnalyticsService && withCaching) {
      throw const ComposerException(
        'Invalid combination: service_type=analytics does not support with_caching=true.',
      );
    }

    return current.setAll({
      ServiceVarKey.serviceType.key: serviceType.key,
      ServiceVarKey.isApiService.key: isApiService,
      ServiceVarKey.isLocalService.key: isLocalService,
      ServiceVarKey.isCacheService.key: isCacheService,
      ServiceVarKey.isAnalyticsService.key: isAnalyticsService,
      ServiceVarKey.isStorageService.key: isStorageService,
      ServiceVarKey.supportsRetry.key: withRetry && isApiService,
      ServiceVarKey.supportsCaching.key:
          withCaching && (isApiService || isLocalService || isCacheService),
      ServiceVarKey.supportsInterceptors.key: withInterceptors && isApiService,
      ServiceVarKey.generateMocks.key: withMocks,
      BaseVarKey.feature.key: feature,
      BaseVarKey.componentName.key: snakeName,
    });
  }
}
