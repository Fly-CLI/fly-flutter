/// Shared enums and type definitions for the fly_foundation template system.
///
/// Provides strongly-typed enums for all categorical variables used in template
/// generation, with helpers for parsing from and serializing to Mason variable maps.
///
/// NOTE: This file now re-exports domain-specific types from foundation_domain
/// and generic types from fly_brick_composer for backward compatibility.
/// New code should import directly from foundation_domain or fly_brick_composer.

// Re-export generic types from fly_brick_composer
export 'package:fly_brick_composer/fly_brick_composer.dart'
    show GenerationMode, PlatformType;

// Re-export domain-specific types from foundation_domain
export 'foundation_domain/foundation_types.dart'
    show BrickId, ProjectName, ScreenType, ServiceType, StateManagement;
