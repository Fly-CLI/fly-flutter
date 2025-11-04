import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:foundation_project/core/database/daos/notes_dao.dart';
import 'package:foundation_project/core/database/daos/tasks_dao.dart';
import 'package:foundation_project/core/database/tables/notes_table.dart';
import 'package:foundation_project/core/database/tables/tasks_table.dart';

part 'app_database.g.dart';

/// Main application database
@DriftDatabase(tables: [Tasks, Notes], daos: [TasksDao, NotesDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations here
      },
    );
  }
}

/// Open database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase(file);
  });
}

