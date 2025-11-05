import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/navigation/fly_router.dart';
import 'package:foundation_project/shared/navigation/bottom_navigation/navigation_items.dart';

/// Bottom navigation state provider
final bottomNavigationProvider =
    NotifierProvider<BottomNavigationProvider, int>(BottomNavigationProvider.new);

/// Bottom navigation state notifier
class BottomNavigationProvider extends Notifier<int> {
  @override
  int build() => 0;

  /// Set current navigation index
  void setIndex(int index, BuildContext context) {
    final items = getBottomNavigationItems(context);
    if (index >= 0 && index < items.length) {
      state = index;
    }
  }

  /// Navigate to specific feature
  void navigateToFeature(FeatureScreenType feature, BuildContext context) {
    final index = NavigationItemsHelper.getIndexByFeature(feature, context);
    if (index != -1) {
      setIndex(index, context);
    }
  }

  /// Get current feature
  FeatureScreenType getCurrentFeature(BuildContext context) {
    final items = getBottomNavigationItems(context);
    return items[state].feature;
  }

  /// Check if current feature should show FAB
  bool shouldShowFAB(BuildContext context) {
    final items = getBottomNavigationItems(context);
    return items[state].showFAB;
  }

  /// Get current navigation item
  NavigationItem getCurrentItem(BuildContext context) {
    final items = getBottomNavigationItems(context);
    return items[state];
  }

  /// Navigate to next tab
  void nextTab(BuildContext context) {
    final items = getBottomNavigationItems(context);
    final nextIndex = (state + 1) % items.length;
    setIndex(nextIndex, context);
  }

  /// Navigate to previous tab
  void previousTab(BuildContext context) {
    final items = getBottomNavigationItems(context);
    final prevIndex = (state - 1 + items.length) % items.length;
    setIndex(prevIndex, context);
  }

  /// Reset to home
  void resetToHome(BuildContext context) {
    navigateToFeature(FeatureScreenType.home, context);
  }

  /// Get navigation history (for future enhancement)
  List<int> getNavigationHistory() {
    // TODO: Implement navigation history tracking
    return [state];
  }

  /// Handle navigation error
  void _handleNavigationError(String error) {
    // TODO: Implement error handling and logging
    debugPrint('Navigation error: $error');
  }
}

