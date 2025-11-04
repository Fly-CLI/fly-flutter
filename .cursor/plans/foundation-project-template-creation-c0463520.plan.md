<!-- c0463520-431d-4fc7-8836-45f330a537fa 4a3e78cf-1036-43ec-b3a9-08ed86daebd9 -->
# Task & Notes Manager Implementation Plan

## Overview

Implement a comprehensive Task & Notes Manager application with bottom navigation. Phase 1 includes fully functional Home/Dashboard screen with statistics, quick actions, and network status. The implementation follows StockAI patterns for navigation, dependency injection, pagination, error handling, database, and localization.

## Architecture Decisions

### Navigation Strategy (Following StockAI Pattern)

- **Feature Enum**: Enum-based features with route paths and protection status
- **AppNavigation Class**: Singleton class for type-safe navigation with automatic analytics tracking
- **GoRouter Integration**: GoRouter configuration using Feature enum for route matching
- **Bottom Navigation**: Managed via Riverpod provider with Feature enum integration
- **Analytics Tracking**: Automatic feature access tracking via RecentlyAccessedTrackingService

### State Management

- Riverpod for all state management
- ViewModels extending foundation ViewModel base class
- Providers for shared services and navigation state
- GlobalContainer for app-wide dependency injection

### Storage Strategy

- **Local Database**: Drift (SQLite) for tasks and notes with sync metadata
- **Preferences**: shared_preferences for app settings (via StorageKey enum pattern)
- **Secure Storage**: flutter_secure_storage for sensitive data
- **In-Memory Cache**: For API responses and computed statistics

### Network Strategy

- Mock API service using http package
- AsyncHandler for all network operations
- ConnectivityService for network checks
- Offline queue for failed operations
- Result pattern (AppResult<T>) for all operations

### Localization Strategy

- Flutter gen-l10n for localization
- ARB files for translations (English required, Arabic optional)
- All screens must use AppLocalizations.of(context) for text strings

## Implementation Phases

### Phase 1: Foundation Setup (Current Phase)

#### 1.1 Dependencies

Add required packages to `pubspec.yaml`:

- `drift` and `drift_dev` - Local database
- `sqlite3_flutter_libs` - SQLite support
- `path_provider` - File system paths
- `shared_preferences` - App preferences
- `flutter_secure_storage` - Secure storage
- `http` - HTTP client for mock API
- `flutter_localizations` (sdk) - Localization support
- `intl` - Internationalization

#### 1.2 Localization Setup

- Create `l10n.yaml` configuration file
- Add `generate: true` to `pubspec.yaml` flutter section
- Create `lib/l10n/app_en.arb` with all localized strings
- Create `lib/l10n/app_ar.arb` (optional, for future)
- Run `flutter gen-l10n` to generate localization files
- Update `main.dart` to include `AppLocalizations.localizationsDelegates` and `supportedLocales`

#### 1.3 Project Structure

Create feature-based directory structure:

```
lib/
├── features/
│   ├── home/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── services/
│   │   ├── domain/
│   │   │   └── models/
│   │   └── presentation/
│   │       ├── home_screen.dart
│   │       ├── home_view_model.dart
│   │       └── widgets/
│   ├── tasks/
│   │   └── presentation/
│   │       └── tasks_screen.dart (placeholder)
│   ├── notes/
│   │   └── presentation/
│   │       └── notes_screen.dart (placeholder)
│   └── settings/
│       └── presentation/
│           └── settings_screen.dart (placeholder)
├── core/
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   └── daos/
│   ├── storage/
│   │   ├── interfaces/
│   │   ├── implementations/
│   │   ├── models/
│   │   ├── managers/
│   │   ├── storage_providers.dart
│   │   └── storage.dart
│   ├── repositories/
│   │   ├── interfaces/
│   │   │   └── i_base_repository.dart
│   │   ├── base/
│   │   │   └── base_repository.dart
│   │   ├── task_repository.dart
│   │   ├── note_repository.dart
│   │   ├── repository_factory.dart
│   │   └── repositories.dart
│   ├── di/
│   │   ├── global_container.dart
│   │   └── di.dart
│   ├── pagination/
│   │   ├── paginated_result.dart
│   │   └── pagination.dart
│   ├── result/
│   │   └── app_result.dart (enhance existing)
│   ├── analytics/
│   │   ├── recently_accessed_tracking_service.dart
│   │   ├── analytics_providers.dart
│   │   └── analytics.dart
│   ├── services/
│   │   ├── cache_service.dart
│   │   ├── api_service.dart (mock)
│   │   ├── statistics_service.dart
│   │   ├── sync_service.dart
│   │   └── pagination/
│   │       ├── task_pagination_service.dart
│   │       ├── note_pagination_service.dart
│   │       └── pagination.dart
│   ├── providers/
│   │   ├── repository_providers.dart
│   │   ├── service_providers.dart
│   │   └── providers.dart
│   └── navigation/
│       ├── app_navigation.dart (Feature enum + AppNavigation class)
│       ├── app_router.dart
│       ├── bottom_navigation_provider.dart
│       ├── navigation_items.dart
│       ├── route_handlers.dart
│       └── app_route_config.dart
└── shared/
    └── widgets/
        └── bottom_navigation_bar.dart
```

