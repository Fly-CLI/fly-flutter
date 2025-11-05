import 'package:drift/drift.dart';
import 'package:foundation_project/core/database/app_database.dart';
import 'package:foundation_project/core/database/daos/notes_dao.dart';
import 'package:foundation_project/core/foundation/operations/result.dart';
import 'package:foundation_project/core/models/sync_status.dart';
import 'package:foundation_project/core/repositories/base/base_repository.dart';
import 'package:foundation_project/features/home/mappers/home_mappr.dart';
import 'package:foundation_project/features/home/data/models/note_entity.dart';
import 'package:foundation_project/features/home/domain/models/note.dart';

/// Note repository implementation
/// Works with domain Note models in public API, but uses NoteEntity for persistence
/// Does not implement IBaseRepository to avoid type conflicts with domain models
class NoteRepository extends BaseRepository<NoteEntity> {
  final AppDatabase _database;
  late final NotesDao _dao;
  final HomeMappr _mappr = HomeMappr();

  NoteRepository(this._database)
      : _dao = NotesDao(_database),
        super(
          tableName: 'notes',
          fromMap: (map) => NoteEntity.fromMap(map),
          toMap: (note) => note.toMap(),
        );

  // =========================================================================
  // DOMAIN MODEL METHODS (Public API - returns domain models)
  // =========================================================================

  /// Get all notes as domain models
  /// Note: This method returns domain models, not entities
  Future<AppResult<List<Note>>> getAllNotes() async {
    try {
      final notesData = await _dao.getAllNotes();
      final entities = notesData.map((data) => _mapNoteDataToEntity(data)).toList();
      final domainNotes = _mappr.convertList<NoteEntity, Note>(entities);
      return Success(domainNotes);
    } catch (e) {
      return Failure('Failed to getAllNotes: ${e.toString()}', e);
    }
  }

  /// Get note by ID as domain model
  Future<AppResult<Note?>> getNoteById(String id) async {
    try {
      final noteData = await _dao.getNoteById(id);
      if (noteData == null) return Success(null);
      final entity = _mapNoteDataToEntity(noteData);
      final domainNote = _mappr.convert<NoteEntity, Note>(entity);
      return Success(domainNote);
    } catch (e) {
      return Failure('Failed to getNoteById: ${e.toString()}', e);
    }
  }

  // =========================================================================
  // INTERFACE METHODS (Required by IBaseRepository - returns entities)
  // =========================================================================

  @override
  Future<AppResult<List<NoteEntity>>> getAll() async {
    try {
      final notesData = await _dao.getAllNotes();
      final entities = notesData.map((data) => _mapNoteDataToEntity(data)).toList();
      return Success(entities);
    } catch (e) {
      return handleListError(e, 'getAll');
    }
  }

  @override
  Future<AppResult<NoteEntity?>> getById(String id) async {
    try {
      final noteData = await _dao.getNoteById(id);
      if (noteData == null) return Success(null);
      final entity = _mapNoteDataToEntity(noteData);
      return Success(entity);
    } catch (e) {
      return handleError(e, 'getById');
    }
  }

  @override
  Future<AppResult<NoteEntity>> create(NoteEntity entity) async {
    return await super.create(entity);
  }

  /// Create note from domain model
  Future<AppResult<Note>> createNote(Note note) async {
    final entity = _mappr.convert<Note, NoteEntity>(note);
    final result = await super.create(entity);
    if (result.isFailure) {
      final originalError = result is Failure<NoteEntity> ? result.originalError : null;
      return Failure(result.error!, originalError);
    }
    return Success(_mappr.convert<NoteEntity, Note>(result.data!));
  }

  @override
  Future<AppResult<NoteEntity>> performCreate(NoteEntity entity) async {
    try {
      final validation = validateEntity(entity);
      if (validation.isFailure) return validation;

      final noteData = _mapEntityToNoteData(entity);
      await _dao.insertNote(noteData);
      return Success(entity);
    } catch (e) {
      return handleError(e, 'create');
    }
  }

  @override
  Future<AppResult<NoteEntity>> update(NoteEntity entity) async {
    return await super.update(entity);
  }

  /// Update note from domain model
  Future<AppResult<Note>> updateNote(Note note) async {
    final entity = _mappr.convert<Note, NoteEntity>(note).copyWith(
      syncStatus: SyncStatus.pending,
    );
    final result = await super.update(entity);
    if (result.isFailure) {
      final originalError = result is Failure<NoteEntity> ? result.originalError : null;
      return Failure(result.error!, originalError);
    }
    return Success(_mappr.convert<NoteEntity, Note>(result.data!));
  }

  @override
  Future<AppResult<NoteEntity>> performUpdate(NoteEntity entity) async {
    try {
      final validation = validateEntity(entity);
      if (validation.isFailure) return validation;

      final noteData = _mapEntityToNoteData(entity.copyWith(
        updatedAt: DateTime.now(),
      ));
      await _dao.updateNote(noteData);
      return Success(entity.copyWith(updatedAt: DateTime.now()));
    } catch (e) {
      return handleError(e, 'update');
    }
  }

  /// Delete note by ID (domain model API)
  Future<AppResult<bool>> deleteNote(String id) async {
    return await super.delete(id);
  }

