import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/core/generation/foundation/foundation_domain/foundation_types.dart';

/// Helper for feature instance configurations in Fly foundation domain.
class FeatureInstanceConfig {
  /// Creates from a generic InstanceConfig.
  factory FeatureInstanceConfig.fromInstanceConfig(InstanceConfig config) {
    final params = config.params;
    return FeatureInstanceConfig(
      name: config.name,
      featureKey: params['feature'] as String? ?? 'core',
      screenType: params['screen_type'] != null
          ? ScreenType.fromKey(params['screen_type'] as String)
          : null,
      withViewModel: params['with_viewmodel'] as bool? ?? true,
      withTests: params['with_tests'] as bool? ?? true,
      withValidation: params['with_validation'] as bool? ?? false,
      withNavigation: params['with_navigation'] as bool? ?? false,
    );
  }
  const FeatureInstanceConfig({
    required this.name,
    required this.featureKey,
    this.screenType,
    this.withViewModel = true,
    this.withTests = true,
    this.withValidation = false,
    this.withNavigation = false,
  });

  final String name;
  final String featureKey;
  final ScreenType? screenType;
  final bool withViewModel;
  final bool withTests;
  final bool withValidation;
  final bool withNavigation;

  /// Converts to InstanceConfig.
  InstanceConfig toInstanceConfig() {
    return InstanceConfig(
      type: 'feature',
      name: name,
      params: {
        'feature': featureKey,
        if (screenType != null) 'screen_type': screenType!.key,
        'with_viewmodel': withViewModel,
        'with_tests': withTests,
        'with_validation': withValidation,
        'with_navigation': withNavigation,
      },
    );
  }
}

/// Helper for service instance configurations in Fly foundation domain.
class ServiceInstanceConfig {
  /// Creates from a generic InstanceConfig.
  factory ServiceInstanceConfig.fromInstanceConfig(InstanceConfig config) {
    final params = config.params;
    return ServiceInstanceConfig(
      name: config.name,
      featureKey: params['feature'] as String? ?? 'core',
      serviceType: params['service_type'] != null
          ? ServiceType.fromKey(params['service_type'] as String)
          : ServiceType.api,
      withTests: params['with_tests'] as bool? ?? true,
      withMocks: params['with_mocks'] as bool? ?? false,
      withInterceptors: params['with_interceptors'] as bool? ?? false,
      withRetryLogic: params['with_retry_logic'] as bool? ?? false,
      withCaching: params['with_caching'] as bool? ?? false,
      baseUrl:
          params['base_url'] as String? ?? params['api_base_url'] as String?,
    );
  }
  const ServiceInstanceConfig({
    required this.name,
    required this.featureKey,
    required this.serviceType,
    this.withTests = true,
    this.withMocks = false,
    this.withInterceptors = false,
    this.withRetryLogic = false,
    this.withCaching = false,
    this.baseUrl,
  });

  final String name;
  final String featureKey;
  final ServiceType serviceType;
  final bool withTests;
  final bool withMocks;
  final bool withInterceptors;
  final bool withRetryLogic;
  final bool withCaching;
  final String? baseUrl;

  /// Converts to InstanceConfig.
  InstanceConfig toInstanceConfig() {
    return InstanceConfig(
      type: 'service',
      name: name,
      params: {
        'feature': featureKey,
        'service_type': serviceType.key,
        'with_tests': withTests,
        'with_mocks': withMocks,
        'with_interceptors': withInterceptors,
        'with_retry_logic': withRetryLogic,
        'with_caching': withCaching,
        if (baseUrl != null) 'api_base_url': baseUrl,
      },
    );
  }
}

