import 'package:fly_cli/src/generation/template/template_info.dart';

/// Repository interface for template discovery and access.
///
/// Provides abstraction over template storage and retrieval, allowing
/// different implementations (local file system, remote registry, etc.).
abstract class ITemplateRepository {
  /// Get a template by name.
  ///
  /// Returns the template if found, null otherwise.
  Future<TemplateInfo?> getTemplate(String name);

  /// Discover all available templates.
  ///
  /// [forceRefresh] if true, bypasses cache and re-discovers templates.
  Future<List<TemplateInfo>> discoverTemplates({bool forceRefresh = false});

  /// Check if a template exists.
  Future<bool> templateExists(String name);

  /// Validate a template.
  ///
  /// Returns validation result indicating if template is valid.
  Future<bool> validateTemplate(TemplateInfo template);

  /// Get template path.
  ///
  /// Returns the absolute path to the template directory.
  Future<String?> getTemplatePath(String name);
}

