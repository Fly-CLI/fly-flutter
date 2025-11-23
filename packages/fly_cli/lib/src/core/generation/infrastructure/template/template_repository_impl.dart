import 'package:fly_cli/src/core/generation/application/ports/icache_manager.dart';
import 'package:fly_cli/src/core/generation/domain/repositories/itemplate_repository.dart';
import 'package:fly_cli/src/core/generation/domain/repositories/itemplate_validator.dart';
import 'package:fly_cli/src/core/generation/template/template_info.dart';
import 'package:fly_cli/src/core/generation/template/template_manager.dart';

/// Implementation of ITemplateRepository using TemplateManager.
///
/// This adapter wraps the existing TemplateManager to implement
/// the new repository interface, maintaining backward compatibility.
/// Uses TemplateCache for caching and TemplateValidator for validation.
class TemplateRepositoryImpl implements ITemplateRepository {
  TemplateRepositoryImpl({
    required TemplateManager templateManager,
    ICacheManager<TemplateInfo>? templateCache,
    ITemplateValidator? templateValidator,
  })
      : _templateManager = templateManager,
        _templateCache = templateCache,
        _templateValidator = templateValidator;

  final TemplateManager _templateManager;
  final ICacheManager<TemplateInfo>? _templateCache;
  final ITemplateValidator? _templateValidator;

  @override
  Future<TemplateInfo?> getTemplate(String name) async {
    // Try cache first if available
    if (_templateCache != null) {
      final cached = await _templateCache.get(name);
      if (cached != null) {
        return cached;
      }
    }

    // Get from template manager
    final template = await _templateManager.getTemplate(name);

    // Cache if available
    if (template != null && _templateCache != null) {
      await _templateCache.set(name, template);
    }

    return template;
  }

  @override
  Future<List<TemplateInfo>> discoverTemplates({bool forceRefresh = false}) async {
    if (forceRefresh && _templateCache != null) {
      await _templateCache.clear();
    }

    return _templateManager.getAvailableTemplates();
  }

  @override
  Future<bool> templateExists(String name) async {
    // Check cache first
    if (_templateCache != null) {
      final exists = await _templateCache.exists(name);
      if (exists) {
        return true;
      }
    }

    final template = await getTemplate(name);
    return template != null;
  }

  @override
  Future<bool> validateTemplate(TemplateInfo template) async {
    // Use validator if available, otherwise basic check
    if (_templateValidator != null) {
      final result = await _templateValidator.validateTemplate(template);
      return result.isValid;
    }

    // Basic validation fallback
    if (template.name.isEmpty || template.path.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Future<String?> getTemplatePath(String name) async {
    final template = await getTemplate(name);
    return template?.path;
  }
}

