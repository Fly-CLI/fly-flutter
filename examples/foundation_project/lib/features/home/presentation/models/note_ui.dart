import 'package:foundation_project/features/home/domain/models/note.dart';

/// Presentation model for Note - UI-specific model
/// 
/// This model is used in the presentation layer (ViewModels, widgets)
/// and contains UI-specific concerns like formatting, display logic, etc.
class NoteUi {
  final Note note;
  final bool isSelected;
  final String formattedCreatedAt;
  final String formattedUpdatedAt;
  final String displayTitle;
  final String displayContent;

  const NoteUi({
    required this.note,
    this.isSelected = false,
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.displayTitle,
    required this.displayContent,
  });

  /// Create NoteUi from domain Note
  factory NoteUi.fromDomain(Note note, {bool isSelected = false}) {
    return NoteUi(
      note: note,
      isSelected: isSelected,
      formattedCreatedAt: _formatDate(note.createdAt),
      formattedUpdatedAt: _formatDate(note.updatedAt),
      displayTitle: note.title.isEmpty ? 'Untitled' : note.title,
      displayContent: note.content.isEmpty ? 'No content' : note.content,
    );
  }

  /// Create NoteUi with updated selection state
  NoteUi copyWith({
    Note? note,
    bool? isSelected,
    String? formattedCreatedAt,
    String? formattedUpdatedAt,
    String? displayTitle,
    String? displayContent,
  }) {
    return NoteUi(
      note: note ?? this.note,
      isSelected: isSelected ?? this.isSelected,
      formattedCreatedAt: formattedCreatedAt ?? this.formattedCreatedAt,
      formattedUpdatedAt: formattedUpdatedAt ?? this.formattedUpdatedAt,
      displayTitle: displayTitle ?? this.displayTitle,
      displayContent: displayContent ?? this.displayContent,
    );
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Get display tags as a string
  String get displayTags => note.tags.join(', ');

  /// Check if note has tags
  bool get hasTags => note.hasTags;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteUi &&
        other.note == note &&
        other.isSelected == isSelected;
  }

  @override
  int get hashCode => Object.hash(note, isSelected);

  @override
  String toString() {
    return 'NoteUi(note: ${note.id}, isSelected: $isSelected, title: $displayTitle)';
  }
}

