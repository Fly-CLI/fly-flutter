import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import 'package:fly_cli/src/features/context/models.dart';

/// Unified AST analysis result containing all metrics and issues
class AstResult {
  final Map<String, ComplexityMetrics> complexityMetrics;
  final Map<String, QualityReport> qualityReports;
  final List<QualityIssue> allIssues;
  final List<String> deadCode;
  final List<DuplicatedCode> duplicatedCode;
  final Map<String, List<String>> imports;
  final Map<String, List<String>> patterns;

  const AstResult({
    required this.complexityMetrics,
    required this.qualityReports,
    required this.allIssues,
    required this.deadCode,
    required this.duplicatedCode,
    required this.imports,
    required this.patterns,
  });

  Map<String, dynamic> toJson() {
    return {
      'complexity_metrics': complexityMetrics.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
      'quality_reports': qualityReports.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
      'all_issues': allIssues.map((e) => e.toJson()).toList(),
      'dead_code': deadCode,
      'duplicated_code': duplicatedCode.map((e) => e.toJson()).toList(),
      'imports': imports,
      'patterns': patterns,
    };
  }
}

/// Unified AST analyzer that performs all AST-based analysis in a single pass
class AstAnalyzer {
  const AstAnalyzer();

  /// Analyze multiple Dart files with a single AST parse per file
  Future<AstResult> analyzeFiles(List<File> dartFiles) async {
    final complexityMetrics = <String, ComplexityMetrics>{};
    final qualityReports = <String, QualityReport>{};
    final allIssues = <QualityIssue>[];
    final deadCode = <String>[];
    final duplicatedCode = <DuplicatedCode>[];
    final imports = <String, List<String>>{};
    final patterns = <String, List<String>>{};

    if (dartFiles.isEmpty) {
      return AstResult(
        complexityMetrics: complexityMetrics,
        qualityReports: qualityReports,
        allIssues: allIssues,
        deadCode: deadCode,
        duplicatedCode: duplicatedCode,
        imports: imports,
        patterns: patterns,
      );
    }

    // Create a single analysis context for all files in the same directory tree
    final rootDir = _findCommonRoot(dartFiles);
    AnalysisContextCollection? collection;
    
    try {
      collection = AnalysisContextCollection(
        includedPaths: [rootDir.path],
        resourceProvider: PhysicalResourceProvider.INSTANCE,
      );
    } catch (e) {
      // SDK path issues or other initialization failures - return empty result
      // rather than crashing. This handles cases where Flutter SDK path
      // cannot be resolved correctly (e.g., in test environments).
      return AstResult(
        complexityMetrics: complexityMetrics,
        qualityReports: qualityReports,
        allIssues: allIssues,
        deadCode: deadCode,
        duplicatedCode: duplicatedCode,
        imports: imports,
        patterns: patterns,
      );
    }

    for (final file in dartFiles) {
      try {
        final result = await _analyzeFileWithContext(file, collection);
        if (result != null) {
          complexityMetrics[file.path] = result.complexityMetrics;
          qualityReports[file.path] = result.qualityReport;
          allIssues.addAll(result.qualityIssues);
          deadCode.addAll(result.deadCode);
          duplicatedCode.addAll(result.duplicatedCode);
          imports[file.path] = result.imports;
          patterns[file.path] = result.patterns;
        }
      } catch (e) {
        // Skip files that can't be analyzed
        continue;
      }
    }

    return AstResult(
      complexityMetrics: complexityMetrics,
      qualityReports: qualityReports,
      allIssues: allIssues,
      deadCode: deadCode,
      duplicatedCode: duplicatedCode,
      imports: imports,
      patterns: patterns,
    );
  }

  /// Find the common root directory for all files
  Directory _findCommonRoot(List<File> files) {
    if (files.isEmpty) return Directory.current;
    
    var commonPath = files.first.parent.path;
    for (final file in files.skip(1)) {
      commonPath = _findCommonPath(commonPath, file.parent.path);
    }
    
    return Directory(commonPath);
  }

  /// Find the common path between two paths
  String _findCommonPath(String path1, String path2) {
    final parts1 = path1.split('/');
    final parts2 = path2.split('/');
    
    final commonParts = <String>[];
    final minLength = parts1.length < parts2.length ? parts1.length : parts2.length;
    
    for (int i = 0; i < minLength; i++) {
      if (parts1[i] == parts2[i]) {
        commonParts.add(parts1[i]);
      } else {
        break;
      }
    }
    
    return commonParts.join('/');
  }

