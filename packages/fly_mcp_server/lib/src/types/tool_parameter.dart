import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/types/type_converter.dart';

/// Abstract base interface for tool parameters
/// 
/// All tool-specific parameter models should implement this interface.
/// This provides a type-safe way to represent tool parameters while maintaining
/// compatibility with the JSON-RPC protocol through serialization.
abstract class ToolParameter {
  /// Convert to Map for protocol serialization
  /// 
  /// Returns a Map representation suitable for JSON-RPC serialization.
  Map<String, Object?> toJson();
  
  /// Validate this parameter against the tool's parameter schema
  /// 
  /// [schema] - The ObjectSchema representing the expected parameter structure
  /// 
  /// Returns an empty list if valid, or a list of error messages if invalid.
  /// Uses TypeConverter to validate against the schema.
  List<String> validate(ObjectSchema schema) {
    return TypeConverter.validateTypedModel(this, schema);
  }
}

