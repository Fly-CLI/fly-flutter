import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/shared/navigation/bottom_navigation/navigation_items.dart';
import 'package:foundation_project/shared/themes/themes.dart';

/// Main bottom navigation widget
class AppBottomNavigation extends ConsumerStatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  ConsumerState<AppBottomNavigation> createState() =>
      _AppBottomNavigationState();
}

class _AppBottomNavigationState extends ConsumerState<AppBottomNavigation> {
  @override
  Widget build(BuildContext context) {
    final themeData = getAppTheme(context);
    final colors = themeData.colors;
    final typography = themeData.textTheme;

    final items = getBottomNavigationItems(context);

    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: colors.surface,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.onSurface.withOpacity(0.6),
      selectedLabelStyle: typography.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: typography.bodyMedium,
      elevation: 8,
      items: _buildNavigationItems(items),
    );
  }

  List<BottomNavigationBarItem> _buildNavigationItems(
    List<NavigationItem> items,
  ) {
    return items.map((item) {
      final isSelected = items.indexOf(item) == widget.currentIndex;
      final icon = isSelected ? item.activeIcon : item.icon;

      return BottomNavigationBarItem(
        icon: Icon(icon),
        activeIcon: Icon(item.activeIcon),
        label: item.label,
        tooltip: item.label,
      );
    }).toList();
  }
}

