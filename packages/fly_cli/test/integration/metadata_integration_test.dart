import 'package:fly_cli/src/command_runner.dart';
import 'package:fly_cli/src/features/completion/infrastructure/generators/bash_generator.dart';
import 'package:fly_cli/src/features/completion/infrastructure/generators/fish_generator.dart';
import 'package:fly_cli/src/features/completion/infrastructure/generators/powershell_generator.dart';
import 'package:fly_cli/src/features/completion/infrastructure/generators/zsh_generator.dart';
import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/features/schema/domain/export_format.dart';
import 'package:fly_cli/src/features/schema/infrastructure/exporters/schema_exporter.dart';
import 'package:fly_cli/src/features/schema/infrastructure/exporters/schema_exporter_factory.dart';
import 'package:test/test.dart';

void main() {
  group('Metadata Integration Tests', () {
    late FlyCommandRunner runner;
    late CommandMetadataRegistry registry;

    setUp(() {
      runner = FlyCommandRunner();
      registry = CommandMetadataRegistry.instance;
    });

    tearDown(() {
      registry.clear();
    });

    group('Command Discovery', () {
      test('discovers all commands from runner', () {
        expect(registry.isInitialized, isTrue);
        expect(registry.hasCommand('create'), isTrue);
        expect(registry.hasCommand('doctor'), isTrue);
        expect(registry.hasCommand('version'), isTrue);
        expect(registry.hasCommand('schema'), isTrue);
        expect(registry.hasCommand('completion'), isTrue);
      });

      test('extracts metadata from enriched commands', () {
        final createCommand = registry.getCommand('create');
        expect(createCommand, isNotNull);
        expect(createCommand!.examples, isNotEmpty);
        expect(createCommand.options, isNotEmpty);
        expect(createCommand.arguments, isNotEmpty);
      });

      test('handles commands without metadata gracefully', () {
        // Commands without metadata should still be discoverable
        expect(registry.hasCommand('add'), isTrue);
        final addCommand = registry.getCommand('add');
        expect(addCommand, isNotNull);
        expect(addCommand!.name, equals('add'));
      });
    });

    group('Schema Export Integration', () {
      test('exports CLI spec format', () {
        final exporter = SchemaExporterFactory.getExporter(ExportFormat.cliSpec);
        final schema = exporter.export(registry, const ExportConfig());
        
        expect(schema, contains('"name": "fly"'));
        expect(schema, contains('"commands"'));
        expect(schema, contains('"create"'));
        expect(schema, contains('"doctor"'));
      });

      test('exports JSON Schema format', () {
        final exporter = SchemaExporterFactory.getExporter(ExportFormat.jsonSchema);
        final schema = exporter.export(registry, const ExportConfig());
        
        expect(schema, contains(r'"$schema"'));
        expect(schema, contains('"properties"'));
        expect(schema, contains('"create"'));
      });

      test('exports OpenAPI format', () {
        final exporter = SchemaExporterFactory.getExporter(ExportFormat.openApi);
        final schema = exporter.export(registry, const ExportConfig());
        
        expect(schema, contains('openapi'));
        expect(schema, contains('paths'));
        expect(schema, contains('/create'));
      });

      test('filters commands by name', () {
        final exporter = SchemaExporterFactory.getExporter(ExportFormat.cliSpec);
        const config = ExportConfig(commandFilter: 'create');
        final schema = exporter.export(registry, config);
        
        expect(schema, contains('"create"'));
        expect(schema, isNot(contains('"doctor"'))); // Should not contain other commands
      });
    });

    group('Completion Generation Integration', () {
      test('generates bash completion script', () {
        const bashGenerator = BashCompletionGenerator();
        final script = bashGenerator.generate(registry);
        
        expect(script, contains('_fly_completion()'));
        expect(script, contains('create'));
        expect(script, contains('doctor'));
        expect(script, contains('complete -F _fly_completion fly'));
      });

      test('generates zsh completion script', () {
        const zshGenerator = ZshCompletionGenerator();
        final script = zshGenerator.generate(registry);
        
        expect(script, contains('#compdef fly'));
        expect(script, contains('_fly()'));
        expect(script, contains('create'));
        expect(script, contains('doctor'));
      });

      test('generates fish completion script', () {
        const fishGenerator = FishCompletionGenerator();
        final script = fishGenerator.generate(registry);
        
        expect(script, contains('complete -c fly'));
        expect(script, contains('create'));
        expect(script, contains('doctor'));
      });

      test('generates PowerShell completion script', () {
        const powershellGenerator = PowerShellCompletionGenerator();
        final script = powershellGenerator.generate(registry);
        
        expect(script, contains('Register-ArgumentCompleter'));
        expect(script, contains('fly'));
        expect(script, contains('create'));
        expect(script, contains('doctor'));
      });
    });

    group('Metadata Enrichment', () {
      test('create command has rich metadata', () {
        final createCommand = registry.getCommand('create');
        expect(createCommand, isNotNull);
        
        // Check arguments
        expect(createCommand!.arguments, hasLength(1));
        expect(createCommand.arguments.first.name, equals('project_name'));
        expect(createCommand.arguments.first.required, isTrue);
        
        // Check options
        expect(createCommand.options, isNotEmpty);
        final templateOption = createCommand.options.firstWhere(
          (opt) => opt.name == 'template',
        );
        expect(templateOption.allowedValues, contains('minimal'));
        expect(templateOption.allowedValues, contains('riverpod'));
        
        // Check examples
        expect(createCommand.examples, isNotEmpty);
        expect(createCommand.examples.first.command, contains('fly create'));
      });

      test('doctor command has metadata', () {
        final doctorCommand = registry.getCommand('doctor');
        expect(doctorCommand, isNotNull);
        expect(doctorCommand!.examples, isNotEmpty);
        expect(doctorCommand.options, isNotEmpty);
        
        final fixOption = doctorCommand.options.firstWhere(
          (opt) => opt.name == 'fix',
        );
        expect(fixOption.type, equals(OptionType.flag));
      });

      test('version command has metadata', () {
        final versionCommand = registry.getCommand('version');
        expect(versionCommand, isNotNull);
        expect(versionCommand!.options, isNotEmpty);
        
        final checkUpdatesOption = versionCommand.options.firstWhere(
          (opt) => opt.name == 'check-updates',
        );
        expect(checkUpdatesOption.type, equals(OptionType.flag));
      });
    });

    group('Global Options', () {
      test('registry includes global options', () {
        final globalOptions = registry.getGlobalOptions();
        expect(globalOptions, isNotEmpty);
        
        final verboseOption = globalOptions.firstWhere(
          (opt) => opt.name == 'verbose',
        );
        expect(verboseOption.isGlobal, isTrue);
        expect(verboseOption.type, equals(OptionType.flag));
      });
    });

    group('Subcommand Handling', () {
      test('completion command has options', () {
        final completionCommand = registry.getCommand('completion');
        expect(completionCommand, isNotNull);
        expect(completionCommand!.options, isNotEmpty);
        
        // Check for specific options
        expect(completionCommand.options.any((opt) => opt.name == 'shell'), isTrue);
        expect(completionCommand.options.any((opt) => opt.name == 'install'), isTrue);
        expect(completionCommand.options.any((opt) => opt.name == 'file'), isTrue);
      });
    });

    group('Error Handling', () {
      test('handles empty registry gracefully', () {
        registry.clear();
        expect(registry.isInitialized, isFalse);
        expect(registry.getAllCommands(), isEmpty);
        expect(registry.getGlobalOptions(), isEmpty);
      });

      test('handles non-existent commands gracefully', () {
        expect(registry.hasCommand('nonexistent'), isFalse);
        expect(registry.getCommand('nonexistent'), isNull);
        expect(registry.getSubcommands('nonexistent'), isEmpty);
      });
    });
  });
}
