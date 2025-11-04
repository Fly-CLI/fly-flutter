/// Standardized paginated result model
///
/// This model represents a paginated result with items, total count,
/// pagination metadata, and a flag indicating if there are more items.
class PaginatedResult<T> {
  /// The paginated items
  final List<T> items;

  /// Total number of items across all pages
  final int total;

  /// Current page number (0-based)
  final int page;

  /// Number of items per page
  final int pageSize;

  /// Whether there are more items to load
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  /// Create an empty paginated result
  factory PaginatedResult.empty({
    int page = 0,
    int pageSize = 20,
  }) {
    return PaginatedResult<T>(
      items: const [],
      total: 0,
      page: page,
      pageSize: pageSize,
      hasMore: false,
    );
  }

  /// Create a paginated result with items
  factory PaginatedResult.fromItems({
    required List<T> items,
    required int total,
    int page = 0,
    int pageSize = 20,
  }) {
    return PaginatedResult<T>(
      items: items,
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: (page + 1) * pageSize < total,
    );
  }

  /// Get the number of pages
  int get totalPages => (total / pageSize).ceil();

  /// Check if this is the first page
  bool get isFirstPage => page == 0;

  /// Check if this is the last page
  bool get isLastPage => !hasMore;

  /// Get the next page number
  int get nextPage => page + 1;

  /// Get the previous page number
  int? get previousPage => page > 0 ? page - 1 : null;

  /// Copy with new values
  PaginatedResult<T> copyWith({
    List<T>? items,
    int? total,
    int? page,
    int? pageSize,
    bool? hasMore,
  }) {
    return PaginatedResult<T>(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  String toString() {
    return 'PaginatedResult(items: ${items.length}, total: $total, page: $page, pageSize: $pageSize, hasMore: $hasMore)';
  }
}

