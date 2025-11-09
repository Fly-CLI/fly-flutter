import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/features/home/presentation/screens/home_screen.dart';
import 'package:foundation_project/features/notes/presentation/screens/notes_screen.dart';
import 'package:foundation_project/features/settings/presentation/screens/settings_screen.dart';
import 'package:foundation_project/features/tasks/presentation/screens/list/tasks_screen.dart';
import 'package:foundation_project/shared/navigation/app_navigation.dart';
import 'package:foundation_project/shared/navigation/bottom_navigation/app_bottom_navigation.dart';
import 'package:foundation_project/shared/navigation/bottom_navigation/bottom_navigation_provider.dart';
import 'package:foundation_project/shared/navigation/bottom_navigation/navigation_items.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';

/// Main navigation shell that decorates feature screens with bottom navigation.
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({
    super.key,
    required this.child,
    required this.feature,
  });

  final Widget child;
  final FeatureScreenType feature;

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  final Map<FeatureScreenType, Widget> _overrideScreens = {};
  late final Map<FeatureScreenType, Widget> _defaultScreens;

  final PageStorageBucket _pageStorageBucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    _defaultScreens = {
      FeatureScreenType.home:
          _wrapWithTabKey(const HomeScreen(), FeatureScreenType.home),
      FeatureScreenType.tasks:
          _wrapWithTabKey(const TasksScreen(), FeatureScreenType.tasks),
      FeatureScreenType.notes:
          _wrapWithTabKey(const NotesScreen(), FeatureScreenType.notes),
      FeatureScreenType.settings:
          _wrapWithTabKey(const SettingsScreen(), FeatureScreenType.settings),
    };

    _overrideScreens[widget.feature] =
        _wrapWithTabKey(widget.child, widget.feature);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncNavigationIndex(widget.feature);
      }
    });
  }

  @override
  void didUpdateWidget(MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _overrideScreens[widget.feature] =
        _wrapWithTabKey(widget.child, widget.feature);

    if (oldWidget.feature != widget.feature) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncNavigationIndex(widget.feature);
        }
      });
    }
  }

  void _syncNavigationIndex(FeatureScreenType feature) {
    ref.read(bottomNavigationProvider.notifier).navigateToFeature(
          feature,
          context,
        );
  }

  void _onNavigationTap(int index) {
    final items = getBottomNavigationItems(context);
    if (index < 0 || index >= items.length) {
      return;
    }

    final targetFeature = items[index].feature;
    final currentFeature = _currentFeature(items);

    if (targetFeature == currentFeature) {
      return;
    }

    FocusScope.of(context).unfocus();
    ref.read(bottomNavigationProvider.notifier).setIndex(index, context);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavigationProvider);
    final items = getBottomNavigationItems(context);
    if (items.isEmpty) {
      return Scaffold(body: widget.child);
    }
    final clampedIndex = currentIndex.clamp(0, items.length - 1).toInt();
    final currentItem = items[clampedIndex];

    return Scaffold(
      body: PageStorage(
        bucket: _pageStorageBucket,
        child: IndexedStack(
          index: clampedIndex,
          children: [
            for (final item in items) _screenForFeature(item.feature),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: clampedIndex,
        onTap: _onNavigationTap,
      ),
      floatingActionButton: currentItem.showFAB
          ? FloatingActionButton(
              onPressed: () {
                final feature = currentItem.feature;
                if (feature == FeatureScreenType.tasks) {
                  AppNavigation.instance.navigateToTaskForm();
                } else if (feature == FeatureScreenType.notes) {
                  AppNavigation.instance.navigateTo(FeatureScreenType.noteForm);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _screenForFeature(FeatureScreenType feature) {
    return _overrideScreens[feature] ??
        _defaultScreens[feature] ??
        _wrapWithTabKey(
          const SizedBox.shrink(),
          feature,
        );
  }

  FeatureScreenType? _currentFeature(List<NavigationItem> items) {
    final currentIndex = ref.read(bottomNavigationProvider);
    if (currentIndex < 0 || currentIndex >= items.length) {
      return null;
    }
    return items[currentIndex].feature;
  }

  Widget _wrapWithTabKey(Widget child, FeatureScreenType feature) {
    final key = PageStorageKey<String>('main-nav-${feature.name}');
    if (child.key == key) {
      return child;
    }
    return KeyedSubtree(
      key: key,
      child: child,
    );
  }
}
