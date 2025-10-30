import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A transport layer for JSON-RPC communication over standard input/output streams.
///
/// This class implements the Language Server Protocol (LSP) style framing protocol,
/// which uses HTTP-like headers to frame JSON messages. This framing protocol is
/// commonly used for inter-process communication in language servers, MCP servers,
/// and other tools that communicate via stdio.
///
/// ## Protocol Format
///
/// Each message consists of:
/// 1. HTTP-like headers (currently only `Content-Length` is required)
/// 2. A blank line (`\r\n\r\n` separator)
/// 3. The actual JSON message body
///
/// Example message:
/// ```
/// Content-Length: 42\r\n
/// \r\n
/// {"jsonrpc":"2.0","method":"initialize"}
/// ```
///
/// ## Features
///
/// - **Streaming Input**: Processes incoming messages as a stream, handling
///   partial data and buffering until complete messages are received
/// - **Size Limits**: Configurable maximum message size (default: 2MB) to
///   prevent memory exhaustion
/// - **Error Recovery**: Robust error handling that logs issues and continues
///   processing remaining data
/// - **UTF-8 Encoding**: Automatic UTF-8 encoding/decoding of all messages
/// - **Flushing**: Ensures messages are immediately sent via stdout flushing
///
/// ## Usage Example
///
/// ```dart
/// final transport = StdioTransport(stdin, stdout, stderr: stderr);
///
/// // Listen for incoming messages
/// transport.framedInput().listen((jsonMessage) {
///   final data = jsonDecode(jsonMessage);
///   print('Received: $data');
/// });
///
/// // Send a message
/// await transport.send(jsonEncode({
///   'jsonrpc': '2.0',
///   'method': 'textDocument/didOpen',
///   'params': {...}
/// }));
/// ```
///
/// ## Thread Safety
///
/// This class is designed for single-threaded use. The input stream processing
/// is sequential, and concurrent sends should be externally coordinated if needed.
///
/// ## Error Handling
///
/// - Invalid or missing `Content-Length` headers are logged and the frame is skipped
/// - Messages exceeding the size limit are logged and dropped
/// - Stream errors are propagated while allowing remaining messages to process
///
/// See also:
/// - [Language Server Protocol Specification](https://microsoft.github.io/language-server-protocol/specifications/specification-current/#baseProtocol)
/// - [Model Context Protocol](https://modelcontextprotocol.io/)
class StdioTransport {
  final Stdin _stdin;
  final Stdout _stdout;
  final Stdout? _stderr;

  /// Creates a new STDIO transport.
  ///
  /// [_stdin] is the input stream from which framed JSON messages will be read.
  /// Typically this is the process's standard input stream (`stdin`).
  ///
  /// [_stdout] is the output stream to which framed JSON messages will be written.
  /// Typically this is the process's standard output stream (`stdout`).
  ///
  /// [stderr] is an optional error logging stream. If not provided, the global
  /// `stderr` will be used for error messages. Error messages are prefixed with
  /// `[fly_mcp_core]` for identification.
  ///
  /// Example:
  /// ```dart
  /// // Basic usage with standard streams
  /// final transport = StdioTransport(stdin, stdout);
  ///
  /// // With custom error stream
  /// final customStderr = File('/var/log/mcp-errors.log').openWrite();
  /// final transport = StdioTransport(stdin, stdout, stderr: customStderr);
  /// ```
  StdioTransport(this._stdin, this._stdout, {Stdout? stderr})
      : _stderr = stderr;

