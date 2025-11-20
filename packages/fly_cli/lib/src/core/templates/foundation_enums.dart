/// Shared enums and type definitions for the fly_foundation template system.
///
/// Provides strongly-typed enums for all categorical variables used in template
/// generation, with helpers for parsing from and serializing to Mason variable maps.
///
/// NOTE: This file now re-exports domain-specific types from foundation_domain
/// and generic types from fly_foundation_planning for backward compatibility.
/// New code should import directly from foundation_domain or fly_foundation_planning.

// Re-export domain-specific types from foundation_domain
export 'foundation_domain/foundation_types.dart' show ScreenType, ServiceType, StateManagement, ProjectName;

// Re-export generic types from fly_foundation_planning
export 'package:fly_foundation_planning/fly_foundation_planning.dart' show GenerationMode, PlatformType;

