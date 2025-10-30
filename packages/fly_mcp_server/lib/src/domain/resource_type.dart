/// Enum representing predefined resource types
/// 
/// **Note:** This is an optional convenience enum. Users can implement their own
/// resource types by creating custom ResourceStrategy implementations. This enum
/// is only provided as a convenience for common use cases.
/// 
/// For complete control and reusability, users should create ResourceStrategy
/// instances directly and pass them to ResourceRegistry.
/// 
/// **Note:** This enum is not tied to any concrete implementations. If you need
/// a registry that maps ResourceType to strategies, create it in your application
/// layer (e.g., see fly_cli for an example ResourceStrategyRegistry).
enum ResourceType {
  workspace,
  logsRun,
  logsBuild,
  manifest,
  dependencies,
  tests,
}

