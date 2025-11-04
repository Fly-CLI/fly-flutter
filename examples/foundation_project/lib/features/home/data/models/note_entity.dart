import 'dart:convert';

import 'package:foundation_project/core/models/base/base_entity.dart';
import 'package:foundation_project/core/models/base/sync_status.dart';

/// Note entity for data/persistence layer
/// Extends BaseEntity with persistence concerns (serialization, sync status)
class NoteEntity extends BaseEntity {
  final String title;
  final String content;
  final List<String> tags;
  final bool isFavorite;

  const NoteEntity({
    required super.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.isFavorite = false,
    required super.createdAt,
    required super.updatedAt,
    super.syncStatus = SyncStatus.pending,
    super.lastSyncedAt,
    super.version = 1,
  });

  @override
  String get tableName => 'notes';

  @override
  NoteEntity copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    int? version,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
    );
  }

  /// Create NoteEntity from database row
  factory NoteEntity.fromMap(Map<String, dynamic> map) {
    List<String> tagsList = [];
    if (map['tags'] != null) {
      try {
        final decoded = jsonDecode(map['tags'] as String);
        if (decoded is List) {
          tagsList = decoded.cast<String>();
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return NoteEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      tags: tagsList,
      isFavorite: (map['is_favorite'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncStatus: SyncStatus.fromJson(map['sync_status'] as String?),
      lastSyncedAt: map['last_synced_at'] != null
          ? DateTime.parse(map['last_synced_at'] as String)
          : null,
      version: map['version'] as int? ?? 1,
    );
  }

  /// Convert NoteEntity to database row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags.isNotEmpty ? jsonEncode(tags) : null,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus.name,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'version': version,
    };
  }
}

