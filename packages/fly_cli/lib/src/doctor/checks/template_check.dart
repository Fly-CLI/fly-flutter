import 'dart:io';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../system_checker.dart';
import '../../templates/template_manager.dart';

/// Check template availability and validity
class TemplateCheck extends SystemCheck {
  TemplateCheck({
    required this.templatesDirectory,
    this.logger,
  });
  
  final String templatesDirectory;
  final Logger? logger;

  @override
  String get name => 'Templates';

  @override
  String get category => 'Fly CLI';

  @override
  String get description => 'Check template availability and validity';

  @override
  Future<CheckResult> run() async {
    try {
      final issues = <String>[];
      final suggestions = <String>[];
      final data = <String, dynamic>{};

      // Check if templates directory exists
      final templatesDir = Directory(templatesDirectory);
      if (!await templatesDir.exists()) {
        return CheckResult.error(
          message: 'Templates directory does not exist: $templatesDirectory',
          suggestion: 'Ensure Fly CLI is properly installed with templates',
          fixCommand: 'Reinstall Fly CLI or check installation',
          data: {'templatesDirectory': templatesDirectory, 'exists': false},
        );
      }

      // Get available templates
      final templateManager = TemplateManager(
        templatesDirectory: templatesDirectory,
        logger: logger ?? Logger(),
      );
      
      final templates = await templateManager.getAvailableTemplates();
      
      if (templates.isEmpty) {
        return CheckResult.error(
          message: 'No templates found in templates directory',
          suggestion: 'Ensure Fly CLI templates are properly installed',
          fixCommand: 'Reinstall Fly CLI or check template installation',
          data: {
            'templatesDirectory': templatesDirectory,
            'templateCount': 0,
          },
        );
      }

      // Check each template for validity
      final invalidTemplates = <String>[];
      final templateData = <String, dynamic>{};
      
      for (final template in templates) {
        final templatePath = path.join(templatesDirectory, template.name);
        final templateDir = Directory(templatePath);
        
        if (!await templateDir.exists()) {
          invalidTemplates.add('${template.name}: directory missing');
          continue;
        }

        // Check for required files
        final requiredFiles = ['template.yaml', '__brick__'];
        final missingFiles = <String>[];
        
        for (final requiredFile in requiredFiles) {
          final filePath = path.join(templatePath, requiredFile);
          final file = File(filePath);
          final dir = Directory(filePath);
          
          if (!await file.exists() && !await dir.exists()) {
            missingFiles.add(requiredFile);
          }
        }

        if (missingFiles.isNotEmpty) {
          invalidTemplates.add('${template.name}: missing ${missingFiles.join(', ')}');
        }

        templateData[template.name] = {
          'version': template.version,
          'description': template.description,
          'valid': missingFiles.isEmpty,
          'missingFiles': missingFiles,
        };
      }

      if (invalidTemplates.isNotEmpty) {
        issues.add('Invalid templates: ${invalidTemplates.join('; ')}');
        suggestions.add('Check template installation and structure');
      }

      // Check cache status
      final cacheResult = await _checkCacheStatus();
      if (!cacheResult.healthy) {
        issues.add('Cache: ${cacheResult.message}');
        if (cacheResult.suggestion != null) {
          suggestions.add(cacheResult.suggestion!);
        }
        data['cache'] = cacheResult.data;
      } else {
        data['cache'] = cacheResult.data;
      }

      data['templates'] = templateData;
      data['templateCount'] = templates.length;
      data['invalidCount'] = invalidTemplates.length;

      if (issues.isEmpty) {
        return CheckResult.success(
          message: 'All templates are valid and accessible (${templates.length} templates)',
          data: data,
        );
      } else if (issues.length == 1) {
        return CheckResult.warning(
          message: 'Template issue: ${issues.first}',
          suggestion: suggestions.isNotEmpty ? suggestions.first : null,
          data: data,
        );
      } else {
        return CheckResult.warning(
          message: 'Multiple template issues found',
          suggestion: suggestions.join('; '),
          data: data,
        );
      }

    } catch (e) {
      return CheckResult.error(
        message: 'Failed to check templates: $e',
        suggestion: 'Check Fly CLI installation and template directory',
        data: {'error': e.toString()},
      );
    }
  }

  /// Check cache status
  Future<CheckResult> _checkCacheStatus() async {
    try {
      // Check if cache directory exists and is accessible
      final cacheDir = Directory(path.join(templatesDirectory, '..', 'cache'));
      
      if (!await cacheDir.exists()) {
        return CheckResult.success(
          message: 'Template cache directory does not exist yet',
          data: {'cacheDirectory': cacheDir.path, 'exists': false},
        );
      }

      // Check cache directory permissions
      try {
        await cacheDir.list().first;
        return CheckResult.success(
          message: 'Template cache is accessible',
          data: {
            'cacheDirectory': cacheDir.path,
            'accessible': true,
          },
        );
      } catch (e) {
        return CheckResult.warning(
          message: 'Template cache directory is not accessible',
          suggestion: 'Check cache directory permissions',
          data: {
            'cacheDirectory': cacheDir.path,
            'error': e.toString(),
          },
        );
      }
    } catch (e) {
      return CheckResult.warning(
        message: 'Could not check cache status: $e',
        suggestion: 'Check cache directory configuration',
        data: {'error': e.toString()},
      );
    }
  }
}
