import 'package:flutter/material.dart';
import 'package:fly_navigation/src/app_navigation.dart';

/// Function signature for generating a route given a [RouteSettings].
typedef RouteGenerator = Route<dynamic>? Function(RouteSettings settings);

/// Function signature for building an unknown route when a matching route is not found.
typedef UnknownRouteGenerator = Route<dynamic>? Function(RouteSettings settings);

/// Factory signature responsible for creating the list of [NavigatorObserver] instances.
typedef NavigatorObserversFactory = List<NavigatorObserver> Function();

/// Signature for providing a navigator key used by the Flutter navigator stack.
typedef NavigatorKeyProvider = GlobalKey<NavigatorState> Function();

abstract class InitialRouteStrategy {
  const InitialRouteStrategy();

  String provideInitialRoute();
}

abstract class RouteGenerationStrategy {
  const RouteGenerationStrategy();

  Route<dynamic>? onGenerateRoute(RouteSettings settings);
}

abstract class UnknownRouteStrategy {
  const UnknownRouteStrategy();

  Route<dynamic>? onUnknownRoute(RouteSettings settings);
}

abstract class NavigatorObserversStrategy {
  const NavigatorObserversStrategy();

  List<NavigatorObserver> createObservers();
}

abstract class NavigatorKeyStrategy {
  const NavigatorKeyStrategy();

  GlobalKey<NavigatorState> provideNavigatorKey();
}

class ValueInitialRouteStrategy implements InitialRouteStrategy {
  const ValueInitialRouteStrategy(this.initialRoute);

  final String initialRoute;

  @override
  String provideInitialRoute() => initialRoute;
}

class FunctionRouteGenerationStrategy implements RouteGenerationStrategy {
  const FunctionRouteGenerationStrategy(this.generator);

  final RouteGenerator generator;

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) =>
      generator(settings);
}

class FunctionUnknownRouteStrategy implements UnknownRouteStrategy {
  const FunctionUnknownRouteStrategy(this.generator);

  final UnknownRouteGenerator generator;

  @override
  Route<dynamic>? onUnknownRoute(RouteSettings settings) =>
      generator(settings);
}

class FunctionNavigatorObserversStrategy
    implements NavigatorObserversStrategy {
  const FunctionNavigatorObserversStrategy(this.factory);

  final NavigatorObserversFactory factory;

  @override
  List<NavigatorObserver> createObservers() => factory();
}

class FunctionNavigatorKeyStrategy implements NavigatorKeyStrategy {
  const FunctionNavigatorKeyStrategy(this.provider);

  final NavigatorKeyProvider provider;

  @override
  GlobalKey<NavigatorState> provideNavigatorKey() => provider();
}

class StaticNavigatorKeyStrategy implements NavigatorKeyStrategy {
  const StaticNavigatorKeyStrategy(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  GlobalKey<NavigatorState> provideNavigatorKey() => navigatorKey;
}

class AppNavigatorKeyStrategy implements NavigatorKeyStrategy {
  const AppNavigatorKeyStrategy();

  @override
  GlobalKey<NavigatorState> provideNavigatorKey() => AppNavigation.globalKey;
}

class NavigationManager {
  /// Creates a [NavigationManager] using the provided strategy implementations.
  ///
  /// The strategy-based design keeps this manager highly reusable and testable—ideal
  /// for Fly CLI templates where multiple projects can plug in their own navigation
  /// requirements simply by supplying alternative strategies.
  NavigationManager({
    required InitialRouteStrategy initialRouteStrategy,
    required RouteGenerationStrategy routeGenerationStrategy,
    required UnknownRouteStrategy unknownRouteStrategy,
    required NavigatorObserversStrategy navigatorObserversStrategy,
    required NavigatorKeyStrategy navigatorKeyStrategy,
  })  : _initialRouteStrategy = initialRouteStrategy,
        _routeGenerationStrategy = routeGenerationStrategy,
        _unknownRouteStrategy = unknownRouteStrategy,
        _navigatorObserversStrategy = navigatorObserversStrategy,
        _navigatorKeyStrategy = navigatorKeyStrategy;

  /// Convenience factory that adapts plain functions into the respective strategies.
  ///
  /// This is useful when migrating existing `MaterialApp` configurations or when the
  /// navigation concerns are simple enough that dedicated strategy classes would be
  /// overkill. The factory remains completely reusable within Fly CLI generated apps.
  factory NavigationManager.from({
    required String initialRoute,
    required RouteGenerator onGenerateRoute,
    required UnknownRouteGenerator onUnknownRoute,
    NavigatorObserversFactory? navigatorObserversFactory,
    GlobalKey<NavigatorState>? navigatorKey,
    NavigatorKeyProvider? navigatorKeyProvider,
  }) {
    final NavigatorKeyStrategy navigatorKeyStrategy;
    if (navigatorKey != null) {
      navigatorKeyStrategy = StaticNavigatorKeyStrategy(navigatorKey);
    } else if (navigatorKeyProvider != null) {
      navigatorKeyStrategy = FunctionNavigatorKeyStrategy(navigatorKeyProvider);
    } else {
      navigatorKeyStrategy = const AppNavigatorKeyStrategy();
    }

    return NavigationManager(
      initialRouteStrategy: ValueInitialRouteStrategy(initialRoute),
      routeGenerationStrategy:
          FunctionRouteGenerationStrategy(onGenerateRoute),
      unknownRouteStrategy: FunctionUnknownRouteStrategy(onUnknownRoute),
      navigatorObserversStrategy:
          FunctionNavigatorObserversStrategy(navigatorObserversFactory ??
              () => <NavigatorObserver>[]),
      navigatorKeyStrategy: navigatorKeyStrategy,
    );
  }

  final InitialRouteStrategy _initialRouteStrategy;
  final RouteGenerationStrategy _routeGenerationStrategy;
  final UnknownRouteStrategy _unknownRouteStrategy;
  final NavigatorObserversStrategy _navigatorObserversStrategy;
  final NavigatorKeyStrategy _navigatorKeyStrategy;

  String get initialRoute => _initialRouteStrategy.provideInitialRoute();

  Route<dynamic>? onGenerateRoute(RouteSettings settings) =>
      _routeGenerationStrategy.onGenerateRoute(settings);

  Route<dynamic>? onUnknownRoute(RouteSettings settings) =>
      _unknownRouteStrategy.onUnknownRoute(settings);

  List<NavigatorObserver> get navigatorObservers =>
      List<NavigatorObserver>.unmodifiable(
        _navigatorObserversStrategy.createObservers(),
      );

  GlobalKey<NavigatorState> get navigatorKey =>
      _navigatorKeyStrategy.provideNavigatorKey();
}


