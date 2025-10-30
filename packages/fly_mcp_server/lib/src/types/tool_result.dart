import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/types/type_converter.dart';

/// Abstract base interface for tool results
/// 
/// All tool-specific result models should implement this interface.
/// This provides a type-safe way to represent tool results while maintaining
/// compatibility with the JSON-RPC protocol through serialization.
abstract class ToolResult {
  /// Convert to Map for protocol serialization
  /// 
  /// Returns a Map representation suitable for JSON-RPC serialization.
  Map<String, Object?> toJson();
  
  /// Validate this result against the tool's result schema
  /// 
  /// [schema] - The ObjectSchema representing the expected result structure
  /// 
  /// Returns an empty list if valid, or a list of error messages if invalid.
  /// Uses TypeConverter to validate against the schema.
  List<String> validate(ObjectSchema schema) {
    return TypeConverter.validateTypedResult(this, schema);
  }
}