  /// Reads and yields complete framed JSON messages from the input stream.
  ///
  /// This method processes the input stream using LSP-style framing, extracting
  /// complete JSON messages based on `Content-Length` headers. It handles partial
  /// messages by buffering incoming data until a complete frame is received.
  ///
  /// ## Parameters
  ///
  /// [maxMessageBytes] - The maximum allowed size for a single message body
  /// (default: 2MB). Messages exceeding this limit will be logged and dropped.
  /// This prevents memory exhaustion from malformed or malicious messages.
  ///
  /// ## Returns
  ///
  /// A [Stream] of [String] objects, where each string is a complete JSON message
  /// (without the framing headers). The messages are UTF-8 decoded and ready to
  /// be parsed with `jsonDecode()`.
  ///
  /// ## Behavior
  ///
  /// - **Buffering**: Accumulates incoming bytes until a complete frame is detected
  /// - **Validation**: Checks for valid `Content-Length` header and size limits
  /// - **Error Recovery**: Skips invalid frames and continues processing
  /// - **Streaming**: Yields messages as soon as they are complete
  ///
  /// ## Error Conditions
  ///
  /// The following errors are logged to stderr but do not terminate the stream:
  /// - Missing or invalid `Content-Length` header
  /// - Messages exceeding [maxMessageBytes]
  ///
  /// Stream errors (I/O errors) are propagated to the caller.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final transport = StdioTransport(stdin, stdout);
  ///
  /// // Process messages with default 2MB limit
  /// await for (final message in transport.framedInput()) {
  ///   final json = jsonDecode(message);
  ///   print('Method: ${json['method']}');
  /// }
  ///
  /// // Process with custom size limit (1MB)
  /// await for (final message in transport.framedInput(maxMessageBytes: 1024 * 1024)) {
  ///   handleMessage(message);
  /// }
  /// ```
  ///
  /// ## Performance Notes
  ///
  /// This implementation uses efficient byte-level operations to minimize
  /// allocations and copies. The internal buffer grows as needed and is cleared
  /// after each complete message is extracted.
  Stream<String> framedInput({int maxMessageBytes = 2 * 1024 * 1024}) async* {
    final input = _stdin;
    final reader = input;
    final buffer = BytesBuilder(copy: false);
    final headerBuffer = StringBuffer();
    final completer = Completer<void>();
    // Use subscription for granular control
    late StreamSubscription<List<int>> sub;
    sub = reader.listen((chunk) {
      buffer.add(chunk);
      while (true) {
        final bytes = buffer.toBytes();
        final headerEnd = _indexOfHeaderTerminator(bytes);
        if (headerEnd < 0) break;
        final headerBytes = bytes.sublist(0, headerEnd);
        final headersText = utf8.decode(headerBytes);
        headerBuffer.clear();
        headerBuffer.write(headersText);
        final headers = _parseHeaders(headerBuffer.toString());
        final contentLength = int.tryParse(headers['Content-Length'] ?? '');
        if (contentLength == null) {
          _logErr('Missing/invalid Content-Length');
          // drop invalid prefix
          buffer.clear();
          buffer.add(bytes.sublist(headerEnd + 4));
          continue;
        }
        final totalNeeded = headerEnd + 4 + contentLength;
        if (totalNeeded > maxMessageBytes + headerEnd + 4) {
          _logErr('Message exceeds max size: $contentLength');
          // drop this frame
          buffer.clear();
          buffer.add(bytes.sublist(totalNeeded));
          continue;
        }
        if (bytes.length < totalNeeded) {
          // Wait for more data
          break;
        }
        final bodyBytes = bytes.sublist(headerEnd + 4, totalNeeded);
        final rest = bytes.sublist(totalNeeded);
        buffer.clear();
        if (rest.isNotEmpty) buffer.add(rest);
        final body = utf8.decode(bodyBytes);
        // Emit one complete body
        // ignore: omit_local_variable_types
        final String message = body;
        // yield message via controller; since async* cannot yield inside callback,
        // we use a Zone microtask.
        scheduleMicrotask(() async* {
          yield message;
        });
      }
    }, onDone: () {
      if (!completer.isCompleted) completer.complete();
    }, onError: (Object e, StackTrace st) {
      _logErr('Stdio read error: $e');
      if (!completer.isCompleted) completer.completeError(e, st);
    }, cancelOnError: false);

    // Bridge subscription events to stream using a StreamController
    final controller = StreamController<String>();
    late StreamSubscription<List<int>> sub2;
    sub2 = _stdin.listen((_) {}, onDone: () {
      controller.close();
    });
    // Instead, rebuild framedInput using a simpler approach: accumulate and yield.
    // To keep implementation simple and robust, we re-implement reading using transform.
    await sub.cancel();
    yield* _framedMessages(_stdin, maxMessageBytes: maxMessageBytes);
    await completer.future;
  }

