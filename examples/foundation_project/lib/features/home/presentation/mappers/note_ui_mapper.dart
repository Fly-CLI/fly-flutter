import 'package:foundation_project/core/mappers/base_mapper.dart';
import 'package:foundation_project/features/home/domain/models/note.dart';
import 'package:foundation_project/features/home/presentation/models/note_ui.dart';

/// Mapper for converting between domain and presentation models for Note
/// 
/// Extends BaseMapper for reusable mapping functionality
class NoteUiMapper extends BaseMapper<Note, NoteUi> {
  /// Singleton instance for instance-based usage
  static final NoteUiMapper instance = NoteUiMapper._();

  NoteUiMapper._();

  @override
  NoteUi toTarget(Note source, {Map<String, dynamic>? options}) {
    final isSelected = options?['isSelected'] as bool? ?? false;
    return NoteUi.fromDomain(source, isSelected: isSelected);
  }

  @override
  Note toSource(NoteUi target, {Map<String, dynamic>? options}) {
    return target.note;
  }
}

