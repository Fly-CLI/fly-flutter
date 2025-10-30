import 'package:fly_mcp_server/src/domain/resource_strategy.dart';
import 'package:fly_mcp_server/src/log_resource_provider.dart';

/// Strategy for logs://build/* resources
class LogsBuildResourceStrategy extends ResourceStrategy {
  LogsBuildResourceStrategy({LogResourceProvider? logProvider})
      : _logProvider = logProvider;

  @override
  String get uriPrefix => 'logs://build/';

  @override
  String get description => 'Build logs from compilation processes';

  @override
  bool get readOnly => true;

  /// Reference to the log provider (injected via constructor or setter)
  LogResourceProvider? _logProvider;

  /// Set the log provider for this strategy
  void setLogProvider(LogResourceProvider provider) {
    _logProvider = provider;
  }

  /// Get the log provider for this strategy
  LogResourceProvider? get logProvider => _logProvider;

  @override
  Map<String, Object?> list(Map<String, Object?> params) {
    if (_logProvider == null) {
      throw StateError('LogResourceProvider not configured');
    }

    final uriPrefixParam = params['uri'] as String?;
    
    // Extract build ID prefix from URI if provided
    // listLogs expects prefix to match build ID, not full URI
    String? prefix;
    if (uriPrefixParam != null && uriPrefixParam.startsWith('logs://build/')) {
      // Extract the build ID part after 'logs://build/'
      final buildIdPart = uriPrefixParam.replaceFirst('logs://build/', '');
      prefix = buildIdPart.isEmpty ? null : buildIdPart;
    } else {
      // No URI prefix means list all build logs
      prefix = null;
    }

    return _logProvider!.listLogs(
      prefix: prefix,
      page: params['page'] as int?,
      pageSize: params['pageSize'] as int?,
    );
  }

  @override
  Map<String, Object?> read(Map<String, Object?> params) {
    if (_logProvider == null) {
      throw StateError('LogResourceProvider not configured');
    }

    final uri = params['uri'] as String?;
    if (uri == null || !uri.startsWith('logs://build/')) {
      throw StateError('Invalid or missing uri');
    }

    return _logProvider!.readLog(
      uri,
      start: params['start'] as int?,
      length: params['length'] as int?,
    );
  }
}

