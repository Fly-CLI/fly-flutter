import 'package:flutter/material.dart';
import 'package:fly_navigation/fly_navigation.dart';

import 'feature_screen_type.dart';

final class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
  }
}

class AppNavigator extends NavigationService<FeatureScreen> {
  AppNavigator() : super(navigationManager: NavigationManager.shared);

  @override
  String resolveRoute(FeatureScreen feature, {Map<String, dynamic>? arguments}) {
    return feature.path;
  }

  @override
  FeatureScreen? resolveFeature(String route) {
    return FeatureScreen.values.firstWhere(
      (feature) => feature.path == route,
      orElse: () => FeatureScreen.home,
    );
  }
}