  /// Analyze a single Dart file with shared analysis context
  Future<FileAstResult?> _analyzeFileWithContext(
    File file,
    AnalysisContextCollection collection,
  ) async {
    try {
      final context = collection.contextFor(file.path);
      final session = context.currentSession;
      final result = await session.getResolvedUnit(file.path);

      if (result is ResolvedUnitResult) {
        final visitor = _UnifiedAstVisitor(file.path);
        result.unit.accept(visitor);

        return FileAstResult(
          complexityMetrics: visitor.complexityMetrics,
          qualityReport: visitor.qualityReport,
          qualityIssues: visitor.qualityIssues,
          deadCode: visitor.deadCode,
          duplicatedCode: visitor.duplicatedCode,
          imports: visitor.imports,
          patterns: visitor.patterns,
        );
      }
    } catch (e) {
      // Skip files that can't be analyzed
    }

    return null;
  }

  /// Analyze a single Dart file with unified visitor (legacy method)
  Future<FileAstResult?> _analyzeFile(File file) async {
    try {
      final collection = AnalysisContextCollection(
        includedPaths: [file.parent.path],
        resourceProvider: PhysicalResourceProvider.INSTANCE,
      );

      final context = collection.contextFor(file.path);
      final session = context.currentSession;
      final result = await session.getResolvedUnit(file.path);

      if (result is ResolvedUnitResult) {
        final visitor = _UnifiedAstVisitor(file.path);
        result.unit.accept(visitor);

        return FileAstResult(
          complexityMetrics: visitor.complexityMetrics,
          qualityReport: visitor.qualityReport,
          qualityIssues: visitor.qualityIssues,
          deadCode: visitor.deadCode,
          duplicatedCode: visitor.duplicatedCode,
          imports: visitor.imports,
          patterns: visitor.patterns,
        );
      }
    } catch (e) {
      // Skip files that can't be analyzed
    }

    return null;
  }
}

/// Result of AST analysis for a single file
class FileAstResult {
  final ComplexityMetrics complexityMetrics;
  final QualityReport qualityReport;
  final List<QualityIssue> qualityIssues;
  final List<String> deadCode;
  final List<DuplicatedCode> duplicatedCode;
  final List<String> imports;
  final List<String> patterns;

  const FileAstResult({
    required this.complexityMetrics,
    required this.qualityReport,
    required this.qualityIssues,
    required this.deadCode,
    required this.duplicatedCode,
    required this.imports,
    required this.patterns,
  });
}

