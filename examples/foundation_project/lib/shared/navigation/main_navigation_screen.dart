import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foundation_project/shared/navigation/app_navigation.dart';
import 'package:foundation_project/shared/navigation/bottom_navigation/app_bottom_navigation.dart';
import 'package:foundation_project/shared/navigation/bottom_navigation/bottom_navigation_provider.dart';
import 'package:foundation_project/shared/navigation/bottom_navigation/navigation_items.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';

/// Main navigation screen that wraps bottom navigation
class MainNavigationScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainNavigationScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize navigation index based on current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateNavigationIndex();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigationIndex();
  }

  void _updateNavigationIndex() {
    final router = GoRouter.of(context);
    final currentLocation = router.routerDelegate.currentConfiguration.uri.path;

    // Find matching feature
    final feature = FeatureScreenType.values.firstWhere(
      (f) => _matchesRoute(f.route, currentLocation),
      orElse: () => FeatureScreenType.home,
    );

    // Update navigation index
    final index = NavigationItemsHelper.getIndexByFeature(feature, context);
    if (index != -1) {
      ref.read(bottomNavigationProvider.notifier).setIndex(index, context);
    }
  }

  bool _matchesRoute(String routePattern, String currentPath) {
    // Simple route matching - can be enhanced
    if (routePattern == currentPath) return true;
    if (routePattern.contains(':id') && currentPath.contains('/')) {
      final patternParts = routePattern.split('/');
      final pathParts = currentPath.split('/');
      if (patternParts.length == pathParts.length) {
        return true; // Simplified matching
      }
    }
    return false;
  }

  void _onNavigationTap(int index) {
    final items = getBottomNavigationItems(context);
    if (index >= 0 && index < items.length) {
      final feature = items[index].feature;
      AppNavigation.instance.navigateTo(feature);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavigationProvider);
    final items = getBottomNavigationItems(context);
    final shouldShowFAB = items[currentIndex].showFAB;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: currentIndex,
        onTap: _onNavigationTap,
      ),
      floatingActionButton: shouldShowFAB
          ? FloatingActionButton(
              onPressed: () {
                final feature = items[currentIndex].feature;
                if (feature == FeatureScreenType.tasks) {
                  AppNavigation.instance.navigateTo(FeatureScreenType.taskForm);
                } else if (feature == FeatureScreenType.notes) {
                  AppNavigation.instance.navigateTo(FeatureScreenType.noteForm);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

