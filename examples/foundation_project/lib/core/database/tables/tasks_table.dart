import 'package:drift/drift.dart';

/// Tasks table definition with sync metadata
@DataClassName('TaskData')
class Tasks extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Task title
  TextColumn get title => text()();

  /// Task description
  TextColumn get description => text().nullable()();

  /// Task status: 'active', 'completed', 'overdue'
  TextColumn get status => text()();

  /// Task priority: 'low', 'medium', 'high'
  TextColumn get priority => text()();

  /// Task due date
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Created timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Updated timestamp
  DateTimeColumn get updatedAt => dateTime()();

  /// Sync metadata - sync status
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  /// Sync metadata - last synced timestamp
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  /// Sync metadata - version
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

