/// Configuration for input/output size limits
/// 
/// Controls the maximum sizes for various types of data to prevent
/// resource exhaustion and DoS attacks.
class SizeLimitsConfig {
  /// Creates a size limits configuration
  /// 
  /// [maxParameterSize] - Maximum size for tool/request parameters (default: 1MB)
  /// [maxResultSize] - Maximum size for tool results (default: 10MB)
  /// [maxResourceSize] - Maximum size for resource content (default: 50MB)
  /// [maxMessageSize] - Maximum size for JSON-RPC messages (default: 2MB)
  const SizeLimitsConfig({
    this.maxParameterSize = 1024 * 1024, // 1MB
    this.maxResultSize = 10 * 1024 * 1024, // 10MB
    this.maxResourceSize = 50 * 1024 * 1024, // 50MB
    this.maxMessageSize = 2 * 1024 * 1024, // 2MB
  });

  /// Maximum size for tool/request parameters in bytes
  final int maxParameterSize;

  /// Maximum size for tool results in bytes
  final int maxResultSize;

  /// Maximum size for resource content in bytes
  final int maxResourceSize;

  /// Maximum size for JSON-RPC messages in bytes
  final int maxMessageSize;

  SizeLimitsConfig copyWith({
    int? maxParameterSize,
    int? maxResultSize,
    int? maxResourceSize,
    int? maxMessageSize,
  }) {
    return SizeLimitsConfig(
      maxParameterSize: maxParameterSize ?? this.maxParameterSize,
      maxResultSize: maxResultSize ?? this.maxResultSize,
      maxResourceSize: maxResourceSize ?? this.maxResourceSize,
      maxMessageSize: maxMessageSize ?? this.maxMessageSize,
    );
  }

  /// Validates the size limits configuration
  /// 
  /// Throws [ArgumentError] if any limit is not positive.
  void validate() {
    if (maxParameterSize <= 0) {
      throw ArgumentError('maxParameterSize must be positive', 'maxParameterSize');
    }
    if (maxResultSize <= 0) {
      throw ArgumentError('maxResultSize must be positive', 'maxResultSize');
    }
    if (maxResourceSize <= 0) {
      throw ArgumentError('maxResourceSize must be positive', 'maxResourceSize');
    }
    if (maxMessageSize <= 0) {
      throw ArgumentError('maxMessageSize must be positive', 'maxMessageSize');
    }

    // Ensure limits are reasonable (parameter size should not exceed message size)
    if (maxParameterSize > maxMessageSize) {
      throw ArgumentError(
        'maxParameterSize ($maxParameterSize) cannot exceed maxMessageSize ($maxMessageSize)',
        'maxParameterSize',
      );
    }
  }
}

