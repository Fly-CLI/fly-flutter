import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';

/// Standard analyzer plugin that works with flutter analyze
///
/// This is a more complex implementation but integrates with flutter analyze.
class FoundationProjectLintsAnalyzerPlugin extends ServerPlugin {
  FoundationProjectLintsAnalyzerPlugin()
      : super(
          resourceProvider: PhysicalResourceProvider.INSTANCE,
        );

  @override
  String get name => 'foundation_project_lints';

  @override
  String get version => '1.0.0';

  @override
  List<String> get fileGlobsToAnalyze => ['**/*.dart'];

  @override
  Future<void> analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  }) async {
    try {
      // Debug: Log analyzeFile calls
      try {
        final debugFile = File('/tmp/foundation_project_lints_debug.log');
        debugFile.writeAsStringSync(
          'analyzeFile called: $path at ${DateTime.now()}\n',
          mode: FileMode.append,
        );
      } catch (e) {
        // Ignore debug logging errors
      }

      // Only analyze Dart files
      if (!path.endsWith('.dart')) return;
      
      // Get the resolved result
      final session = analysisContext.currentSession;
      final result = await session.getResolvedUnit(path);
      
      // Check if result is ResolvedUnitResult
      if (result is! ResolvedUnitResult) return;
      
      final unit = result.unit;
      final lineInfo = result.lineInfo;

      // Collect errors
      final errors = <AnalysisError>[];

      // Visit the compilation unit to find violations
      final visitor = _ViewModelAsyncAnalyzerVisitor(
        path,
        lineInfo,
        errors,
      );
      unit.accept(visitor);

      // Always send errors list (even if empty) to clear previous errors
      final params = AnalysisErrorsParams(path, errors);
      channel.sendNotification(params.toNotification());
    } catch (e) {
      // Handle errors silently - plugin should not crash analyzer
      // Note: In production, you might want to log this for debugging
    }
  }

  @override
  Future<void> afterNewContextCollection({
    required AnalysisContextCollection contextCollection,
  }) async {
    // Debug: Log context collection
      File('/tmp/foundation_project_lints_debug.log')
      .writeAsStringSync(
        'afterNewContextCollection called at ${DateTime.now()}\n',
        mode: FileMode.append,
      );
    await super.afterNewContextCollection(contextCollection: contextCollection);
  }

  @override
  Future<void> handleAffectedFiles({
    required AnalysisContext analysisContext,
    required List<String> paths,
  }) async {
    // Analyze all affected files when content changes
    await analyzeFiles(
      analysisContext: analysisContext,
      paths: paths,
    );
  }
}

/// Visitor that analyzes ViewModels for async method violations
class _ViewModelAsyncAnalyzerVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo lineInfo;
  final List<AnalysisError> errors;

  _ViewModelAsyncAnalyzerVisitor(
    this.filePath,
    this.lineInfo,
    this.errors,
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!_extendsViewModel(node)) {
      super.visitClassDeclaration(node);
      return;
    }

    // Visit all methods in the class
    for (final member in node.members) {
      if (member is MethodDeclaration) {
        _checkMethod(member);
      }
    }

    super.visitClassDeclaration(node);
  }

  void _checkMethod(MethodDeclaration node) {
    // Check if this is an async method
    if (!_isAsyncMethod(node)) {
      return;
    }

    // Skip if the method is private (starting with _)
    if (node.name.lexeme.startsWith('_')) {
      return;
    }

    // Skip if the method is a getter or setter
    if (node.isGetter || node.isSetter) {
      return;
    }

    // Skip lifecycle methods
    final lifecycleMethods = [
      'onInitialize',
      'onAppear',
      'onDisappear',
      'onDispose'
    ];
    if (lifecycleMethods.contains(node.name.lexeme)) {
      return;
    }

    // Check if the method body uses performAsync
    if (!_usesPerformAsync(node.body)) {
      // Create error using protocol_common AnalysisError
      final location = _createLocation(node.offset, node.length);
      final error = AnalysisError(
        AnalysisErrorSeverity.INFO,
        AnalysisErrorType.LINT,
        location,
        'Async methods in ViewModels must use performAsync() for error handling and loading state management.',
        'view_model_async_must_use_perform_async',
        correction:
            'Wrap your async operation in performAsync() instead of using manual try-catch blocks.',
      );
      errors.add(error);
    }
  }

  Location _createLocation(int offset, int length) {
    // Get line and column information from lineInfo
    final startLocation = lineInfo.getLocation(offset);
    final endLocation = lineInfo.getLocation(offset + length);
    
    return Location(
      filePath,
      offset,
      length,
      startLocation.lineNumber,
      startLocation.columnNumber,
      endLine: endLocation.lineNumber,
      endColumn: endLocation.columnNumber,
    );
  }

  bool _isAsyncMethod(MethodDeclaration node) {
    final body = node.body;
    // ignore: unnecessary_type_check
    if (body is FunctionBody && body.isAsynchronous) {
      return true;
    }

    final returnType = node.returnType;
    if (returnType != null) {
      final typeName = returnType.toString();
      if (typeName.contains('Future')) {
        return true;
      }
    }

    return false;
  }

  bool _usesPerformAsync(AstNode? body) {
    if (body == null) return false;

    if (body is EmptyFunctionBody) {
      return false;
    }

    var usesPerformAsync = false;
    body.visitChildren(_PerformAsyncChecker(
      (found) {
        usesPerformAsync = found;
      },
    ));
    return usesPerformAsync;
  }

  bool _extendsViewModel(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final superclass = extendsClause.superclass;
      // ignore: unnecessary_type_check
      if (superclass is NamedType) {
        final nameNode = superclass.name;
        final name = nameNode.lexeme;
        if (name == 'ViewModel') {
          return true;
        }
      }
      final superclassString = superclass.toString();
      if (superclassString.contains('ViewModel') &&
          !superclassString.contains('ViewModelState')) {
        return true;
      }
    }

    final withClause = node.withClause;
    if (withClause != null) {
      for (final mixin in withClause.mixinTypes) {
        // ignore: unnecessary_type_check
        if (mixin is NamedType) {
          final nameNode = mixin.name;
          final name = nameNode.lexeme;
          if (name == 'ViewModel') {
            return true;
          }
        }
        final mixinString = mixin.toString();
        if (mixinString.contains('ViewModel') &&
            !mixinString.contains('ViewModelState')) {
          return true;
        }
      }
    }

    return false;
  }
}

/// Visitor to check for performAsync usage
class _PerformAsyncChecker extends RecursiveAstVisitor<void> {
  final void Function(bool) _onFound;

  _PerformAsyncChecker(this._onFound);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (methodName == 'performAsync') {
      _onFound(true);
    }
    super.visitMethodInvocation(node);
  }
}

