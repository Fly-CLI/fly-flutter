import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/core/generation/foundation/foundation_domain/foundation_types.dart';
import 'package:fly_cli/src/core/generation/utils/mason_variable_keys.dart';

/// Deriver that sets service-mode-specific variables.
class ServiceModeDeriver implements VariableDeriver {
  const ServiceModeDeriver();

  @override
  String get id => 'service_mode';

  @override
  bool supports(GenerationContext ctx) =>
      ctx.mode == GenerationMode.service;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    ComposerLogger logger,
  ) {
    final serviceTypeStr = ctx.rawVars[MasonVarKey.serviceType.key] as String? ??
        ctx.rawVars['service_type'] as String?;
    final serviceType = serviceTypeStr != null
        ? ServiceType.fromKey(serviceTypeStr)
        : ServiceType.api;

    final withRetry = ctx.rawVars[MasonVarKey.withRetryLogic.key] as bool? ??
        ctx.rawVars['with_retry_logic'] as bool? ??
        false;

    final withCaching = ctx.rawVars[MasonVarKey.withCaching.key] as bool? ??
        ctx.rawVars['with_caching'] as bool? ??
        false;

    final withInterceptors =
        ctx.rawVars[MasonVarKey.withInterceptors.key] as bool? ??
            ctx.rawVars['with_interceptors'] as bool? ??
            false;

    final withMocks = ctx.rawVars[MasonVarKey.withMocks.key] as bool? ??
        ctx.rawVars['with_mocks'] as bool? ??
        false;

    final name = ctx.rawVars[MasonVarKey.name.key] as String? ??
        ctx.rawVars['name'] as String? ??
        'unnamed';
    final snakeName = NamingUtils.toSnakeCase(name);

    // Get feature from input vars or current bag, defaulting to 'core' if not provided
    final feature = ctx.rawVars[MasonVarKey.feature.key] as String? ??
        ctx.rawVars['feature'] as String? ??
        current.get<String>(MasonVarKey.feature.key) ??
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
      MasonVarKey.isService.key: true,
      MasonVarKey.serviceType.key: serviceType.key,
      MasonVarKey.isApiService.key: isApiService,
      MasonVarKey.isLocalService.key: isLocalService,
      MasonVarKey.isCacheService.key: isCacheService,
      MasonVarKey.isAnalyticsService.key: isAnalyticsService,
      MasonVarKey.isStorageService.key: isStorageService,
      MasonVarKey.supportsRetry.key: withRetry && isApiService,
      MasonVarKey.supportsCaching.key: withCaching &&
          (isApiService || isLocalService || isCacheService),
      MasonVarKey.supportsInterceptors.key: withInterceptors && isApiService,
      MasonVarKey.generateMocks.key: withMocks,
      MasonVarKey.feature.key: feature,
      MasonVarKey.componentName.key: snakeName,
    });
  }
}

