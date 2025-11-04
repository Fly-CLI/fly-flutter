/// Command categories for better organization and discoverability
enum CommandCategory {
  /// Project setup and initialization commands
  project,

  /// Code generation commands (screens, services, etc.)
  generation,

  /// Information and export commands (version, context, schema)
  information,

  /// System diagnostics commands
  diagnostics,

  /// Integration commands (completion, MCP)
  integration,
}

/// Tool categories for better organization and discoverability
enum ToolCategory {
  /// Diagnostic tools (echo, doctor)
  diagnostic,

  /// Template management tools (list, apply)
  template,

  /// Code generation tools (generate screen, generate service)
  generation,

  /// Export tools (context, schema)
  export,

  /// Integration tools (completion, version)
  integration,
}
