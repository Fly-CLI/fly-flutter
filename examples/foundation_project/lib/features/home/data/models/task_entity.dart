import 'package:foundation_project/core/database/models/base_entity.dart';
import 'package:foundation_project/core/models/sync_status.dart';

/// Task entity for data/persistence layer
/// Extends BaseEntity with persistence concerns (serialization, sync status)
class TaskEntity extends BaseEntity {
  final String title;
  final String? description;
  final String status; // 'active', 'completed', 'overdue'
  final String priority; // 'low', 'medium', 'high'
  final DateTime? dueDate;

  const TaskEntity({
    required super.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required super.createdAt,
    required super.updatedAt,
    super.syncStatus = SyncStatus.pending,
    super.lastSyncedAt,
    super.version = 1,
  });

  @override
  String get tableName => 'tasks';

  @override
  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    int? version,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
    );
  }

  /// Create TaskEntity from database row
  factory TaskEntity.fromMap(Map<String, dynamic> map) {
    return TaskEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status'] as String,
      priority: map['priority'] as String,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncStatus: SyncStatus.fromJson(map['sync_status'] as String?),
      lastSyncedAt: map['last_synced_at'] != null
          ? DateTime.parse(map['last_synced_at'] as String)
          : null,
      version: map['version'] as int? ?? 1,
    );
  }

  /// Convert TaskEntity to database row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus.name,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'version': version,
    };
  }
}

