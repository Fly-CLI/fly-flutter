import 'package:drift/drift.dart';
import 'package:foundation_project/core/database/app_database.dart';
import 'package:foundation_project/core/database/tables/notes_table.dart';

part 'notes_dao.g.dart';

/// Data Access Object for Notes table
@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(AppDatabase db) : super(db);

  /// Get all notes
  Future<List<NoteData>> getAllNotes() {
    return select(notes).get();
  }

  /// Get note by ID
  Future<NoteData?> getNoteById(String id) {
    return (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();
  }

  /// Insert note
  Future<void> insertNote(NotesCompanion note) {
    return into(notes).insert(note);
  }

  /// Update note
  Future<bool> updateNote(NotesCompanion note) {
    return update(notes).replace(note);
  }

  /// Delete note
  Future<int> deleteNote(String id) {
    return (delete(notes)..where((n) => n.id.equals(id))).go();
  }

  /// Get favorite notes
  Future<List<NoteData>> getFavoriteNotes() {
    return (select(notes)..where((n) => n.isFavorite.equals(true))).get();
  }

  /// Get pending sync notes
  Future<List<NoteData>> getPendingSyncNotes() {
    return (select(notes)
          ..where((n) => n.syncStatus.equals('pending')))
        .get();
  }
}

