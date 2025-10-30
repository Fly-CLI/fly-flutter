import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:fly_mcp_server/src/concurrency_limiter.dart';
import 'package:fly_mcp_server/src/errors/error_converter.dart';
import 'package:fly_mcp_server/src/errors/server_errors.dart';
import 'package:fly_mcp_server/src/timeout_manager.dart';
import 'package:test/test.dart';

void main() {
  group('ErrorConverter', () {
    group('toJsonRpcError', () {
      test('should return JsonRpcError as-is', () {
        final originalError = JsonRpcError(
          code: -32000,
          message: 'Test error',
          data: {'key': 'value'},
        );

        final result = ErrorConverter.toJsonRpcError(originalError);

        expect(result, same(originalError));
        expect(result.code, equals(-32000));
        expect(result.message, equals('Test error'));
        expect(result.data, equals({'key': 'value'}));
      });

      test('should convert ToolNotFoundError', () {
        const error = ToolNotFoundError(toolName: 'nonexistent-tool');
        const requestId = 123;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpNotFound));
        expect(result.message, contains('nonexistent-tool'));
        expect(result.data, containsPair('tool', 'nonexistent-tool'));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert ResourceNotFoundError', () {
        const error = ResourceNotFoundError(uri: 'workspace://nonexistent');
        const requestId = 'req-456';

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpNotFound));
        expect(result.message, contains('workspace://nonexistent'));
        expect(result.data, containsPair('uri', 'workspace://nonexistent'));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert PromptNotFoundError', () {
        const error = PromptNotFoundError(promptId: 'nonexistent-prompt');
        const requestId = 789;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpNotFound));
        expect(result.message, contains('nonexistent-prompt'));
        expect(result.data, containsPair('promptId', 'nonexistent-prompt'));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert MethodNotFoundError', () {
        const error = MethodNotFoundError(methodName: 'unknown/method');
        const requestId = 'req-999';

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.methodNotFound));
        expect(result.message, contains('unknown/method'));
        expect(result.data, containsPair('method', 'unknown/method'));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert ValidationError without fieldErrors', () {
        const error = ValidationError(message: 'Validation failed');
        const requestId = 100;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.invalidParams));
        expect(result.message, equals('Validation failed'));
        expect(result.data, containsPair('requestId', requestId));
        expect(result.data, isNot(contains('fieldErrors')));
      });

      test('should convert ValidationError with fieldErrors', () {
        final fieldErrors = <String, List<String>>{
          'name': ['Name is required'],
          'email': ['Invalid email format'],
        };
        final error = ValidationError(
          message: 'Validation failed',
          fieldErrors: fieldErrors,
        );
        const requestId = 200;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.invalidParams));
        expect(result.message, equals('Validation failed'));
        expect(result.data, containsPair('fieldErrors', fieldErrors));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert InvalidParamsError without missing/invalid fields', () {
        const error = InvalidParamsError(message: 'Invalid parameters');
        const requestId = 300;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.invalidParams));
        expect(result.message, equals('Invalid parameters'));
        expect(result.data, containsPair('requestId', requestId));
        expect(result.data, isNot(contains('missingFields')));
        expect(result.data, isNot(contains('invalidFields')));
      });

      test('should convert InvalidParamsError with missingFields', () {
        const missingFields = ['name', 'email'];
        const error = InvalidParamsError(
          message: 'Invalid parameters',
          missingFields: missingFields,
        );
        const requestId = 400;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.invalidParams));
        expect(result.message, equals('Invalid parameters'));
        expect(result.data, containsPair('missingFields', missingFields));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert InvalidParamsError with invalidFields', () {
        const invalidFields = ['age', 'phone'];
        const error = InvalidParamsError(
          message: 'Invalid parameters',
          invalidFields: invalidFields,
        );
        const requestId = 500;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.invalidParams));
        expect(result.message, equals('Invalid parameters'));
        expect(result.data, containsPair('invalidFields', invalidFields));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert InvalidParamsError with both missing and invalid fields', () {
        const missingFields = ['name'];
        const invalidFields = ['age'];
        const error = InvalidParamsError(
          message: 'Invalid parameters',
          missingFields: missingFields,
          invalidFields: invalidFields,
        );
        const requestId = 600;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.invalidParams));
        expect(result.message, equals('Invalid parameters'));
        expect(result.data, containsPair('missingFields', missingFields));
        expect(result.data, containsPair('invalidFields', invalidFields));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert CancellationError', () {
        const requestId = 'cancel-req-123';
        const error = CancellationError(requestId: requestId);
        const errorRequestId = 700;

        final result = ErrorConverter.toJsonRpcError(error, requestId: errorRequestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpCanceled));
        expect(result.message, contains(requestId));
        expect(result.data, containsPair('requestId', requestId));
        // CancellationError has its own requestId, so errorRequestId is not used
      });

      test('should convert TimeoutError without operationName', () {
        final timeout = Duration(seconds: 30);
        final error = TimeoutError(timeout: timeout);
        const requestId = 800;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpTimeout));
        expect(result.message, contains('30'));
        expect(result.data, containsPair('timeout', 30));
        expect(result.data, containsPair('requestId', requestId));
        expect(result.data, isNot(contains('operation')));
      });

      test('should convert TimeoutError with operationName', () {
        final timeout = Duration(seconds: 60);
        final error = TimeoutError(
          timeout: timeout,
          operationName: 'tool-execution',
        );
        const requestId = 900;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpTimeout));
        expect(result.message, contains('tool-execution'));
        expect(result.message, contains('60'));
        expect(result.data, containsPair('timeout', 60));
        expect(result.data, containsPair('operation', 'tool-execution'));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert ConcurrencyLimitError', () {
        const error = ConcurrencyLimitError(
          toolName: 'test-tool',
          current: 5,
          limit: 3,
        );
        const requestId = 1000;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpPermissionDenied));
        expect(result.message, contains('test-tool'));
        expect(result.message, contains('5'));
        expect(result.message, contains('3'));
        expect(result.data, containsPair('tool', 'test-tool'));
        expect(result.data, containsPair('current', 5));
        expect(result.data, containsPair('limit', 3));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert PermissionDeniedError without reason', () {
        const error = PermissionDeniedError(message: 'Access denied');
        const requestId = 1100;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpPermissionDenied));
        expect(result.message, equals('Access denied'));
        expect(result.data, containsPair('requestId', requestId));
        expect(result.data, isNot(contains('reason')));
      });

      test('should convert PermissionDeniedError with reason', () {
        const error = PermissionDeniedError(
          message: 'Access denied',
          reason: 'Insufficient permissions',
        );
        const requestId = 1200;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpPermissionDenied));
        expect(result.message, equals('Access denied'));
        expect(result.data, containsPair('reason', 'Insufficient permissions'));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert CancellationException', () {
        final error = CancellationException('Request cancelled');
        const requestId = 1300;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpCanceled));
        expect(result.message, contains('Request cancelled'));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert TimeoutException', () {
        final error = TimeoutException('Operation timed out', Duration(seconds: 30));
        const requestId = 1400;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpTimeout));
        expect(result.message, contains('Operation timed out'));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert ConcurrencyLimitException', () {
        final error = ConcurrencyLimitException(
          'Tool limit reached',
          toolName: 'test-tool',
          current: 10,
          limit: 5,
        );
        const requestId = 1500;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.mcpPermissionDenied));
        expect(result.message, equals('Tool limit reached'));
        expect(result.data, containsPair('tool', 'test-tool'));
        expect(result.data, containsPair('current', 10));
        expect(result.data, containsPair('limit', 5));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert unknown errors to internal error', () {
        final error = Exception('Unknown error occurred');
        const requestId = 1600;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.internalError));
        expect(result.message, contains('Internal server error'));
        expect(result.message, contains('Unknown error occurred'));
        expect(result.data, containsPair('error', contains('Unknown error occurred')));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should convert generic Object to internal error', () {
        final error = 'String error';
        const requestId = 1700;

        final result = ErrorConverter.toJsonRpcError(error, requestId: requestId);

        expect(result.code, equals(JsonRpcErrorCode.internalError));
        expect(result.message, contains('Internal server error'));
        expect(result.message, contains('String error'));
        expect(result.data, containsPair('error', 'String error'));
        expect(result.data, containsPair('requestId', requestId));
      });

      test('should handle null requestId', () {
        const error = ToolNotFoundError(toolName: 'test-tool');

        final result = ErrorConverter.toJsonRpcError(error);

        expect(result.code, equals(JsonRpcErrorCode.mcpNotFound));
        expect(result.data, containsPair('tool', 'test-tool'));
        expect(result.data, isNot(contains('requestId')));
      });

      test('should not include requestId when null for ValidationError', () {
        final error = ValidationError(message: 'Validation failed');

        final result = ErrorConverter.toJsonRpcError(error);

        expect(result.code, equals(JsonRpcErrorCode.invalidParams));
        expect(result.data, isNot(contains('requestId')));
      });
    });

    group('isKnownError', () {
      test('should return true for McpServerException', () {
        const error = ToolNotFoundError(toolName: 'test');
        expect(ErrorConverter.isKnownError(error), isTrue);
      });

      test('should return true for JsonRpcError', () {
        final error = JsonRpcError(
          code: -32000,
          message: 'Test',
        );
        expect(ErrorConverter.isKnownError(error), isTrue);
      });

      test('should return true for CancellationException', () {
        final error = CancellationException('Cancelled');
        expect(ErrorConverter.isKnownError(error), isTrue);
      });

      test('should return true for TimeoutException', () {
        final error = TimeoutException('Timeout', Duration(seconds: 30));
        expect(ErrorConverter.isKnownError(error), isTrue);
      });

      test('should return true for ConcurrencyLimitException', () {
        final error = ConcurrencyLimitException(
          'Limit reached',
          toolName: 'test',
          current: 1,
          limit: 1,
        );
        expect(ErrorConverter.isKnownError(error), isTrue);
      });

      test('should return false for unknown errors', () {
        expect(ErrorConverter.isKnownError(Exception('Unknown')), isFalse);
        expect(ErrorConverter.isKnownError('String error'), isFalse);
        expect(ErrorConverter.isKnownError(123), isFalse);
      });
    });
  });
}

