import 'package:flutter/material.dart';

/// App configuration class
class AppNavigation {
  /// Global NavigatorKey for navigation operations
  static GlobalKey<NavigatorState> globalKey = GlobalKey<NavigatorState>();

  /// Current BuildContext from the navigator
  static BuildContext? get currentContext {
    return globalKey.currentContext;
  }
}
