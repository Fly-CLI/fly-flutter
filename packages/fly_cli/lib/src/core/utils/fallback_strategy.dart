import 'dart:io';
import 'package:fly_cli/src/core/cache/template_cache_manager.dart';

/// 4-level fallback strategy for template retrieval
class FallbackStrategy {

  FallbackStrategy(this.cacheManager);
  final TemplateCacheManager cacheManager;

  /// Get template using fallback strategy
  /// Levels: Network → Cache → Bundled → Fail
  Future<Template> getTemplate(String name, {bool offlineMode = false}) async {
    // Level 1: Try network download
    if (!offlineMode) {
      try {
        print('Level 1: Attempting network download...');
        final template = await _downloadFromNetwork(name);
        return template;
      } catch (e) {
        print('Level 1 failed: $e');
        print('Falling back to Level 2...');
      }
    }

    // Level 2: Try cache
    try {
      print('Level 2: Attempting to load from cache...');
      final template = await cacheManager.getTemplate(name, offlineMode: true);
      print('Level 2 succeeded: Loaded from cache');
      return template;
    } catch (e) {
      print('Level 2 failed: $e');
      print('Falling back to Level 3...');
    }

    // Level 3: Try bundled templates (built into CLI)
    try {
      print('Level 3: Attempting to load bundled template...');
      final template = await _loadBundledTemplate(name);
      print('Level 3 succeeded: Loaded bundled template');
      return template;
    } catch (e) {
      print('Level 3 failed: $e');
      print('Falling back to Level 4...');
    }

    // Level 4: Fail with helpful message
    throw TemplateNotFoundException(
      'Template "$name" not found using any fallback method',
      suggestions: _generateSuggestions(name, offlineMode),
    );
  }

  /// Level 1: Download from network
  Future<Template> _downloadFromNetwork(String name) async {
    // Network download implementation
    // Returns downloaded template
    throw NetworkDownloadException('Network download not implemented');
  }

  /// Level 3: Load bundled template
  Future<Template> _loadBundledTemplate(String name) async {
    // Check if template is bundled
    final bundledTemplates = ['minimal', 'riverpod'];
    
    if (!bundledTemplates.contains(name)) {
      throw BundledTemplateNotFoundException('Template "$name" is not bundled');
    }

    // Load from bundled templates directory
    final bundledPath = 'packages/fly_cli/lib/src/templates/bundled/$name.template.json';
    final file = File(bundledPath);
    
    if (!await file.exists()) {
      throw BundledTemplateNotFoundException('Bundled template file not found: $bundledPath');
    }

    // Load and return bundled template
    // This would parse the JSON and return a Template object
    throw BundledTemplateNotFoundException('Bundled template loading not implemented');
  }

  /// Generate helpful suggestions based on the error context
  List<String> _generateSuggestions(String templateName, bool offlineMode) {
    final suggestions = <String>[];

    if (offlineMode) {
      suggestions.add('You are in offline mode. Try: fly template fetch $templateName (when online)');
      suggestions.add('Check if template exists in cache: fly template cache list');
    } else {
      suggestions.add('Check your internet connection and try again');
      suggestions.add('Verify template name: fly template list');
      suggestions.add('Download template manually: fly template fetch $templateName');
    }

    suggestions.add('For help: fly help template');

    return suggestions;
  }
}

/// Exception for template not found
class TemplateNotFoundException implements Exception {

  TemplateNotFoundException(this.message, {required this.suggestions});
  final String message;
  final List<String> suggestions;

  @override
  String toString() {
    final buffer = StringBuffer('TemplateNotFoundException: $message\n\n');
    buffer.writeln('Suggestions:');
    for (final suggestion in suggestions) {
      buffer.writeln('  • $suggestion');
    }
    return buffer.toString();
  }
}

/// Exception for network download failures
class NetworkDownloadException implements Exception {

  NetworkDownloadException(this.message);
  final String message;

  @override
  String toString() => 'NetworkDownloadException: $message';
}

/// Exception for bundled template not found
class BundledTemplateNotFoundException implements Exception {

  BundledTemplateNotFoundException(this.message);
  final String message;

  @override
  String toString() => 'BundledTemplateNotFoundException: $message';
} 