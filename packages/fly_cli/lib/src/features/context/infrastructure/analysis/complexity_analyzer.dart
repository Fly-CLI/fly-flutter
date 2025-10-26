import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import 'package:fly_cli/src/features/context/domain/models/models.dart';

/// Complexity analyzer for calculating code complexity metrics
class ComplexityAnalyzer {
  const ComplexityAnalyzer();

  /// Calculate complexity metrics for a Dart file
  Future<ComplexityMetrics> calculateComplexity(File file) async {
    try {
      final collection = AnalysisContextCollection(
        includedPaths: [file.parent.path],
        resourceProvider: PhysicalResourceProvider.INSTANCE,
      );

      final context = collection.contextFor(file.path);
      final session = context.currentSession;
      final result = await session.getResolvedUnit(file.path);

      if (result is ResolvedUnitResult) {
        final visitor = _ComplexityVisitor();
        result.unit.accept(visitor);
        
        return ComplexityMetrics(
          cyclomaticComplexity: visitor.cyclomaticComplexity,
          cognitiveComplexity: visitor.cognitiveComplexity,
          maintainabilityIndex: _calculateMaintainabilityIndex(
            visitor.cyclomaticComplexity,
            visitor.cognitiveComplexity,
            visitor.linesOfCode,
            visitor.commentLines,
          ),
        );
      }
    } catch (e) {
      // Return default metrics if analysis fails
    }
    
    return const ComplexityMetrics(
      cyclomaticComplexity: 0,
      cognitiveComplexity: 0,
      maintainabilityIndex: 100.0,
    );
  }

  /// Calculate maintainability index
  double _calculateMaintainabilityIndex(
    int cyclomaticComplexity,
    int cognitiveComplexity,
    int linesOfCode,
    int commentLines,
  ) {
    // Simplified maintainability index calculation
    // Real implementation would be more sophisticated
    final halsteadVolume = linesOfCode * 0.75;
    final cyclomaticComplexityFactor = cyclomaticComplexity * 0.5;
    final cognitiveComplexityFactor = cognitiveComplexity * 0.3;
    final commentRatio = commentLines / (linesOfCode + 1);
    
    final maintainabilityIndex = 171 - 5.2 * halsteadVolume - 0.23 * cyclomaticComplexityFactor - 16.2 * cognitiveComplexityFactor + 50 * commentRatio;
    
    return maintainabilityIndex.clamp(0.0, 100.0);
  }
}

/// AST visitor for calculating complexity metrics
class _ComplexityVisitor extends RecursiveAstVisitor<void> {
  int cyclomaticComplexity = 1; // Base complexity
  int cognitiveComplexity = 0;
  int linesOfCode = 0;
  int commentLines = 0;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
    
    // Count lines of code and comments
    _countLinesAndComments(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);
    
    // Each function adds to cyclomatic complexity
    cyclomaticComplexity++;
    
    // Calculate cognitive complexity for this function
    final functionVisitor = _CognitiveComplexityVisitor();
    node.accept(functionVisitor);
    cognitiveComplexity += functionVisitor.complexity;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    
    // Each method adds to cyclomatic complexity
    cyclomaticComplexity++;
    
    // Calculate cognitive complexity for this method
    final methodVisitor = _CognitiveComplexityVisitor();
    node.accept(methodVisitor);
    cognitiveComplexity += methodVisitor.complexity;
  }

  @override
  void visitIfStatement(IfStatement node) {
    cyclomaticComplexity++;
    super.visitIfStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    cyclomaticComplexity++;
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    cyclomaticComplexity++;
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    cyclomaticComplexity++;
    super.visitDoStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    // Each case adds to complexity
    cyclomaticComplexity += node.members.length;
    super.visitSwitchStatement(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    cyclomaticComplexity++;
    super.visitCatchClause(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    cyclomaticComplexity++;
    super.visitConditionalExpression(node);
  }

  void _countLinesAndComments(CompilationUnit node) {
    // Count lines of code (simplified)
    linesOfCode = node.endToken.offset - node.beginToken.offset;
    
    // Count comment lines (simplified) - skip for now
    commentLines = 0;
  }
}

/// Visitor for calculating cognitive complexity
class _CognitiveComplexityVisitor extends RecursiveAstVisitor<void> {
  int complexity = 0;
  int nestingLevel = 0;

  @override
  void visitIfStatement(IfStatement node) {
    complexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitIfStatement(node);
    nestingLevel--;
  }

  @override
  void visitForStatement(ForStatement node) {
    complexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitForStatement(node);
    nestingLevel--;
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    complexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitWhileStatement(node);
    nestingLevel--;
  }

  @override
  void visitDoStatement(DoStatement node) {
    complexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitDoStatement(node);
    nestingLevel--;
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    complexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitSwitchStatement(node);
    nestingLevel--;
  }

  @override
  void visitCatchClause(CatchClause node) {
    complexity += 1 + nestingLevel;
    nestingLevel++;
    super.visitCatchClause(node);
    nestingLevel--;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    complexity += 1 + nestingLevel;
    super.visitConditionalExpression(node);
  }
}