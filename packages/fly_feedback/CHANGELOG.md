# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-01-XX

### Added
- Initial release of fly_feedback package
- Support for success, error, warning, and info feedback types
- Multiple display strategies: snackbar, dialog, bottom sheet, toast, banner
- Feedback service interface with generic type support
- DefaultFeedbackService implementation for standard feedback operations
- Mixins for emitting and listening to feedback events (FlyFeedbackEmitterMixin, FlyFeedbackListenerMixin)
- Handler pattern for custom feedback displays
- Composite feedback handler for multiple display strategies
- Comprehensive example app demonstrating all features
- Configuration classes for customizing handler behavior
- Support for action buttons in success and error feedback
- Support for retry actions in error feedback
- Support for confirmation dialogs with custom actions
- Material Design 3 theme integration
- Color system with automatic theme color resolution
- Duration configuration for transient feedback
- Metadata support for feedback events

### Changed
- (None in initial release)

### Deprecated
- (None in initial release)

### Removed
- (None in initial release)

### Fixed
- (None in initial release)

### Security
- (None in initial release)

