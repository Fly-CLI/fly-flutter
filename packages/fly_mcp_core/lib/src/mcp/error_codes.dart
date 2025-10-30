/// MCP-specific error codes (following MCP spec conventions)
class McpErrorCodes {
  // Standard JSON-RPC 2.0 error codes
  static const int parseError = -32700;
  static const int invalidRequest = -32600;
  static const int methodNotFound = -32601;
  static const int invalidParams = -32602;
  static const int internalError = -32603;

  // MCP domain error codes (custom range: -32000 to -32099)
  static const int mcpInvalidParams = -32602; // Reuse JSON-RPC for params
  static const int mcpCanceled = -32800; // Request was canceled
  static const int mcpTimeout = -32801; // Request timed out
  static const int mcpTooLarge = -32802; // Message/resource too large
  static const int mcpPermissionDenied = -32803; // Permission denied for operation
  static const int mcpNotFound = -32804; // Resource/tool not found
}

