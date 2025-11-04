import 'package:drift/drift.dart';

/// Notes table definition with sync metadata
@DataClassName('NoteData')
class Notes extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Note title
  TextColumn get title => text()();

  /// Note content
  TextColumn get content => text()();

  /// Note tags (JSON array)
  TextColumn get tags => text().nullable()();

  /// Is favorite
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();

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

