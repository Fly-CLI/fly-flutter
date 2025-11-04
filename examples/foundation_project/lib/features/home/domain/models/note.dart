/// Domain model for Note - pure business entity without persistence concerns
/// 
/// This is the core business model that represents a note in the domain.
/// It contains only business logic properties and has no knowledge of
/// databases, serialization, or UI concerns.
class Note {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this note with updated fields
  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if note has any tags
  bool get hasTags => tags.isNotEmpty;

  /// Get the number of tags
  int get tagCount => tags.length;

  /// Get a preview of the content (first 100 characters)
  String get contentPreview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.tags.toString() == tags.toString() &&
        other.isFavorite == isFavorite &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      tags,
      isFavorite,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, content: $contentPreview, tags: $tags, isFavorite: $isFavorite)';
  }
}