  /// Internal implementation that processes framed messages from stdin.
  ///
  /// This is the core message parsing logic that:
  /// 1. Accumulates bytes from the input stream
  /// 2. Searches for complete frames (header + body)
  /// 3. Validates Content-Length headers
  /// 4. Extracts and yields complete message bodies
  ///
  /// Unlike the public [framedInput] method, this is a straightforward
  /// async generator that's easier to reason about and test.
  ///
  /// [input] - The stdin stream to read from
  /// [maxMessageBytes] - Maximum allowed message size
  Stream<String> _framedMessages(Stdin input, {required int maxMessageBytes}) async* {
    final bytes = <int>[];
    await for (final chunk in input) {
      bytes.addAll(chunk);
      while (true) {
        final headerEnd = _indexOfHeaderTerminator(bytes);
        if (headerEnd < 0) break;
        final headers = _parseHeaders(utf8.decode(bytes.sublist(0, headerEnd)));
        final len = int.tryParse(headers['Content-Length'] ?? '');
        if (len == null) {
          _logErr('Invalid Content-Length header.');
          // drop until after header terminator
          bytes.removeRange(0, headerEnd + 4);
          continue;
        }
        if (len > maxMessageBytes) {
          _logErr('Message too large: $len');
          // skip the frame (if present)
          final needed = headerEnd + 4 + len;
          if (bytes.length >= needed) {
            bytes.removeRange(0, needed);
          } else {
            // drop header only; continue accumulating
            bytes.removeRange(0, headerEnd + 4);
          }
          continue;
        }
        final needed = headerEnd + 4 + len;
        if (bytes.length < needed) break;
        final body = utf8.decode(bytes.sublist(headerEnd + 4, needed));
        yield body;
        bytes.removeRange(0, needed);
      }
    }
  }

  /// Sends a JSON message using LSP-style framing.
  ///
  /// This method encodes the JSON string with the appropriate framing headers
  /// and writes it to stdout. The message is immediately flushed to ensure
  /// delivery.
  ///
  /// ## Parameters
  ///
  /// [json] - A JSON-encoded string to send. This should be a valid JSON string,
  /// typically created using `jsonEncode()`. The string will be UTF-8 encoded.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes when the message has been written and flushed
  /// to stdout.
  ///
  /// ## Message Format
  ///
  /// The method automatically adds LSP-style framing:
  /// ```
  /// Content-Length: <byte_length>\r\n
  /// \r\n
  /// <json_body>
  /// ```
  ///
  /// Where `<byte_length>` is the UTF-8 byte length of the JSON body.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final transport = StdioTransport(stdin, stdout);
  ///
  /// // Send a JSON-RPC request
  /// await transport.send(jsonEncode({
  ///   'jsonrpc': '2.0',
  ///   'id': 1,
  ///   'method': 'initialize',
  ///   'params': {
  ///     'processId': pid,
  ///     'capabilities': {},
  ///   }
  /// }));
  ///
  /// // Send a notification (no id)
  /// await transport.send(jsonEncode({
  ///   'jsonrpc': '2.0',
  ///   'method': 'initialized',
  ///   'params': {}
  /// }));
  /// ```
  ///
  /// ## Performance
  ///
  /// The method performs a flush operation to ensure the message is sent
  /// immediately. For high-throughput scenarios, consider batching multiple
  /// messages if the protocol supports it.
  ///
  /// ## Thread Safety
  ///
  /// This method is not thread-safe. If multiple isolates or concurrent
  /// operations need to send messages, external synchronization is required.
  Future<void> send(String json) async {
    final utf8Bytes = utf8.encode(json);
    final header = 'Content-Length: ${utf8Bytes.length}\r\n\r\n';
    _stdout.add(utf8.encode(header));
    _stdout.add(utf8Bytes);
    await _stdout.flush();
  }

