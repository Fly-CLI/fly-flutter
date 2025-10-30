import 'dart:async';

import 'package:dart_mcp/server.dart';

/// Progress notification sender for MCP tools
/// 
/// This class wraps dart_mcp's progress notification system.
/// It can be created from a request that has a progress token.
class ProgressNotifier {
  final MCPServer? _server;
  final ProgressToken? _progressToken;
  final bool _enabled;

  /// Creates a progress notifier from an MCP server and progress token
  /// 
  /// [server] - The MCP server instance (optional, for sending progress)
  /// [progressToken] - The progress token from the request (optional)
  /// [enabled] - Whether progress notifications are enabled
  ProgressNotifier({
    MCPServer? server,
    ProgressToken? progressToken,
    bool enabled = false,
  })  : _server = server,
        _progressToken = progressToken,
        _enabled = enabled;

  /// Send a progress notification
  /// 
  /// [message] - Progress message
  /// [percent] - Progress percentage (0-100, optional)
  Future<void> notify({
    required String message,
    int? percent,
  }) async {
    if (!_enabled || _server == null || _progressToken == null) {
      return;
    }

    // Calculate total if percent is provided (assume 100 as max)
    final total = percent != null ? 100 : null;
    final progressValue = percent != null ? percent.toDouble() : 0.0;

    _server.notifyProgress(ProgressNotification(
      progressToken: _progressToken!,
      progress: progressValue,
      total: total?.toDouble(),
      message: message,
    ));
  }
}

