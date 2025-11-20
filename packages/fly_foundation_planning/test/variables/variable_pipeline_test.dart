import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/logger.dart';
import 'package:fly_foundation_planning/src/variables/generation_context.dart';
import 'package:fly_foundation_planning/src/variables/variable_bag.dart';
import 'package:fly_foundation_planning/src/variables/variable_deriver.dart';
import 'package:fly_foundation_planning/src/variables/variable_pipeline.dart';
import 'package:test/test.dart';

class TestDeriver implements VariableDeriver {
  final String id;
  final bool Function(GenerationContext)? supportsFn;
  final VariableBag Function(GenerationContext, VariableBag, PlanningLogger)? deriveFn;

  const TestDeriver({
    required this.id,
    this.supportsFn,
    this.deriveFn,
  });

  @override
  bool supports(GenerationContext ctx) =>
      supportsFn?.call(ctx) ?? true;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) =>
      deriveFn?.call(ctx, current, logger) ??
      current.set(id, true);
}

void main() {
  group('VariablePipeline', () {
    test('runs all derivers that support the context', () {
      final deriver1 = TestDeriver(id: 'deriver1', supportsFn: (_) => true);
      final deriver2 = TestDeriver(id: 'deriver2', supportsFn: (_) => true);
      final deriver3 = TestDeriver(id: 'deriver3', supportsFn: (_) => false);

      final pipeline = VariablePipeline([deriver1, deriver2, deriver3]);
      final ctx = GenerationContext.fromVars({'name': 'test'});
      final logger = NoOpLogger();

      final result = pipeline.run(ctx, logger);

      expect(result.get<bool>('deriver1'), isTrue);
      expect(result.get<bool>('deriver2'), isTrue);
      expect(result.get<bool>('deriver3'), isNull);
    });

    test('runs derivers in order', () {
      final deriver1 = TestDeriver(
        id: 'deriver1',
        deriveFn: (_, bag, __) => bag.set('order', 'first'),
      );
      final deriver2 = TestDeriver(
        id: 'deriver2',
        deriveFn: (_, bag, __) => bag.set('order', 'second'),
      );

      final pipeline = VariablePipeline([deriver1, deriver2]);
      final ctx = GenerationContext.fromVars({'name': 'test'});
      final logger = NoOpLogger();

      final result = pipeline.run(ctx, logger);

      // Last deriver should win
      expect(result.get<String>('order'), 'second');
    });

    test('derivers receive accumulated bag state', () {
      final deriver1 = TestDeriver(
        id: 'deriver1',
        deriveFn: (_, bag, __) => bag.set('count', 1),
      );
      final deriver2 = TestDeriver(
        id: 'deriver2',
        deriveFn: (_, bag, __) {
          final current = bag.get<int>('count') ?? 0;
          return bag.set('count', current + 1);
        },
      );

      final pipeline = VariablePipeline([deriver1, deriver2]);
      final ctx = GenerationContext.fromVars({'name': 'test'});
      final logger = NoOpLogger();

      final result = pipeline.run(ctx, logger);

      expect(result.get<int>('count'), 2);
    });

    test('conditionally runs derivers based on context', () {
      final projectDeriver = TestDeriver(
        id: 'project',
        supportsFn: (ctx) => ctx.mode == GenerationMode.project,
      );
      final featureDeriver = TestDeriver(
        id: 'feature',
        supportsFn: (ctx) => ctx.mode == GenerationMode.feature,
      );

      final pipeline = VariablePipeline([projectDeriver, featureDeriver]);
      final ctx = GenerationContext.fromVars(
        {'name': 'test', 'generation_mode': 'project'},
      );
      final logger = NoOpLogger();

      final result = pipeline.run(ctx, logger);

      expect(result.get<bool>('project'), isTrue);
      expect(result.get<bool>('feature'), isNull);
    });

    test('propagates exceptions from derivers', () {
      final deriver = TestDeriver(
        id: 'error',
        deriveFn: (_, __, ___) => throw Exception('Derivation failed'),
      );

      final pipeline = VariablePipeline([deriver]);
      final ctx = GenerationContext.fromVars({'name': 'test'});
      final logger = NoOpLogger();

      expect(
        () => pipeline.run(ctx, logger),
        throwsA(isA<Exception>()),
      );
    });
  });
}

