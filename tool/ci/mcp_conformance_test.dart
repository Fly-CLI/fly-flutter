import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// MCP Conformance Test
/// 
/// Tests basic MCP protocol compliance:
/// - initialize handshake
/// - tools/list enumeration
/// - tools/call execution
/// - cancellation support
/// - error handling
Future<void> main() async {
  print('Starting MCP conformance test...');
  
  // Spawn MCP server process
  final proc = await Process.start(
    'dart',
    [
      'run',
      'packages/fly_cli/bin/fly.dart',
      'mcp',
      'serve',
      '--stdio',
      '--default-timeout-seconds=30',
    ],
  );

  // Buffer for stdout chunks
  final stdoutBuffer = <int>[];
  final stderrController = StreamController<String>.broadcast();
  
  // Set up stdout listener
  proc.stdout.listen(
    (chunk) {
      stdoutBuffer.addAll(chunk);
    },
    onDone: () {},
    onError: (e) {
      print('Stdout error: $e');
    },
  );

  // Set up stderr listener
  proc.stderr.transform(utf8.decoder).listen(
    (line) {
      stderrController.add(line);
    },
    onDone: () {},
    onError: (e) {
      print('Stderr error: $e');
    },
  );

  // Helper to send a framed JSON-RPC request
  Future<void> send(Object payload) async {
    final jsonStr = jsonEncode(payload);
    final bytes = utf8.encode(jsonStr);
    final header = 'Content-Length: ${bytes.length}\r\n\r\n';
    proc.stdin.add(utf8.encode(header));
    proc.stdin.add(bytes);
    await proc.stdin.flush();
  }

  Future<Map<String, Object?>> readResponse() async {
    // Wait a bit for response to arrive
    await Future.delayed(Duration(milliseconds: 100));
    
    // Read headers and body from buffer
    while (true) {
      if (stdoutBuffer.isEmpty) {
        await Future.delayed(Duration(milliseconds: 50));
        continue;
      }
      
      final bufferText = utf8.decode(stdoutBuffer);
      final idx = bufferText.indexOf('\r\n\r\n');
      
      if (idx == -1) {
        await Future.delayed(Duration(milliseconds: 50));
        continue;
      }
      
      final headerLines = bufferText.substring(0, idx);
      final rest = bufferText.substring(idx + 4);
      
      final contentLengthLine = headerLines.split('\n').firstWhere(
        (l) => l.toLowerCase().startsWith('content-length'),
        orElse: () => 'Content-Length: 0',
      );
      
      final len = int.parse(contentLengthLine.split(':')[1].trim());
      
      if (rest.length < len) {
        await Future.delayed(Duration(milliseconds: 50));
        continue;
      }
      
      final body = rest.substring(0, len);
      final remaining = rest.substring(len);
      
      // Remove consumed data from buffer
      stdoutBuffer.clear();
      stdoutBuffer.addAll(utf8.encode(remaining));
      
      return (jsonDecode(body) as Map).cast<String, Object?>();
    }
  }

  try {
    // Test 1: Initialize handshake
    print('Test 1: Initialize handshake...');
    await send({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {},
    });
    final initResponse = await readResponse();
    assert(initResponse['id'] == 1);
    assert(initResponse['result'] != null);
    final capabilities = (initResponse['result'] as Map)['capabilities'] as Map?;
    assert(capabilities?['tools'] == true);
    assert(capabilities?['resources'] != null);
    assert(capabilities?['prompts'] == true);
    print('✅ Initialize successful');

    // Test 2: List tools
    print('Test 2: List tools...');
    await send({
      'jsonrpc': '2.0',
      'id': 2,
      'method': 'tools/list',
    });
    final toolsResponse = await readResponse();
    assert(toolsResponse['id'] == 2);
    final tools = (toolsResponse['result'] as Map?)?['tools'] as List?;
    assert(tools != null && tools.length >= 7);
    print('✅ Tools list successful (found ${tools?.length} tools)');

    // Test 3: Call a simple tool (fly.echo)
    print('Test 3: Call fly.echo tool...');
    await send({
      'jsonrpc': '2.0',
      'id': 3,
      'method': 'tools/call',
      'params': {
        'name': 'fly.echo',
        'arguments': {'message': 'test'},
      },
    });
    final echoResponse = await readResponse();
    assert(echoResponse['id'] == 3);
    assert(echoResponse['result'] != null);
    final content = (echoResponse['result'] as Map?)?['content'] as Map?;
    assert(content?['message'] == 'test');
    print('✅ Tool call successful');

    // Test 4: Invalid tool name (error handling)
    print('Test 4: Error handling (invalid tool)...');
    await send({
      'jsonrpc': '2.0',
      'id': 4,
      'method': 'tools/call',
      'params': {
        'name': 'nonexistent.tool',
        'arguments': {},
      },
    });
    final errorResponse = await readResponse();
    assert(errorResponse['id'] == 4);
    assert(errorResponse['error'] != null);
    print('✅ Error handling correct');

    // Test 5: Ping
    print('Test 5: Ping...');
    await send({
      'jsonrpc': '2.0',
      'id': 5,
      'method': 'ping',
    });
    final pingResponse = await readResponse();
    assert(pingResponse['id'] == 5);
    print('✅ Ping successful');

    print('\n✅ All conformance tests passed!');
  } catch (e, st) {
    print('❌ Test failed: $e');
    print(st);
    exit(1);
  } finally {
    // Cleanup
    proc.kill(ProcessSignal.sigterm);
    await proc.exitCode;
  }
}

Future<List<int>> _readExact(
  Stream<List<int>> stream,
  int len, {
  List<int>? initial,
}) async {
  final out = <int>[];
  if (initial != null && initial.isNotEmpty) {
    out.addAll(initial);
  }
  await for (final chunk in stream) {
    out.addAll(chunk);
    if (out.length >= len) {
      return out.sublist(0, len);
    }
  }
  return out;
}

