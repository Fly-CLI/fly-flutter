import 'dart:io';

import 'package:fly_cli/src/features/context/domain/models/models.dart';
import 'package:fly_cli/src/features/context/infrastructure/analysis/base/utils.dart';
import 'package:path/path.dart' as path;

/// Result of directory analysis containing all discovered files and metadata
class DirectoryAnalysisResult {
  final Map<String, FileInfo> files;
  final Map<String, DirectoryInfo> directories;
  final List<String> dartFiles;
  final List<String> testFiles;
  final List<String> generatedFiles;
  final Map<String, int> fileTypes;
  final int totalFiles;
  final int totalLinesOfCode;

  const DirectoryAnalysisResult({
    required this.files,
    required this.directories,
    required this.dartFiles,
    required this.testFiles,
    required this.generatedFiles,
    required this.fileTypes,
    required this.totalFiles,
    required this.totalLinesOfCode,
  });

  /// Get files by type
  List<String> getFilesByType(String type) {
    return files.values
        .where((file) => file.type == type)
        .map((file) => file.path)
        .toList();
  }

  /// Get files by importance level
  List<String> getFilesByImportance(String importance) {
    return files.values
        .where((file) => file.importance == importance)
        .map((file) => file.path)
        .toList();
  }

  /// Get files in a specific directory
  List<String> getFilesInDirectory(String directory) {
    return files.values
        .where((file) => path.dirname(file.path) == directory)
        .map((file) => file.path)
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'files': files.map((key, value) => MapEntry(key, value.toJson())),
      'directories': directories.map((key, value) => MapEntry(key, value.toJson())),
      'dart_files': dartFiles,
      'test_files': testFiles,
      'generated_files': generatedFiles,
      'file_types': fileTypes,
      'total_files': totalFiles,
      'total_lines_of_code': totalLinesOfCode,
    };
  }
}

/// Information about a single file
class FileInfo {
  final String path;
  final String name;
  final String type;
  final String importance;
  final int linesOfCode;
  final int size;
  final DateTime? modified;
  final String? description;

  const FileInfo({
    required this.path,
    required this.name,
    required this.type,
    required this.importance,
    required this.linesOfCode,
    required this.size,
    this.modified,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'type': type,
      'importance': importance,
      'lines_of_code': linesOfCode,
      'size': size,
      'modified': modified?.toIso8601String(),
      'description': description,
    };
  }
}

/// Unified directory analyzer that performs a single traversal
class UnifiedDirectoryAnalyzer {
  const UnifiedDirectoryAnalyzer();

