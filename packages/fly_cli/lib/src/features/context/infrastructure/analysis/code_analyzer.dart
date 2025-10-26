import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:fly_cli/src/features/context/domain/models/models.dart';

/// Analyzes source code structure and content
class CodeAnalyzer {
  const CodeAnalyzer();

  /// Analyze code in a project directory
  Future<CodeInfo> analyzeCode(
    Directory projectDir,
    ContextGeneratorConfig config,
  ) async {
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    if (!await libDir.exists()) {
      return CodeInfo(
        keyFiles: [],
        fileContents: {},
        metrics: {},
        imports: {},
        patterns: [],
      );
    }

    // Identify key files
    final keyFiles = await identifyKeyFiles(libDir);

    // Extract file contents if requested
    final fileContents = config.includeCode
        ? await extractFileContents(keyFiles, config)
        : <String, String>{};

    // Calculate metrics
    final metrics = await calculateMetrics(projectDir);

    // Analyze imports
    final imports = await analyzeImports(keyFiles);

    // Detect patterns
    final patterns = await detectPatterns(libDir);

    return CodeInfo(
      keyFiles: keyFiles,
      fileContents: fileContents,
      metrics: metrics,
      imports: imports,
      patterns: patterns,
    );
  }

  /// Identify key source files
  Future<List<SourceFile>> identifyKeyFiles(Directory libDir) async {
    final keyFiles = <SourceFile>[];

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = path.relative(entity.path, from: libDir.path);
        final fileName = path.basename(entity.path);
        
        // Determine file type and importance
        final fileType = _determineFileType(relativePath, fileName);
        final importance = _determineImportance(fileType, fileName);
        
        // Count lines of code
        final linesOfCode = await _countLinesOfCode(entity);
        
        // Generate description
        final description = _generateDescription(fileType, fileName);

        keyFiles.add(SourceFile(
          path: relativePath,
          name: fileName,
          type: fileType,
          linesOfCode: linesOfCode,
          importance: importance,
          description: description,
        ));
      }
    }

    // Sort by importance and then by name
    keyFiles.sort((a, b) {
      final importanceOrder = {'high': 0, 'medium': 1, 'low': 2};
      final aOrder = importanceOrder[a.importance] ?? 3;
      final bOrder = importanceOrder[b.importance] ?? 3;
      
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      
      return a.name.compareTo(b.name);
    });

    return keyFiles;
  }

  /// Extract file contents for important files using streaming
  Future<Map<String, String>> extractFileContents(
    List<SourceFile> keyFiles,
    ContextGeneratorConfig config,
  ) async {
    final contents = <String, String>{};
    int filesProcessed = 0;

    for (final file in keyFiles) {
      if (filesProcessed >= config.maxFiles) break;
      
      // Only include high and medium importance files
      if (file.importance == 'low') continue;

      try {
        final filePath = path.join('lib', file.path);
        final fileEntity = File(filePath);
        
        if (await fileEntity.exists()) {
          // Use streaming for large files to reduce memory usage
          final content = await _readFileWithStreaming(fileEntity, config.maxFileSize);
          
          if (content != null) {
            contents[file.path] = content;
            filesProcessed++;
          }
        }
      } catch (e) {
        // Skip files that can't be read
        continue;
      }
    }

    return contents;
  }

  /// Read file content using streaming for large files with retry logic
  Future<String?> _readFileWithStreaming(File file, int maxSize) async {
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 50);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Check file size first
        final stat = await file.stat();
        if (stat.size > maxSize) {
          return null; // Skip files that are too large
        }

        // For small files, read normally
        if (stat.size < 1024 * 1024) { // Less than 1MB
          return await file.readAsString();
        }

        // For larger files, use streaming
        final buffer = StringBuffer();
        final stream = file.openRead();
        
        await for (final chunk in stream) {
          buffer.write(String.fromCharCodes(chunk));
          
          // Check if we've exceeded the limit during streaming
          if (buffer.length > maxSize) {
            return null;
          }
        }
        
        return buffer.toString();
      } catch (e) {
        if (attempt == maxRetries - 1) {
          return null; // Skip files that can't be read after retries
        }
        // Wait before retry
        await Future.delayed(retryDelay * (attempt + 1));
      }
    }
    
    return null;
  }

  /// Calculate code metrics
  Future<Map<String, int>> calculateMetrics(Directory projectDir) async {
    final metrics = <String, int>{
      'total_dart_files': 0,
      'total_lines_of_code': 0,
      'total_characters': 0,
      'classes': 0,
      'functions': 0,
      'imports': 0,
    };

    // Analyze lib directory
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    if (await libDir.exists()) {
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          await _analyzeDartFile(entity, metrics);
        }
      }
    }

    // Analyze test directory
    final testDir = Directory(path.join(projectDir.path, 'test'));
    if (await testDir.exists()) {
      await for (final entity in testDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          await _analyzeDartFile(entity, metrics);
        }
      }
    }

    return metrics;
  }

  /// Analyze imports in key files
  Future<Map<String, List<String>>> analyzeImports(List<SourceFile> keyFiles) async {
    final imports = <String, List<String>>{};

    for (final file in keyFiles) {
      if (file.importance == 'low') continue;

      try {
        final filePath = path.join('lib', file.path);
        final fileEntity = File(filePath);
        
        if (await fileEntity.exists()) {
          final content = await fileEntity.readAsString();
          final fileImports = _extractImports(content);
          imports[file.path] = fileImports;
        }
      } catch (e) {
        // Skip files that can't be read
        continue;
      }
    }

    return imports;
  }

  /// Detect code patterns
  Future<List<String>> detectPatterns(Directory libDir) async {
    final patterns = <String>{};

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();
        final detectedPatterns = _detectPatternsInContent(content);
        patterns.addAll(detectedPatterns);
      }
    }

    return patterns.toList();
  }

  /// Determine file type based on path and name
  String _determineFileType(String relativePath, String fileName) {
    // Main entry point
    if (fileName == 'main.dart') return 'main';
    
    // App configuration
    if (fileName == 'app.dart' || fileName == 'app.dart') return 'app';
    
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
        return 'low';
      default:
        return 'low';
    }
  }

  /// Count lines of code in a file using streaming
  Future<int> _countLinesOfCode(File file) async {
    try {
      // For small files, read normally
      final stat = await file.stat();
      if (stat.size < 1024 * 1024) { // Less than 1MB
        final content = await file.readAsString();
        return content.split('\n').length;
      }

      // For larger files, use streaming to count lines
      int lineCount = 0;
      final stream = file.openRead();
      
      await for (final chunk in stream) {
        final content = String.fromCharCodes(chunk);
        lineCount += content.split('\n').length - 1; // -1 because split creates extra element
      }
      
      return lineCount + 1; // +1 for the last line
    } catch (e) {
      return 0;
    }
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
      default:
        return 'Source code file';
    }
  }

  /// Analyze a Dart file for metrics using streaming
  Future<void> _analyzeDartFile(File file, Map<String, int> metrics) async {
    try {
      // For small files, read normally
      final stat = await file.stat();
      if (stat.size < 1024 * 1024) { // Less than 1MB
        final content = await file.readAsString();
        _processFileContent(content, metrics);
        return;
      }

      // For larger files, use streaming
      final buffer = StringBuffer();
      final stream = file.openRead();
      
      await for (final chunk in stream) {
        buffer.write(String.fromCharCodes(chunk));
        
        // Process in chunks to avoid memory issues
        if (buffer.length > 1024 * 1024) { // Process every 1MB
          _processFileContent(buffer.toString(), metrics);
          buffer.clear();
        }
      }
      
      // Process remaining content
      if (buffer.isNotEmpty) {
        _processFileContent(buffer.toString(), metrics);
      }
    } catch (e) {
      // Skip files that can't be analyzed
    }
  }

  /// Process file content for metrics calculation
  void _processFileContent(String content, Map<String, int> metrics) {
    final lines = content.split('\n');
    
    metrics['total_dart_files'] = (metrics['total_dart_files'] ?? 0) + 1;
    metrics['total_lines_of_code'] = (metrics['total_lines_of_code'] ?? 0) + lines.length;
    metrics['total_characters'] = (metrics['total_characters'] ?? 0) + content.length;
    
    // Count classes
    final classMatches = RegExp(r'class\s+\w+').allMatches(content);
    metrics['classes'] = (metrics['classes'] ?? 0) + classMatches.length;
    
    // Count functions
    final functionMatches = RegExp(r'(?:Future<[^>]*>|void|String|int|bool|double|Widget)\s+\w+\s*\(').allMatches(content);
    metrics['functions'] = (metrics['functions'] ?? 0) + functionMatches.length;
    
    // Count imports
    final importMatches = RegExp(r'import\s+').allMatches(content);
    metrics['imports'] = (metrics['imports'] ?? 0) + importMatches.length;
  }

  /// Extract imports from file content
  List<String> _extractImports(String content) {
    final imports = <String>[];
    // Match import statements with single or double quotes
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.trim().startsWith('import ')) {
        // Try to extract the import path
        final singleQuote = RegExp(r"import\s+'(.+?)'").firstMatch(line);
        final doubleQuote = RegExp(r'import\s+"(.+?)"').firstMatch(line);
        final match = singleQuote ?? doubleQuote;
        if (match != null) {
          imports.add(match.group(1)!);
        }
      }
    }
    
    return imports;
  }

  /// Detect patterns in file content
  List<String> _detectPatternsInContent(String content) {
    final patterns = <String>{};
    
    // State management patterns
    if (content.contains('ConsumerWidget') || content.contains('Consumer')) {
      patterns.add('riverpod');
    }
    if (content.contains('BlocBuilder') || content.contains('BlocListener')) {
      patterns.add('bloc');
    }
    if (content.contains('ChangeNotifier') || content.contains('Provider')) {
      patterns.add('provider');
    }
    
    // Architecture patterns
    if (content.contains('BaseScreen') || content.contains('BaseViewModel')) {
      patterns.add('fly_architecture');
    }
    if (content.contains('ViewModel') && content.contains('Screen')) {
      patterns.add('mvvm');
    }
    
    // UI patterns
    if (content.contains('Scaffold') && content.contains('AppBar')) {
      patterns.add('material_design');
    }
    if (content.contains('CupertinoApp') || content.contains('CupertinoPageScaffold')) {
      patterns.add('cupertino_design');
    }
    
    // Navigation patterns
    if (content.contains('GoRouter') || content.contains('go_router')) {
      patterns.add('go_router');
    }
    if (content.contains('Navigator.push') || content.contains('Navigator.pop')) {
      patterns.add('imperative_navigation');
    }
    
    // Error handling patterns
    if (content.contains('Result<') || content.contains('Either<')) {
      patterns.add('functional_error_handling');
    }
    if (content.contains('try-catch') || content.contains('try {')) {
      patterns.add('exception_handling');
    }
    
    return patterns.toList();
  }
}
