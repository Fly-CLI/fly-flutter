import 'package:flutter/material.dart';
import 'package:foundation_project/core/foundation/navigation/fly_router.dart';
import 'package:foundation_project/l10n/app_localizations.dart';

/// Navigation item configuration for bottom navigation
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final FeatureScreenType feature;
  final bool showFAB;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.feature,
    this.showFAB = false,
  });
}

/// Get localized label for navigation item
String getLocalizedNavigationLabel(String label, BuildContext context) {
  final l10n = AppLocalizations.of(context);
  switch (label) {
    case 'home':
      return l10n.home;
    case 'tasks':
      return l10n.tasks;
    case 'notes':
      return l10n.notes;
    case 'settings':
      return l10n.settings;
    default:
      return label;
  }
}

/// Bottom navigation items list
List<NavigationItem> getBottomNavigationItems(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: l10n.home,
      feature: FeatureScreenType.home,
    ),
    NavigationItem(
      icon: Icons.task_outlined,
      activeIcon: Icons.task,
      label: l10n.tasks,
      feature: FeatureScreenType.tasks,
      showFAB: true,
    ),
    NavigationItem(
      icon: Icons.note_outlined,
      activeIcon: Icons.note,
      label: l10n.notes,
      feature: FeatureScreenType.notes,
      showFAB: true,
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: l10n.settings,
      feature: FeatureScreenType.settings,
    ),
  ];
}

/// Helper functions for navigation items
class NavigationItemsHelper {
  /// Get navigation item by feature
  static NavigationItem? getItemByFeature(
    FeatureScreenType feature,
    BuildContext context,
  ) {
    try {
      return getBottomNavigationItems(context).firstWhere(
        (item) => item.feature == feature,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get index by feature
  static int getIndexByFeature(FeatureScreenType feature, BuildContext context) {
    final items = getBottomNavigationItems(context);
    for (int i = 0; i < items.length; i++) {
      if (items[i].feature == feature) {
        return i;
      }
    }
    return -1;
  }

  /// Get feature by index
  static FeatureScreenType? getFeatureByIndex(int index, BuildContext context) {
    final items = getBottomNavigationItems(context);
    if (index >= 0 && index < items.length) {
      return items[index].feature;
    }
    return null;
  }

  /// Check if feature should show FAB
  static bool shouldShowFAB(FeatureScreenType feature, BuildContext context) {
    final item = getItemByFeature(feature, context);
    return item?.showFAB ?? false;
  }
}

