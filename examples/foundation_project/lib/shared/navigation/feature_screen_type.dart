/// Enum for application features with their corresponding routes
///
/// To add a new feature:
/// 1. Add the feature with its route and protection status
/// 2. Set isProtected: true for features that require authentication
/// 3. Set isProtected: false for public features
enum FeatureScreen {
  // Main features
  home('/', isProtected: false),
  tasks('/tasks', isProtected: true),
  notes('/notes', isProtected: true),
  settings('/settings', isProtected: true),

  // Detail features
  taskDetail('/tasks/:id', isProtected: true),
  noteDetail('/notes/:id', isProtected: true),

  // Form features
  taskForm('/tasks/form', isProtected: true),
  noteForm('/notes/form', isProtected: true);

  const FeatureScreen(this.route, {required this.isProtected});

  final String route;
  final bool isProtected;

  /// Helper method to check if this feature requires authentication
  bool get requiresAuth => isProtected;

  /// Helper method to check if this feature is public
  bool get isPublic => !isProtected;

  /// Helper method to get all protected features
  static List<FeatureScreen> get protectedFeatures =>
      FeatureScreen.values.where((feature) => feature.isProtected).toList();

  /// Helper method to get all public features
  static List<FeatureScreen> get publicFeatures =>
      FeatureScreen.values.where((feature) => !feature.isProtected).toList();
}

