import 'package:flutter/material.dart';

/// App configuration class
class App {
  /// Global NavigatorKey for navigation operations
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Current BuildContext from the navigator
  static BuildContext? get context {
    return navigatorKey.currentContext;
  }
}