#### 1.4 Data Models

Create core data models:

- `BaseEntity` model (id, syncStatus, lastSyncedAt, version) - for sync metadata
- `Task` model (extends BaseEntity: id, title, description, status, priority, dueDate, timestamps)
- `Note` model (extends BaseEntity: id, title, content, tags, timestamps)
- `Statistics` model (totalTasks, completedTasks, overdueTasks, todayTasks)
- `SyncStatus` model (lastSync, isSyncing, pendingOperations)
- `PaginatedResult<T>` model (items, total, page, pageSize, hasMore)

#### 1.5 Database Setup (Following StockAI Pattern)

- Create Drift database with tasks and notes tables
- Define table schemas with sync metadata columns (sync_status, last_synced_at, version)
- Create DAO (Data Access Objects) for CRUD operations
- Create Repository abstraction layer over DAOs
- Implement BaseRepository with template method pattern (beforeCreate, beforeUpdate, beforeDelete hooks)
- Add sync metadata support (syncStatus, lastSyncedAt, version)
- Create RepositoryFactory for centralized repository creation
- Initialize database on app startup
- Set up database migrations

#### 1.6 Storage Services (Already in Plan)

- Storage system following StockAI pattern:
  - Interfaces (IStorageService, ISecureStorageService)
  - Implementations (SharedPreferencesStorageService, SecureStorageService)
  - StorageKey enum with StorageType classification
  - Storage managers (AppDataManager, AppConfigDataManager, TaskDataManager, NoteDataManager, SyncDataManager)
  - Storage providers for Riverpod DI

#### 1.7 Dependency Injection (Following StockAI Pattern)

- `GlobalContainer`: Singleton ProviderContainer for app-wide access
  - Static `instance` getter
  - `initialize()` method for app startup
  - `overrideForTesting()` for test support
  - `reset()` for test cleanup
- Initialize GlobalContainer in main.dart
- Create Riverpod providers for all services and managers:
  - Storage providers (regularStorageProvider, secureStorageProvider, appDataManagerProvider)
  - Repository providers (via RepositoryFactory)
  - Service providers (statisticsServiceProvider, syncServiceProvider, cacheServiceProvider)
  - Navigation providers (bottomNavigationProvider)
  - Analytics providers (recentlyAccessedTrackingServiceProvider)

#### 1.8 Navigation Infrastructure (Following StockAI Pattern)

- **Feature Enum**: Enum-based features with route paths and protection status
  - Each feature has: `route` (String), `isProtected` (bool)
  - Helper methods: `requiresAuth`, `isPublic`, `protectedFeatures`, `publicFeatures`
- **AppNavigation Class**: Singleton class for type-safe navigation
  - Static methods: `navigateTo()`, `navigateToReplacement()`, `navigateToAndClear()`, `goBack()`
  - Automatic feature access tracking via `_trackFeatureAccess()`
  - Type-safe navigation methods using Feature enum
  - Integration with analytics/recently accessed tracking
- **AppRouter**: GoRouter configuration with nested routes
  - Uses Feature enum for route matching
  - Route handlers for each feature
  - Route configuration using Feature enum
- **BottomNavigationProvider**: Riverpod provider for tab index (using NotifierProvider)
- **NavigationItems**: Navigation item definitions with Feature enum
- **AppBottomNavigation**: Custom bottom navigation widget
- **Feature Access Tracking**: Integration with analytics service
  - `RecentlyAccessedTrackingService`: Tracks feature access for analytics
  - Automatic tracking on all navigation methods
  - Provider-based tracking service

#### 1.9 Pagination Infrastructure (Following StockAI Pattern)