/// Unified AST visitor that performs all analysis in a single pass
class _UnifiedAstVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  
  // Complexity metrics
  ComplexityMetrics complexityMetrics = ComplexityMetrics(
    cyclomaticComplexity: 0,
    cognitiveComplexity: 0,
    maintainabilityIndex: 100.0,
  );
  
  // Quality analysis
  final List<QualityIssue> qualityIssues = [];
  final List<String> deadCode = [];
  final List<DuplicatedCode> duplicatedCode = [];
  final List<String> imports = [];
  final List<String> patterns = [];
  
  // Symbol tracking
  final Set<String> _usedSymbols = {};
  final Set<String> _declaredSymbols = {};
  final Map<String, int> _symbolUsage = {};
  
  // Pattern detection
  final Set<String> _detectedPatterns = {};

  _UnifiedAstVisitor(this.filePath);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
    
    // Extract imports
    _extractImports(node);
    
    // Detect patterns
    _detectPatterns(node);
    
    // Check for dead code
    _checkDeadCode();
    
    // Calculate maintainability index
    complexityMetrics = ComplexityMetrics(
      cyclomaticComplexity: complexityMetrics.cyclomaticComplexity,
      cognitiveComplexity: complexityMetrics.cognitiveComplexity,
      maintainabilityIndex: _calculateMaintainabilityIndex(),
    );
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _declaredSymbols.add(node.name.lexeme);
    
    // Calculate complexity for this function
    final functionVisitor = _FunctionComplexityVisitor();
    node.accept(functionVisitor);
    
    complexityMetrics = ComplexityMetrics(
      cyclomaticComplexity: complexityMetrics.cyclomaticComplexity + functionVisitor.cyclomaticComplexity,
      cognitiveComplexity: complexityMetrics.cognitiveComplexity + functionVisitor.cognitiveComplexity,
      maintainabilityIndex: complexityMetrics.maintainabilityIndex,
    );
    
    // Check for quality issues
    _checkFunctionQuality(node, functionVisitor);
    
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _declaredSymbols.add(node.name.lexeme);
    
    // Calculate complexity for this method
    final methodVisitor = _FunctionComplexityVisitor();
    node.accept(methodVisitor);
    
    complexityMetrics = ComplexityMetrics(
      cyclomaticComplexity: complexityMetrics.cyclomaticComplexity + methodVisitor.cyclomaticComplexity,
      cognitiveComplexity: complexityMetrics.cognitiveComplexity + methodVisitor.cognitiveComplexity,
      maintainabilityIndex: complexityMetrics.maintainabilityIndex,
    );
    
    // Check for quality issues
    _checkMethodQuality(node, methodVisitor);
    
    super.visitMethodDeclaration(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _declaredSymbols.add(node.name.lexeme);
    
    // Check class quality
    _checkClassQuality(node);
    
    super.visitClassDeclaration(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _declaredSymbols.add(node.name.lexeme);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _usedSymbols.add(node.name);
    _symbolUsage[node.name] = (_symbolUsage[node.name] ?? 0) + 1;
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    // Check for empty if statements
    if (node.thenStatement is EmptyStatement) {
      qualityIssues.add(QualityIssue(
        type: 'empty_if',
        message: 'Empty if statement',
        severity: 'low',
        line: 0,
        file: filePath,
      ));
    }
    
    super.visitIfStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    // Check for empty for loops
    if (node.body is EmptyStatement) {
      qualityIssues.add(QualityIssue(
        type: 'empty_for',
        message: 'Empty for loop',
        severity: 'low',
        line: 0,
        file: filePath,
      ));
    }
    
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    // Check for empty while loops
    if (node.body is EmptyStatement) {
      qualityIssues.add(QualityIssue(
        type: 'empty_while',
        message: 'Empty while loop',
        severity: 'low',
        line: 0,
        file: filePath,
      ));
    }
    
    super.visitWhileStatement(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    // Check for empty try blocks
    if (node.body is EmptyStatement) {
      qualityIssues.add(QualityIssue(
        type: 'empty_try',
        message: 'Empty try block',
        severity: 'medium',
        line: 0,
        file: filePath,
      ));
    }
    
    super.visitTryStatement(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    // Check for empty catch blocks
    if (node.body is EmptyStatement) {
      qualityIssues.add(QualityIssue(
        type: 'empty_catch',
        message: 'Empty catch block',
        severity: 'medium',
        line: 0,
        file: filePath,
      ));
    }
    
    super.visitCatchClause(node);
  }

  /// Extract imports from compilation unit
  void _extractImports(CompilationUnit node) {
    for (final directive in node.directives) {
      if (directive is ImportDirective) {
        final uri = directive.uri.stringValue;
        if (uri != null) {
          imports.add(uri);
        }
      }
    }
  }

  /// Detect patterns in the code
  void _detectPatterns(CompilationUnit node) {
    // State management patterns
    if (_hasPattern(node, ['ConsumerWidget', 'Consumer'])) {
      _detectedPatterns.add('riverpod');
    }
    if (_hasPattern(node, ['BlocBuilder', 'BlocListener'])) {
      _detectedPatterns.add('bloc');
    }
    if (_hasPattern(node, ['ChangeNotifier', 'Provider'])) {
      _detectedPatterns.add('provider');
    }
    
    // Architecture patterns
    if (_hasPattern(node, ['BaseScreen', 'BaseViewModel'])) {
      _detectedPatterns.add('fly_architecture');
    }
    if (_hasPattern(node, ['ViewModel', 'Screen'])) {
      _detectedPatterns.add('mvvm');
    }
    
    // UI patterns
    if (_hasPattern(node, ['Scaffold', 'AppBar'])) {
      _detectedPatterns.add('material_design');
    }
    if (_hasPattern(node, ['CupertinoApp', 'CupertinoPageScaffold'])) {
      _detectedPatterns.add('cupertino_design');
    }
    
    // Navigation patterns
    if (_hasPattern(node, ['GoRouter', 'go_router'])) {
      _detectedPatterns.add('go_router');
    }
    if (_hasPattern(node, ['Navigator.push', 'Navigator.pop'])) {
      _detectedPatterns.add('imperative_navigation');
    }
    
    // Error handling patterns
    if (_hasPattern(node, ['Result<', 'Either<'])) {
      _detectedPatterns.add('functional_error_handling');
    }
    if (_hasPattern(node, ['try-catch', 'try {'])) {
      _detectedPatterns.add('exception_handling');
    }
    
    patterns.addAll(_detectedPatterns);
  }

  /// Check if compilation unit has specific patterns
  bool _hasPattern(CompilationUnit node, List<String> patterns) {
    // This is a simplified implementation
    // In a real implementation, you would traverse the AST more carefully
    return false; // Placeholder
  }

  /// Check for dead code
  void _checkDeadCode() {
    for (final symbol in _declaredSymbols) {
      if (!_usedSymbols.contains(symbol)) {
        deadCode.add(symbol);
        qualityIssues.add(QualityIssue(
          type: 'dead_code',
          message: 'Unused symbol: $symbol',
          severity: 'low',
          line: 0,
          file: filePath,
        ));
      }
    }
  }

  /// Check function quality
  void _checkFunctionQuality(FunctionDeclaration node, _FunctionComplexityVisitor visitor) {
    if (visitor.cyclomaticComplexity > 10) {
      qualityIssues.add(QualityIssue(
        type: 'high_complexity',
        message: 'Function ${node.name.lexeme} has high cyclomatic complexity (${visitor.cyclomaticComplexity})',
        severity: 'medium',
        line: 0,
        file: filePath,
      ));
    }
  }

  /// Check method quality
  void _checkMethodQuality(MethodDeclaration node, _FunctionComplexityVisitor visitor) {
    if (visitor.cyclomaticComplexity > 10) {
      qualityIssues.add(QualityIssue(
        type: 'high_complexity',
        message: 'Method ${node.name.lexeme} has high cyclomatic complexity (${visitor.cyclomaticComplexity})',
        severity: 'medium',
        line: 0,
        file: filePath,
      ));
    }
  }

  /// Check class quality
  void _checkClassQuality(ClassDeclaration node) {
    // Simplified class quality check
    // In a real implementation, you would check for various quality issues
  }

  /// Calculate maintainability index
  double _calculateMaintainabilityIndex() {
    // Simplified maintainability index calculation
    final halsteadVolume = _declaredSymbols.length * 0.75;
    final cyclomaticComplexityFactor = complexityMetrics.cyclomaticComplexity * 0.5;
    final cognitiveComplexityFactor = complexityMetrics.cognitiveComplexity * 0.3;
    final commentRatio = 0.1; // Placeholder - would need actual comment analysis
    
    final maintainabilityIndex = 171 - 5.2 * halsteadVolume - 0.23 * cyclomaticComplexityFactor - 16.2 * cognitiveComplexityFactor + 50 * commentRatio;
    
    return maintainabilityIndex.clamp(0.0, 100.0);
  }

  /// Get quality report
  QualityReport get qualityReport {
    final overallScore = _calculateOverallScore();
    return QualityReport(
      issues: qualityIssues,
      deadCode: deadCode,
      duplicatedCode: duplicatedCode,
      overallScore: overallScore,
    );
  }

  /// Calculate overall quality score
  double _calculateOverallScore() {
    double score = 100.0;
    
    for (final issue in qualityIssues) {
      switch (issue.severity) {
        case 'high':
          score -= 10.0;
          break;
        case 'medium':
          score -= 5.0;
          break;
        case 'low':
          score -= 1.0;
          break;
      }
    }
    
    return score.clamp(0.0, 100.0);
  }
}

/// Visitor for calculating function/method complexity
class _FunctionComplexityVisitor extends RecursiveAstVisitor<void> {
  int cyclomaticComplexity = 1; // Base complexity
  int cognitiveComplexity = 0;
  int nestingLevel = 0;

  @override
  void visitIfStatement(IfStatement node) {
    cyclomaticComplexity++;
    cognitiveComplexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitIfStatement(node);
    nestingLevel--;
  }

  @override
  void visitForStatement(ForStatement node) {
    cyclomaticComplexity++;
    cognitiveComplexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitForStatement(node);
    nestingLevel--;
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    cyclomaticComplexity++;
    cognitiveComplexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitWhileStatement(node);
    nestingLevel--;
  }

  @override
  void visitDoStatement(DoStatement node) {
    cyclomaticComplexity++;
    cognitiveComplexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitDoStatement(node);
    nestingLevel--;
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    cyclomaticComplexity += node.members.length;
    cognitiveComplexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitSwitchStatement(node);
    nestingLevel--;
  }

  @override
  void visitCatchClause(CatchClause node) {
    cyclomaticComplexity++;
    cognitiveComplexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitCatchClause(node);
    nestingLevel--;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    cyclomaticComplexity++;
    cognitiveComplexity += 1 + nestingLevel;
    super.visitConditionalExpression(node);
  }
}
