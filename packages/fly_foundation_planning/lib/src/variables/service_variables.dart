import 'mode_specific_variables.dart';
import '../foundation_model.dart';
import '../mason_variable_keys.dart';

/// Service-specific derived variables.
final class ServiceVariables extends ModeSpecificVariables {
  const ServiceVariables({
    this.isService = true,
    this.serviceType,
    this.isApiService = false,
    this.isLocalService = false,
    this.isCacheService = false,
    this.isAnalyticsService = false,
    this.isStorageService = false,
    this.supportsRetry = false,
    this.supportsCaching = false,
    this.supportsInterceptors = false,
    this.generateMocks = false,
    this.feature,
    this.componentName,
  });

  final bool isService;
  final ServiceType? serviceType;
  final bool isApiService;
  final bool isLocalService;
  final bool isCacheService;
  final bool isAnalyticsService;
  final bool isStorageService;
  final bool supportsRetry;
  final bool supportsCaching;
  final bool supportsInterceptors;
  final bool generateMocks;
  final String? feature;
  final String? componentName;

  @override
  GenerationMode get mode => GenerationMode.service;

  @override
  Map<String, dynamic> toMasonVars() {
    final result = <String, dynamic>{
      MasonVarKey.isService.key: isService,
      MasonVarKey.isApiService.key: isApiService,
      MasonVarKey.isLocalService.key: isLocalService,
      MasonVarKey.isCacheService.key: isCacheService,
      MasonVarKey.isAnalyticsService.key: isAnalyticsService,
      MasonVarKey.isStorageService.key: isStorageService,
      MasonVarKey.supportsRetry.key: supportsRetry,
      MasonVarKey.supportsCaching.key: supportsCaching,
      MasonVarKey.supportsInterceptors.key: supportsInterceptors,
      MasonVarKey.generateMocks.key: generateMocks,
    };

    if (serviceType != null) {
      result[MasonVarKey.serviceType.key] = serviceType!.key;
    }
    if (feature != null) {
      result[MasonVarKey.feature.key] = feature;
    }
    if (componentName != null) {
      result[MasonVarKey.componentName.key] = componentName;
    }

    return result;
  }

  /// Creates a copy with updated fields.
  ServiceVariables copyWith({
    bool? isService,
    ServiceType? serviceType,
    bool? isApiService,
    bool? isLocalService,
    bool? isCacheService,
    bool? isAnalyticsService,
    bool? isStorageService,
    bool? supportsRetry,
    bool? supportsCaching,
    bool? supportsInterceptors,
    bool? generateMocks,
    String? feature,
    String? componentName,
  }) {
    return ServiceVariables(
      isService: isService ?? this.isService,
      serviceType: serviceType ?? this.serviceType,
      isApiService: isApiService ?? this.isApiService,
      isLocalService: isLocalService ?? this.isLocalService,
      isCacheService: isCacheService ?? this.isCacheService,
      isAnalyticsService: isAnalyticsService ?? this.isAnalyticsService,
      isStorageService: isStorageService ?? this.isStorageService,
      supportsRetry: supportsRetry ?? this.supportsRetry,
      supportsCaching: supportsCaching ?? this.supportsCaching,
      supportsInterceptors: supportsInterceptors ?? this.supportsInterceptors,
      generateMocks: generateMocks ?? this.generateMocks,
      feature: feature ?? this.feature,
      componentName: componentName ?? this.componentName,
    );
  }
}