- `PaginatedResult<T>`: Standardized paginated result model
  - `List<T> items`: The paginated items
  - `int total`: Total number of items
  - `int page`: Current page number
  - `int pageSize`: Items per page
  - `bool hasMore`: Whether there are more items
- `TaskPaginationService`: Dedicated pagination service for tasks
- `NotePaginationService`: Dedicated pagination service for notes
- Pagination services integrate with search and filters
- Support for infinite scroll pagination

#### 1.10 Error Handling Enhancement (Following StockAI Pattern)

- Enhance existing `AppResult<T>` to match StockAI pattern:
  - Ensure sealed class with `Success<T>`, `Failure<T>`, `Loading<T>`
  - Add `when()` method for pattern matching
  - Add `map()` and `mapError()` methods for transformations
- Update all services to return `AppResult<T>`
- Update repositories to return `AppResult<T>`
- Update ViewModels to handle `AppResult<T>` consistently
- Centralized error message formatting using ErrorMessageFormatter

#### 1.11 Main Navigation Screen

- `MainNavigationScreen`: Wrapper screen with bottom navigation
- Handles tab switching using BottomNavigationProvider
- Manages navigation state via Riverpod
- Integrates with GoRouter
- Uses Feature enum for type-safe navigation
- Supports FAB (Floating Action Button) configuration per tab

### Phase 2: Home Screen Implementation (Fully Functional)

#### 2.1 Home ViewModel

- Extends foundation `ViewModel<HomeViewModelState>`
- Manages statistics (total tasks, completed, overdue, today)
- Handles sync operations
- Manages network connectivity status
- Uses AsyncHandler for all async operations
- Uses AppResult pattern for error handling
- Implements lifecycle methods (onInitialize, onAppear)
- Uses storage managers via Riverpod providers
- Uses AppLocalizations for all text strings

#### 2.2 Home ViewModelState

- Loading state
- Error state
- Statistics data
- Sync status
- Network connectivity status

#### 2.3 Home Screen UI (All Localized)

**Statistics Cards Section:**

- Total Tasks card (localized)
- Completed Tasks card (localized)
- Overdue Tasks card (localized)
- Today's Tasks card (localized)
- Each card shows count with icon and color

**Quick Actions Section:**

- Add Task button (localized)
- Add Note button (localized)
- Sync Now button (localized) with loading indicator
- Network status indicator (localized)

**Activity Feed Section:**

- Recent activity list (last 5-10 items)
- Shows task/note creation, completion, updates (localized)
- Pull-to-refresh support

**Sync Status Section:**

- Last sync timestamp (localized, from SyncDataManager)
- Pending operations count (localized)
- Sync progress indicator (when syncing)

#### 2.4 Home Screen Features

- Pull-to-refresh to reload statistics
- Real-time statistics updates
- Network connectivity indicator
- Error handling with feedback system (localized messages)
- Loading states (localized)
- Empty states (localized)

#### 2.5 Statistics Service

- `StatisticsService`: Calculates statistics from database
- Aggregates task counts by status
- Filters tasks by date ranges
- Uses CacheService for result caching with TTL
- Returns `AppResult<Statistics>` for error handling

#### 2.6 Sync Service

- `SyncService`: Handles sync with mock API
- Uses AsyncHandler for network operations
- Implements offline queue
- Uses SyncDataManager to track sync status
- Handles conflicts
- Returns `AppResult<T>` for all operations

### Phase 3: Placeholder Screens (All Localized)

#### 3.1 Tasks Screen (Placeholder)

- Simple scaffold with localized "Coming Soon" message
- Basic structure for future implementation
- Placeholder for task list, filters, search

#### 3.2 Notes Screen (Placeholder)

- Simple scaffold with localized "Coming Soon" message
- Basic structure for future implementation
- Placeholder for notes list, categories, search

#### 3.3 Settings Screen (Placeholder)

- Simple scaffold with localized "Coming Soon" message
- Basic structure for future implementation
- Placeholder for user profile, preferences, data management

## Technical Implementation Details

### Feature Enum Pattern

```dart
enum Feature {
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
  
  const Feature(this.route, {required this.isProtected});
  
  final String route;
  final bool isProtected;
  
  bool get requiresAuth => isProtected;
  bool get isPublic => !isProtected;
  
  static List<Feature> get protectedFeatures =>
      Feature.values.where((f) => f.isProtected).toList();
  
  static List<Feature> get publicFeatures =>
      Feature.values.where((f) => !f.isProtected).toList();
}
```

