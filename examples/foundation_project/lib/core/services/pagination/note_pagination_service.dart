import 'package:foundation_project/core/foundation/operations/result.dart';
import 'package:foundation_project/core/foundation/utils/app_logger.dart';
import 'package:foundation_project/core/pagination/paginated_result.dart';
import 'package:foundation_project/core/repositories/note_repository.dart';
import 'package:foundation_project/features/home/domain/models/note.dart';

/// Pagination service for notes
class NotePaginationService {
  final NoteRepository _noteRepository;
  final AppLogger _logger = AppLogger('NotePaginationService');

  NotePaginationService(this._noteRepository);

  /// Get paginated notes
  Future<AppResult<PaginatedResult<Note>>> getPaginated({
    required int page,
    required int pageSize,
    String? searchQuery,
    bool? favoriteFilter,
  }) async {
    try {
      // Get all notes or filtered notes
      final notesResult = searchQuery != null
          ? await _noteRepository.searchNotes(searchQuery)
          : favoriteFilter == true
              ? await _noteRepository.getFavoriteNotes()
              : await _noteRepository.getAllNotes();

      if (notesResult.isFailure) {
        return Failure(
          'Failed to get notes: ${notesResult.error}',
          notesResult.data,
        );
      }

      final allNotes = notesResult.data ?? [];

      // Calculate pagination
      final total = allNotes.length;
      final start = page * pageSize;
      final end = (start + pageSize).clamp(0, total);
      final paginatedNotes = allNotes.sublist(
        start.clamp(0, total),
        end,
      );

      final result = PaginatedResult<Note>.fromItems(
        items: paginatedNotes,
        total: total,
        page: page,
        pageSize: pageSize,
      );

      return Success(result);
    } catch (e) {
      _logger.error('Failed to get paginated notes: ${e.toString()}', stackTrace: StackTrace.current);
      return Failure('Failed to get paginated notes: ${e.toString()}', e);
    }
  }
}

