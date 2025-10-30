import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed parameters for fly.add.screen tool
class FlyAddScreenParams extends ToolParameter {
  FlyAddScreenParams({
    required this.screenName,
    this.feature,
    this.screenType,
    this.withViewModel,
    this.withTests,
    this.withValidation,
    this.withNavigation,
  });

  /// Create from JSON Map
  factory FlyAddScreenParams.fromJson(Map<String, Object?> json) {
    return FlyAddScreenParams(
      screenName: json['screenName'] as String? ?? '',
      feature: json['feature'] as String?,
      screenType: json['screenType'] as String?,
      withViewModel: json['withViewModel'] as bool?,
      withTests: json['withTests'] as bool?,
      withValidation: json['withValidation'] as bool?,
      withNavigation: json['withNavigation'] as bool?,
    );
  }

  /// Screen name (required)
  final String screenName;

  /// Feature name
  final String? feature;

  /// Screen type
  final String? screenType;

  /// Whether to include ViewModel/Provider
  final bool? withViewModel;

  /// Whether to include test files
  final bool? withTests;

  /// Whether to include form validation (for form screens)
  final bool? withValidation;

  /// Whether to include navigation logic
  final bool? withNavigation;

  @override
  Map<String, Object?> toJson() => {
        'screenName': screenName,
        if (feature != null) 'feature': feature,
        if (screenType != null) 'screenType': screenType,
        if (withViewModel != null) 'withViewModel': withViewModel,
        if (withTests != null) 'withTests': withTests,
        if (withValidation != null) 'withValidation': withValidation,
        if (withNavigation != null) 'withNavigation': withNavigation,
      };
}

