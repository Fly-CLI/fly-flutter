import 'dart:async';
import 'dart:convert';

import 'model.dart';
import 'stdio_transport.dart';

typedef RequestHandler = FutureOr<Object?> Function(JsonRpcRequest request);
typedef NotificationHandler = void Function(String method, Object? params);

class JsonRpcConnection {
  final StdioTransport transport;
  final int maxMessageBytes;

  JsonRpcConnection(this.transport, {this.maxMessageBytes = 2 * 1024 * 1024});

  Future<void> start({
    required RequestHandler handleRequest,
    NotificationHandler? handleNotify,
  }) async {
    await for (final frame in transport.framedInput(maxMessageBytes: maxMessageBytes)) {
      Map<String, Object?> decoded;
      try {
        decoded = jsonDecode(frame) as Map<String, Object?>;
      } catch (e) {
        // Not a valid JSON object; ignore silently to be robust.
        continue;
      }

      if (decoded['method'] != null && decoded['id'] != null) {
        final request = JsonRpcRequest.fromJson(decoded);
        try {
          final result = await handleRequest(request);
          final response = JsonRpcResponse(id: request.id, result: result);
          await transport.send(jsonEncode(response.toJson()));
        } catch (e) {
          final error = JsonRpcError(code: -32603, message: 'Internal error', data: e.toString());
          final response = JsonRpcResponse(id: request.id, error: error);
          await transport.send(jsonEncode(response.toJson()));
        }
      } else if (decoded['method'] != null && decoded['id'] == null) {
        // Notification - handle $/cancelRequest specially
        final method = decoded['method'] as String;
        if (method == '\$/cancelRequest') {
          // Treat cancellation notification as a request for proper handling
          final cancelReq = JsonRpcRequest.fromJson({
            ...decoded,
            'id': 'cancel_${DateTime.now().microsecondsSinceEpoch}', // Generate temp ID
          });
          try {
            await handleRequest(cancelReq);
          } catch (_) {
            // Cancellation doesn't need response
          }
        } else {
          handleNotify?.call(method, decoded['params']);
        }
      } else if (decoded['id'] != null) {
        // Response from peer: ignore in server mode
      }
    }
  }
}

