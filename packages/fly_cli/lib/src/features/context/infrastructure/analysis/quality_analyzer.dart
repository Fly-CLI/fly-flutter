import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import 'package:fly_cli/src/features/context/domain/models/models.dart';

/// Quality analyzer for detecting code quality issues
class QualityAnalyzer {
  const QualityAnalyzer();

  /// Analyze code quality for a Dart file
  Future<QualityReport> analyzeQuality(File file) async {
    try {
      final collection = AnalysisContextCollection(
        includedPaths: [file.parent.path],
        resourceProvider: PhysicalResourceProvider.INSTANCE,
      );

      final context = collection.contextFor(file.path);
      final session = context.currentSession;
      final result = await session.getResolvedUnit(file.path);

      if (result is ResolvedUnitResult) {
        final visitor = _QualityVisitor(file.path);
        result.unit.accept(visitor);
        
        return QualityReport(
          issues: visitor.issues,
          deadCode: visitor.deadCode,
          duplicatedCode: visitor.duplicatedCode,
          overallScore: _calculateOverallScore(visitor.issues),
        );
      }
    } catch (e) {
      // Return default report if analysis fails
    }
    
    return const QualityReport(
      issues: [],
      deadCode: [],
      duplicatedCode: [],
      overallScore: 100.0,
    );
  }

  /// Calculate overall quality score
  double _calculateOverallScore(List<QualityIssue> issues) {
    double score = 100.0;
    
    for (final issue in issues) {
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

/// AST visitor for detecting quality issues
class _QualityVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final List<QualityIssue> issues = [];
  final List<String> deadCode = [];
  final List<DuplicatedCode> duplicatedCode = [];
  
  final Set<String> _usedSymbols = {};
  final Set<String> _declaredSymbols = {};

  _QualityVisitor(this.filePath);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
    
    // Check for unused imports
    _checkUnusedImports(node);
    
    // Check for dead code
    _checkDeadCode();
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _declaredSymbols.add(node.name.lexeme);
    
    // Check function length (simplified)
    final lines = _estimateLines(node);
    if (lines > 50) {
      issues.add(QualityIssue(
        type: 'long_function',
        message: 'Function ${node.name.lexeme} is too long ($lines lines)',
        severity: 'medium',
        line: 0, // Simplified - no line numbers
        file: filePath,
      ));
    }
    
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _declaredSymbols.add(node.name.lexeme);
    
    // Check method length (simplified)
    final lines = _estimateLines(node);
    if (lines > 30) {
      issues.add(QualityIssue(
        type: 'long_method',
        message: 'Method ${node.name.lexeme} is too long ($lines lines)',
        severity: 'medium',
        line: 0, // Simplified - no line numbers
        file: filePath,
      ));
    }
    
    super.visitMethodDeclaration(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _declaredSymbols.add(node.name.lexeme);
    
    // Check class length (simplified)
    final lines = _estimateLines(node);
    if (lines > 200) {
      issues.add(QualityIssue(
        type: 'large_class',
        message: 'Class ${node.name.lexeme} is too large ($lines lines)',
        severity: 'medium',
        line: 0, // Simplified - no line numbers
        file: filePath,
      ));
    }
    
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
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    // Check for empty if statements
    if (node.thenStatement is EmptyStatement) {
      issues.add(QualityIssue(
        type: 'empty_if',
        message: 'Empty if statement',
        severity: 'low',
        line: 0, // Simplified - no line numbers
        file: filePath,
      ));
    }
    
    super.visitIfStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    // Check for empty for loops
    if (node.body is EmptyStatement) {
      issues.add(QualityIssue(
        type: 'empty_for',
        message: 'Empty for loop',
        severity: 'low',
        line: 0, // Simplified - no line numbers
        file: filePath,
      ));
    }
    
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    // Check for empty while loops
    if (node.body is EmptyStatement) {
      issues.add(QualityIssue(
        type: 'empty_while',
        message: 'Empty while loop',
        severity: 'low',
        line: 0, // Simplified - no line numbers
        file: filePath,
      ));
    }
    
    super.visitWhileStatement(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    // Check for empty try blocks
    if (node.body is EmptyStatement) {
      issues.add(QualityIssue(
        type: 'empty_try',
        message: 'Empty try block',
        severity: 'medium',
        line: 0, // Simplified - no line numbers
        file: filePath,
      ));
    }
    
    super.visitTryStatement(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    // Check for empty catch blocks
    if (node.body is EmptyStatement) {
      issues.add(QualityIssue(
        type: 'empty_catch',
        message: 'Empty catch block',
        severity: 'medium',
        line: 0, // Simplified - no line numbers
        file: filePath,
      ));
    }
    
    super.visitCatchClause(node);
  }

  int _estimateLines(AstNode node) {
    // Simplified line estimation using offset
    return (node.endToken.offset - node.beginToken.offset) ~/ 50; // Rough estimate
  }

  void _checkUnusedImports(CompilationUnit node) {
    // Simplified unused import detection
    // In a real implementation, this would track symbol usage more accurately
    for (final directive in node.directives) {
      if (directive is ImportDirective) {
        final uri = directive.uri.stringValue;
        if (uri != null && !_isImportUsed(uri)) {
          issues.add(QualityIssue(
            type: 'unused_import',
            message: 'Unused import: $uri',
            severity: 'low',
            line: 0, // Simplified - no line numbers
            file: filePath,
          ));
        }
      }
    }
  }

  bool _isImportUsed(String uri) {
    // Simplified check - in reality, this would be more sophisticated
    return uri.contains('dart:') || uri.contains('package:flutter/');
  }

  void _checkDeadCode() {
    // Find declared symbols that are never used
    for (final symbol in _declaredSymbols) {
      if (!_usedSymbols.contains(symbol)) {
        deadCode.add(symbol);
        issues.add(QualityIssue(
          type: 'dead_code',
          message: 'Unused symbol: $symbol',
          severity: 'low',
          line: 0, // Simplified - no line numbers
          file: filePath,
        ));
      }
    }
  }
}