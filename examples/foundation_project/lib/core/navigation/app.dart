import 'package:flutter/material.dart';

/// App configuration class
class App {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get context {
    return navigatorKey.currentContext;
  }
}

