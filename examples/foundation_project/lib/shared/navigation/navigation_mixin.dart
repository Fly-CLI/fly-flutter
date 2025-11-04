import 'package:flutter/material.dart';

/// Mixin for navigation functionality
mixin NavigationMixin {
  /// Navigate to a route
  void navigateTo(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  /// Navigate back
  void navigateBack(BuildContext context, {Object? result}) {
    Navigator.pop(context, result);
  }

  /// Navigate and replace current route
  void navigateReplace(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }

  /// Navigate and clear stack
  void navigateClearStack(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (route) => false,
      arguments: arguments,
    );
  }
}