### AppNavigation Class Pattern

```dart
class AppNavigation {
  static final AppNavigation _instance = AppNavigation._internal();
  factory AppNavigation() => _instance;
  AppNavigation._internal();
  
  static ProviderContainer? _providerContainer;
  
  static void initialize(ProviderContainer container) {
    _providerContainer = container;
  }
  
  static void _trackFeatureAccess(Feature feature) {
    if (_providerContainer == null) return;
    try {
      final trackingService = _providerContainer!.read(
        recentlyAccessedTrackingServiceProvider,
      );
      trackingService.trackFeatureAccess(feature);
    } catch (e) {
      // Silently fail - tracking is not critical
    }
  }
  
  static Future<T?> navigateTo<T>(Feature feature, {Object? arguments}) {
    _trackFeatureAccess(feature);
    return App.navigatorKey.currentState!.pushNamed<T>(
      feature.route,
      arguments: arguments,
    );
  }
  
  // Additional navigation methods...
}
```

### Database Schema with Sync Metadata

```dart
// Tasks Table
@TableName('tasks')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text()(); // 'active', 'completed', 'overdue'
  TextColumn get priority => text()(); // 'low', 'medium', 'high'
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  // Sync metadata
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### GoRouter Configuration with Feature Enum

```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Feature.home.route,
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => Feature.home.route,
      ),
      GoRoute(
        path: Feature.home.route,
        name: Feature.home.name,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Feature.tasks.route,
        name: Feature.tasks.name,
        builder: (context, state) => const TasksScreen(),
      ),
      // Additional routes...
    ],
  );
});
```

### Recently Accessed Tracking Service

```dart
class RecentlyAccessedTrackingService {
  final AppDataManager _dataManager;
  
  RecentlyAccessedTrackingService(this._dataManager);
  
  Future<void> trackFeatureAccess(Feature feature) async {
    // Track feature access for analytics
    // Store in storage for recently accessed items
    // Update analytics metrics
  }
  
  Future<List<Feature>> getRecentlyAccessed({int limit = 10}) async {
    // Get recently accessed features from storage
    return [];
  }
}

@riverpod
RecentlyAccessedTrackingService recentlyAccessedTrackingService(
  RecentlyAccessedTrackingServiceRef ref,
) {
  return RecentlyAccessedTrackingService(
    ref.watch(appDataManagerProvider),
  );
}
```

## Key Files to Create

### Core Infrastructure

1. `lib/core/database/app_database.dart` - Drift database setup
2. `lib/core/database/tables/tasks_table.dart` - Tasks table with sync metadata
3. `lib/core/database/tables/notes_table.dart` - Notes table with sync metadata
4. `lib/core/database/daos/tasks_dao.dart` - Tasks DAO
5. `lib/core/database/daos/notes_dao.dart` - Notes DAO
6. `lib/core/repositories/interfaces/i_base_repository.dart` - Base repository interface
7. `lib/core/repositories/base/base_repository.dart` - B

### To-dos

- [ ] Add required dependencies to pubspec.yaml (drift, sqlite3_flutter_libs, path_provider, shared_preferences, flutter_secure_storage, http)
- [ ] Create feature-based directory structure for home, tasks, notes, settings features and core services
- [ ] Create Task, Note, Statistics, and SyncStatus data models
- [ ] Create Drift database with tasks and notes tables, define schemas and DAOs
- [ ] Implement StorageService, SecureStorageService, and CacheService
- [ ] Implement mock ApiService for network operations using http package
- [ ] Create AppRouter with GoRouter, BottomNavigationProvider, NavigationItems, and AppBottomNavigation widget
- [ ] Create MainNavigationScreen that wraps bottom navigation and manages tab switching
- [ ] Create placeholder TasksScreen, NotesScreen, and SettingsScreen with basic structure
- [ ] Implement HomeViewModel with statistics management, sync operations, and network status
- [ ] Implement StatisticsService and SyncService for Home screen functionality
- [ ] Implement HomeScreen UI with statistics cards, quick actions, activity feed, and sync status
- [ ] Create reusable widgets for Home screen (StatisticsCard, QuickActionButton, ActivityFeedItem, SyncStatusWidget)
- [ ] Update main.dart to use GoRouter and MainNavigationScreen
- [ ] Verify project builds, navigation works, Home screen displays correctly with real data, and all foundation components integrated