  /// Analyze a directory structure with a single traversal
  Future<DirectoryAnalysisResult> analyze(Directory projectDir) async {
    final files = <String, FileInfo>{};
    final directories = <String, DirectoryInfo>{};
    final dartFiles = <String>[];
    final testFiles = <String>[];
    final generatedFiles = <String>[];
    final fileTypes = <String, int>{};
    int totalLinesOfCode = 0;

    // Single traversal of the entire project
    await for (final entity in projectDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: projectDir.path);
        final fileName = path.basename(entity.path);
        final extension = path.extension(entity.path);
        
        // Count file types
        fileTypes[extension] = (fileTypes[extension] ?? 0) + 1;

        // Determine file type and importance
        final fileType = _determineFileType(relativePath, fileName);
        final importance = _determineImportance(fileType, fileName);
        
        // Check if it's a generated file
        final isGenerated = _isGeneratedFile(relativePath, fileName);
        if (isGenerated) {
          generatedFiles.add(relativePath);
        }

        // Count lines of code for Dart files
        int linesOfCode = 0;
        if (entity.path.endsWith('.dart')) {
          dartFiles.add(relativePath);
          linesOfCode = await FileUtils.countLines(entity);
          totalLinesOfCode += linesOfCode;
          
          if (fileType == 'test') {
            testFiles.add(relativePath);
          }
        }

        // Get file metadata
        final stat = await entity.stat();
        
        files[relativePath] = FileInfo(
          path: relativePath,
          name: fileName,
          type: fileType,
          importance: importance,
          linesOfCode: linesOfCode,
          size: stat.size,
          modified: stat.modified,
          description: _generateDescription(fileType, fileName),
        );
      } else if (entity is Directory) {
        final relativePath = path.relative(entity.path, from: projectDir.path);
        final dirInfo = await _analyzeDirectory(entity);
        directories[relativePath] = dirInfo;
      }
    }

    return DirectoryAnalysisResult(
      files: files,
      directories: directories,
      dartFiles: dartFiles,
      testFiles: testFiles,
      generatedFiles: generatedFiles,
      fileTypes: fileTypes,
      totalFiles: files.length,
      totalLinesOfCode: totalLinesOfCode,
    );
  }

  /// Analyze a single directory
  Future<DirectoryInfo> _analyzeDirectory(Directory dir) async {
    int files = 0;
    int dartFiles = 0;
    final subdirectories = <String>[];

    await for (final entity in dir.list(recursive: false)) {
      if (entity is File) {
        files++;
        if (entity.path.endsWith('.dart')) {
          dartFiles++;
        }
      } else if (entity is Directory) {
        subdirectories.add(path.basename(entity.path));
      }
    }

    return DirectoryInfo(
      files: files,
      dartFiles: dartFiles,
      subdirectories: subdirectories,
    );
  }

  /// Determine file type based on path and name
  String _determineFileType(String relativePath, String fileName) {
    // Main entry point
    if (fileName == 'main.dart') return 'main';
    
    // App configuration
    if (fileName == 'app.dart') return 'app';
    
    // Routing
    if (fileName.contains('router') || fileName.contains('route')) return 'routing';
    
    // Screens
    if (fileName.contains('_screen.dart') || fileName.contains('_page.dart')) {
      return 'screen';
    }
    
    // ViewModels/Controllers
    if (fileName.contains('_viewmodel.dart') || 
        fileName.contains('_controller.dart') ||
        fileName.contains('_cubit.dart') ||
        fileName.contains('_bloc.dart')) {
      return 'viewmodel';
    }
    
    // Services
    if (fileName.contains('_service.dart') || 
        fileName.contains('_api.dart') ||
        fileName.contains('_repository.dart')) {
      return 'service';
    }
    
    // Models
    if (fileName.contains('_model.dart') || 
        fileName.contains('_entity.dart') ||
        fileName.contains('_data.dart')) {
      return 'model';
    }
    
    // Providers
    if (fileName.contains('_provider.dart') || fileName == 'providers.dart') {
      return 'provider';
    }
    
    // Widgets
    if (fileName.contains('_widget.dart') || fileName.contains('widgets/')) {
      return 'widget';
    }
    
    // Utils
    if (fileName.contains('_util.dart') || fileName.contains('utils/')) {
      return 'util';
    }
    
    // Constants
    if (fileName.contains('_constant.dart') || fileName.contains('constants/')) {
      return 'constant';
    }
    
    // Tests
    if (fileName.contains('_test.dart') || fileName.contains('test/')) {
      return 'test';
    }
    
    // Configuration files
    if (fileName.endsWith('.yaml') || fileName.endsWith('.yml')) {
      return 'config';
    }
    
    // Documentation
    if (fileName.endsWith('.md')) {
      return 'documentation';
    }
    
    return 'other';
  }

  /// Determine file importance
  String _determineImportance(String fileType, String fileName) {
    switch (fileType) {
      case 'main':
      case 'app':
      case 'routing':
        return 'high';
      case 'screen':
      case 'viewmodel':
      case 'service':
      case 'provider':
        return 'medium';
      case 'model':
      case 'widget':
      case 'util':
      case 'constant':
      case 'config':
        return 'low';
      default:
        return 'low';
    }
  }

  /// Check if file is generated
  bool _isGeneratedFile(String relativePath, String fileName) {
    // Check for common generated file patterns
    if (fileName.endsWith('.g.dart') || 
        fileName.endsWith('.freezed.dart') ||
        fileName.endsWith('.gr.dart') ||
        fileName.endsWith('.config.dart')) {
      return true;
    }
    
    // Check for generated directories
    if (relativePath.contains('/generated/') ||
        relativePath.contains('/build/') ||
        relativePath.contains('/.dart_tool/')) {
      return true;
    }
    
    return false;
  }

  /// Generate file description
  String _generateDescription(String fileType, String fileName) {
    switch (fileType) {
      case 'main':
        return 'Application entry point';
      case 'app':
        return 'Main app configuration and setup';
      case 'routing':
        return 'Navigation and routing configuration';
      case 'screen':
        return 'UI screen implementation';
      case 'viewmodel':
        return 'Business logic and state management';
      case 'service':
        return 'API service or data layer';
      case 'provider':
        return 'Dependency injection provider';
      case 'model':
        return 'Data model or entity';
      case 'widget':
        return 'Reusable UI widget';
      case 'util':
        return 'Utility functions and helpers';
      case 'constant':
        return 'Application constants and configuration';
      case 'test':
        return 'Unit or widget test';
      case 'config':
        return 'Configuration file';
      case 'documentation':
        return 'Documentation file';
      default:
        return 'Source code file';
    }
  }
}