  @override
  Future<AppResult<bool>> performDelete(String id) async {
    try {
      final count = await _dao.deleteNote(id);
      return Success(count > 0);
    } catch (e) {
      return handleBooleanError(e, 'delete');
    }
  }

  @override
  Future<AppResult<List<NoteEntity>>> search(String query) async {
    try {
      final allNotes = await _dao.getAllNotes();
      final filtered = allNotes
          .where((note) {
            final titleMatch = note.title.toLowerCase().contains(query.toLowerCase());
            final contentMatch = note.content.toLowerCase().contains(query.toLowerCase());
            return titleMatch || contentMatch;
          })
          .toList();
      final entities = filtered.map((data) => _mapNoteDataToEntity(data)).toList();
      return Success(entities);
    } catch (e) {
      return handleListError(e, 'search');
    }
  }

  /// Search notes by query (domain model API)
  Future<AppResult<List<Note>>> searchNotes(String query) async {
    try {
      final allNotes = await _dao.getAllNotes();
      final filtered = allNotes
          .where((note) {
            final titleMatch = note.title.toLowerCase().contains(query.toLowerCase());
            final contentMatch = note.content.toLowerCase().contains(query.toLowerCase());
            return titleMatch || contentMatch;
          })
          .toList();
      final entities = filtered.map((data) => _mapNoteDataToEntity(data)).toList();
      final domainNotes = _mappr.convertList<NoteEntity, Note>(entities);
      return Success(domainNotes);
    } catch (e) {
      return Failure('Failed to searchNotes: ${e.toString()}', e);
    }
  }

  @override
  Future<AppResult<List<NoteEntity>>> getPendingSync() async {
    try {
      final notesData = await _dao.getPendingSyncNotes();
      final entities = notesData.map((data) => _mapNoteDataToEntity(data)).toList();
      return Success(entities);
    } catch (e) {
      return handleListError(e, 'getPendingSync');
    }
  }

  /// Get notes that need synchronization (domain model API)
  Future<AppResult<List<Note>>> getPendingSyncNotes() async {
    try {
      final notesData = await _dao.getPendingSyncNotes();
      final entities = notesData.map((data) => _mapNoteDataToEntity(data)).toList();
      final domainNotes = _mappr.convertList<NoteEntity, Note>(entities);
      return Success(domainNotes);
    } catch (e) {
      return Failure('Failed to getPendingSyncNotes: ${e.toString()}', e);
    }
  }

  @override
  Future<AppResult<void>> markAsSynced(String id, DateTime syncedAt) async {
    try {
      final entityResult = await getById(id);
      if (entityResult.isFailure || entityResult.data == null) {
        return Failure('Note not found');
      }

      final entity = entityResult.data!;
      final updatedEntity = entity.markAsSynced() as NoteEntity;
      await performUpdate(updatedEntity);
      return Success(null);
    } catch (e) {
      return handleVoidError(e, 'markAsSynced');
    }
  }

  @override
  Future<AppResult<void>> markAsConflicted(String id) async {
    try {
      final entityResult = await getById(id);
      if (entityResult.isFailure || entityResult.data == null) {
        return Failure('Note not found');
      }

      final entity = entityResult.data!;
      final updatedEntity = entity.markAsConflicted() as NoteEntity;
      await performUpdate(updatedEntity);
      return Success(null);
    } catch (e) {
      return handleVoidError(e, 'markAsConflicted');
    }
  }

  @override
  Future<AppResult<void>> markAsFailed(String id, String errorMessage) async {
    try {
      final entityResult = await getById(id);
      if (entityResult.isFailure || entityResult.data == null) {
        return Failure('Note not found');
      }

      final entity = entityResult.data!;
      final updatedEntity = entity.markAsFailed() as NoteEntity;
      await performUpdate(updatedEntity);
      return Success(null);
    } catch (e) {
      return handleVoidError(e, 'markAsFailed');
    }
  }

  /// Get favorite notes (domain model API)
  Future<AppResult<List<Note>>> getFavoriteNotes() async {
    try {
      final notesData = await _dao.getFavoriteNotes();
      final entities = notesData.map((data) => _mapNoteDataToEntity(data)).toList();
      final domainNotes = _mappr.convertList<NoteEntity, Note>(entities);
      return Success(domainNotes);
    } catch (e) {
      return Failure('Failed to getFavoriteNotes: ${e.toString()}', e);
    }
  }

  /// Map NoteData to NoteEntity
  NoteEntity _mapNoteDataToEntity(NoteData data) {
    return NoteEntity.fromMap({
      'id': data.id,
      'title': data.title,
      'content': data.content,
      'tags': data.tags,
      'is_favorite': data.isFavorite ? 1 : 0,
      'created_at': data.createdAt.toIso8601String(),
      'updated_at': data.updatedAt.toIso8601String(),
      'sync_status': data.syncStatus,
      'last_synced_at': data.lastSyncedAt?.toIso8601String(),
      'version': data.version,
    });
  }

  /// Map NoteEntity to NotesCompanion
  NotesCompanion _mapEntityToNoteData(NoteEntity entity) {
    return NotesCompanion.insert(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      tags: Value(entity.tags.isNotEmpty ? entity.tags.join(',') : null),
      isFavorite: Value(entity.isFavorite),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      syncStatus: Value(entity.syncStatus.name),
      lastSyncedAt: Value(entity.lastSyncedAt),
      version: Value(entity.version),
    );
  }
}

