import 'package:fly_cli/src/core/templates/generation/generation_request.dart';
import 'package:fly_cli/src/core/templates/generators/generation_result.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Unified service interface for code generation operations.
///
/// Provides a single source of truth for generation logic that can be used
/// by both CLI commands and MCP tool strategies. Handles variable building,
/// validation, orchestration, and result transformation.
abstract class GenerationService {
  /// Generate a feature component.
  ///
  /// [request] contains all parameters needed for generation.
  /// [progressNotifier] optional progress notifier for MCP tools.
  ///
  /// Returns a GenerationResult with success status and generated files.
  Future<GenerationResult> generateFeature({
    required GenerationRequest request,
    ProgressNotifier? progressNotifier,
  });

  /// Generate a service component.
  ///
  /// [request] contains all parameters needed for generation.
  /// [progressNotifier] optional progress notifier for MCP tools.
  ///
  /// Returns a GenerationResult with success status and generated files.
  Future<GenerationResult> generateService({
    required GenerationRequest request,
    ProgressNotifier? progressNotifier,
  });
}

