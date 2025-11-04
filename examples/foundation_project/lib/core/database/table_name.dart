/// Database table names enum
///
/// Provides type-safe table name references for all database tables
enum TableName {
  /// Tasks table
  tasks('tasks'),

  /// Notes table
  notes('notes');

  const TableName(this.value);

  /// The actual database table name string
  final String value;

  @override
  String toString() => value;
}

