import 'package:fly_mcp/fly_mcp.dart';

/// Typed parameters for fly.generate.service tool
class GenerateServiceParams extends ToolParameter {
  GenerateServiceParams({
    required this.serviceName,
    this.feature,
    this.serviceType,
    this.withTests,
    this.withMocks,
    this.withInterceptors,
    this.baseUrl,
  });

  /// Create from JSON Map
  factory GenerateServiceParams.fromJson(Map<String, Object?> json) {
    return GenerateServiceParams(
      serviceName: json['serviceName'] as String? ?? '',
      feature: json['feature'] as String?,
      serviceType: json['serviceType'] as String?,
      withTests: json['withTests'] as bool?,
      withMocks: json['withMocks'] as bool?,
      withInterceptors: json['withInterceptors'] as bool?,
      baseUrl: json['baseUrl'] as String?,
    );
  }

  /// Service name (required)
  final String serviceName;

  /// Feature name
  final String? feature;

  /// Service type
  final String? serviceType;

  /// Whether to include test files
  final bool? withTests;

  /// Whether to include mock files
  final bool? withMocks;

  /// Whether to include HTTP interceptors (for API services)
  final bool? withInterceptors;

  /// Base URL for API services
  final String? baseUrl;

  @override
  Map<String, Object?> toJson() => {
        'serviceName': serviceName,
        if (feature != null) 'feature': feature,
        if (serviceType != null) 'serviceType': serviceType,
        if (withTests != null) 'withTests': withTests,
        if (withMocks != null) 'withMocks': withMocks,
        if (withInterceptors != null) 'withInterceptors': withInterceptors,
        if (baseUrl != null) 'baseUrl': baseUrl,
      };
}

