import 'dart:convert';

/// JSON-RPC 2.0 base message types
abstract class JsonRpcMessage {
  const JsonRpcMessage();
}

class JsonRpcRequest extends JsonRpcMessage {
  final String jsonrpc;
  final Object id; // numeric or string ids per spec
  final String method;
  final Object? params;

  const JsonRpcRequest({
    this.jsonrpc = '2.0',
    required this.id,
    required this.method,
    this.params,
  });

  Map<String, Object?> toJson() => {
        'jsonrpc': jsonrpc,
        'id': id,
        'method': method,
        if (params != null) 'params': params,
      };

  static JsonRpcRequest fromJson(Map<String, Object?> map) {
    return JsonRpcRequest(
      id: map['id'] as Object,
      method: map['method'] as String,
      params: map['params'],
    );
  }
}

class JsonRpcError {
  final int code;
  final String message;
  final Object? data;

  const JsonRpcError({required this.code, required this.message, this.data});

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  static JsonRpcError fromJson(Map<String, Object?> map) {
    return JsonRpcError(
      code: map['code'] as int,
      message: map['message'] as String,
      data: map['data'],
    );
  }
}

class JsonRpcResponse extends JsonRpcMessage {
  final String jsonrpc;
  final Object id;
  final Object? result;
  final JsonRpcError? error;

  const JsonRpcResponse({
    this.jsonrpc = '2.0',
    required this.id,
    this.result,
    this.error,
  });

  Map<String, Object?> toJson() => {
        'jsonrpc': jsonrpc,
        'id': id,
        if (result != null) 'result': result,
        if (error != null) 'error': error!.toJson(),
      };

  static JsonRpcResponse fromJson(Map<String, Object?> map) {
    return JsonRpcResponse(
      id: map['id'] as Object,
      result: map['result'],
      error: map['error'] == null
          ? null
          : JsonRpcError.fromJson(
              (map['error'] as Map).cast<String, Object?>(),
            ),
    );
  }
}

String encodeJson(Object obj) => jsonEncode(obj);

T decodeJson<T>(String source) => jsonDecode(source) as T;

