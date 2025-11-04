import 'package:foundation_project/core/models/base/sync_status.dart';
import 'package:foundation_project/core/mappers/base_mapper.dart';
import 'package:foundation_project/features/home/data/models/note_entity.dart';
import 'package:foundation_project/features/home/domain/models/note.dart';

/// Mapper for converting between domain and data models for Note
/// 
/// Extends BaseMapper for reusable mapping functionality
class NoteMapper extends BaseMapper<Note, NoteEntity> {
  /// Singleton instance for instance-based usage
  static final NoteMapper instance = NoteMapper._();

  NoteMapper._();

  @override
  NoteEntity toTarget(Note source, {Map<String, dynamic>? options}) {
    final syncStatus = options?['syncStatus'] as SyncStatus? ?? SyncStatus.pending;
    final lastSyncedAt = options?['lastSyncedAt'] as DateTime?;
    final version = options?['version'] as int? ?? 1;

    return NoteEntity(
      id: source.id,
      title: source.title,
      content: source.content,
      tags: source.tags,
      isFavorite: source.isFavorite,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
      syncStatus: syncStatus,
      lastSyncedAt: lastSyncedAt,
      version: version,
    );
  }

  @override
  Note toSource(NoteEntity target, {Map<String, dynamic>? options}) {
    return Note(
      id: target.id,
      title: target.title,
      content: target.content,
      tags: target.tags,
      isFavorite: target.isFavorite,
      createdAt: target.createdAt,
      updatedAt: target.updatedAt,
    );
  }
}

