import 'dart:io';
import 'package:fly_cli/src/features/mcp/prompts/prompt_template_engine.dart';
import 'package:path/path.dart' as path;

/// Registry for loading and caching prompt templates
/// 
/// Provides efficient access to prompt templates with caching
/// to avoid reloading templates on every request.
class PromptTemplateRegistry {
  final Map<String, String> _cache = {};
  final String _templatesDirectory;

  /// Creates a new registry with the specified templates directory
  PromptTemplateRegistry({required String templatesDirectory})
      : _templatesDirectory = templatesDirectory;

  /// Finds the templates directory using fallback strategy
  /// Similar to TemplateManager.findTemplatesDirectory()
  static String findTemplatesDirectory() {
    // Try development path: packages/fly_cli/lib/src/features/mcp/prompts/templates
    final currentDir = Directory.current.path;
    final devTemplatesPath = path.join(
      currentDir,
      'packages',
      'fly_cli',
      'lib',
      'src',
      'features',
      'mcp',
      'prompts',
      'templates',
    );
    final devTemplatesDir = Directory(devTemplatesPath);
    if (devTemplatesDir.existsSync()) {
      return path.normalize(devTemplatesPath);
    }

    // Try relative to script location (development)
    final scriptPath = Platform.script.toFilePath();
    final scriptDir = path.dirname(scriptPath);
    
    // Try multiple relative paths for development
    final scriptRelativePaths = [
      path.join(
        scriptDir,
        '..',
        '..',
        'src',
        'features',
        'mcp',
        'prompts',
        'templates',
      ), // From packages/fly_cli/bin/
      path.join(
        scriptDir,
        '..',
        '..',
        '..',
        'packages',
        'fly_cli',
        'lib',
        'src',
        'features',
        'mcp',
        'prompts',
        'templates',
      ), // From test files
    ];
    
    for (final scriptRelativePath in scriptRelativePaths) {
      final normalizedPath = path.normalize(scriptRelativePath);
      final scriptRelativeDir = Directory(normalizedPath);
      if (scriptRelativeDir.existsSync()) {
        return normalizedPath;
      }
    }

    // Production path: relative to executable
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);
    
    // Templates are located at: {executable_dir}/../lib/src/features/mcp/prompts/templates
    return path.normalize(
      path.join(
        executableDir,
        '..',
        'lib',
        'src',
        'features',
        'mcp',
        'prompts',
        'templates',
      ),
    );
  }

  /// Gets a template by its ID (filename without .prompt extension)
  /// 
  /// Loads and caches the template on first access.
  /// Throws [StateError] if the template file doesn't exist.
  Future<String> getTemplate(String templateId) async {
    if (_cache.containsKey(templateId)) {
      return _cache[templateId]!;
    }

    final templatePath = path.join(
      _templatesDirectory,
      '$templateId.prompt',
    );
    
    final templateContent = await PromptTemplateParser.parseTemplateFile(
      templatePath,
    );
    
    _cache[templateId] = templateContent;
    return templateContent;
  }

  /// Renders a template with the given variables
  /// 
  /// Convenience method that loads and renders a template in one call.
  Future<String> render(
    String templateId,
    Map<String, dynamic> variables,
  ) async {
    final template = await getTemplate(templateId);
    return PromptTemplateEngine.render(template, variables);
  }

  /// Clears the template cache
  void clearCache() {
    _cache.clear();
  }

  /// Gets the templates directory path
  String get templatesDirectory => _templatesDirectory;
}

/// Global prompt template registry instance
/// 
/// Automatically finds the templates directory using fallback strategy.
final promptTemplateRegistry = PromptTemplateRegistry(
  templatesDirectory: PromptTemplateRegistry.findTemplatesDirectory(),
);