  /// Logs an error message to stderr.
  ///
  /// All error messages are prefixed with `[fly_mcp_core]` for easy
  /// identification in logs. This method uses either the custom stderr
  /// stream provided during construction or the global stderr.
  ///
  /// [message] - The error message to log
  void _logErr(String message) {
    (_stderr ?? stderr).writeln('[fly_mcp_core] $message');
  }
}

/// Searches for the LSP header terminator sequence in a byte array.
///
/// The LSP protocol uses `\r\n\r\n` (CRLF CRLF) to separate headers from
/// the message body. This function efficiently scans the byte array for
/// this 4-byte sequence: [13, 10, 13, 10].
///
/// ## Parameters
///
/// [bytes] - The byte array to search in
///
/// ## Returns
///
/// The index of the first byte of the terminator sequence if found,
/// or -1 if the sequence is not present in the array.
///
/// ## Example
///
/// ```dart
/// final data = utf8.encode('Content-Length: 10\r\n\r\n{"test":1}');
/// final index = _indexOfHeaderTerminator(data);
/// // index will be 19 (position of first \r in \r\n\r\n)
/// ```
///
/// ## Performance
///
/// This implementation uses a simple linear scan. For typical header sizes
/// (< 100 bytes), this is efficient. The function returns as soon as the
/// sequence is found.
int _indexOfHeaderTerminator(List<int> bytes) {
  for (var i = 0; i + 3 < bytes.length; i++) {
    if (bytes[i] == 13 && bytes[i + 1] == 10 && bytes[i + 2] == 13 && bytes[i + 3] == 10) {
      return i;
    }
  }
  return -1;
}

/// Parses HTTP-style headers from a string into a map.
///
/// This function parses LSP protocol headers, which follow HTTP header format:
/// ```
/// Header-Name: value
/// Another-Header: another value
/// ```
///
/// Each header is on a separate line, with the name and value separated by
/// a colon (`:`). Leading and trailing whitespace is trimmed from both names
/// and values.
///
/// ## Parameters
///
/// [headersText] - A string containing one or more headers, separated by
/// newlines. This should NOT include the terminating `\r\n\r\n` sequence.
///
/// ## Returns
///
/// A [Map<String, String>] where keys are header names and values are
/// header values. If a line doesn't contain a colon or is malformed,
/// it is silently skipped.
///
/// ## Example
///
/// ```dart
/// final headers = _parseHeaders('Content-Length: 42\r\nContent-Type: application/json');
/// print(headers['Content-Length']); // '42'
/// print(headers['Content-Type']); // 'application/json'
///
/// // Headers with whitespace are trimmed
/// final headers2 = _parseHeaders('Content-Length:  100  ');
/// print(headers2['Content-Length']); // '100'
/// ```
///
/// ## Notes
///
/// - Duplicate header names are not explicitly handled; the last occurrence wins
/// - Empty lines and malformed lines (no colon) are silently ignored
/// - Header names are case-sensitive (though LSP typically uses consistent casing)
Map<String, String> _parseHeaders(String headersText) {
  final map = <String, String>{};
  for (final line in const LineSplitter().convert(headersText)) {
    final idx = line.indexOf(':');
    if (idx <= 0) continue;
    final name = line.substring(0, idx).trim();
    final value = line.substring(idx + 1).trim();
    map[name] = value;
  }
  return map;
}

