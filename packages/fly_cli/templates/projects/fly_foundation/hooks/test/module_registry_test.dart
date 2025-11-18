import 'package:test/test.dart';

import '../plugins/foundation_model.dart';
import '../plugins/module_registry.dart';
import '../plugins/composition.dart';

void main() {
  group('ModuleRegistry', () {
    late ModuleRegistry registry;

    setUp(() {
      registry = ModuleRegistry();
    });

    test('resolves project module for project mode', () {
      final vars = <String, dynamic>{
        'generation_mode': 'project',
      };

      final configs = registry.resolveModules(GenerationMode.project, vars);

      expect(configs.length, equals(1));
      expect(configs.first.module, isA<ProjectModule>());
      expect(configs.first.disposition, equals(ModuleDisposition.moveToRoot));
    });

    test('resolves feature module for feature mode', () {
      final vars = <String, dynamic>{
        'generation_mode': 'feature',
      };

      final configs = registry.resolveModules(GenerationMode.feature, vars);

      expect(configs.length, equals(1));
      expect(configs.first.module, isA<FeatureModule>());
      expect(
        configs.first.disposition,
        equals(ModuleDisposition.mergeIntoExisting),
      );
    });

    test('resolves service module for service mode', () {
      final vars = <String, dynamic>{
        'generation_mode': 'service',
      };

      final configs = registry.resolveModules(GenerationMode.service, vars);

      expect(configs.length, equals(1));
      expect(configs.first.module, isA<ServiceModule>());
      expect(
        configs.first.disposition,
        equals(ModuleDisposition.mergeIntoExisting),
      );
    });

    test('gets disposition for registered module', () {
      expect(
        registry.getDisposition('project'),
        equals(ModuleDisposition.moveToRoot),
      );
      expect(
        registry.getDisposition('feature'),
        equals(ModuleDisposition.mergeIntoExisting),
      );
      expect(
        registry.getDisposition('service'),
        equals(ModuleDisposition.mergeIntoExisting),
      );
    });

    test('returns null for unknown module', () {
      expect(registry.getDisposition('unknown'), isNull);
    });

    test('lists all registered module names', () {
      final names = registry.registeredModuleNames;

      expect(names, contains('project'));
      expect(names, contains('feature'));
      expect(names, contains('service'));
      expect(names, contains('provider'));
    });
  });
}

