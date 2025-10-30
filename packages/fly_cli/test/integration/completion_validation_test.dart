import 'package:fly_cli/src/command_runner.dart';
import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/features/completion/generators/bash_generator.dart';
import 'package:fly_cli/src/features/completion/generators/fish_generator.dart';
import 'package:fly_cli/src/features/completion/generators/powershell_generator.dart';
import 'package:fly_cli/src/features/completion/generators/zsh_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Completion Script Validation', () {
    late FlyCommandRunner runner;
    late CommandMetadataRegistry registry;

    setUp(() {
      runner = FlyCommandRunner();
      registry = CommandMetadataRegistry.instance;
    });

    tearDown(() {
      registry.clear();
    });

    group('Bash Completion Validation', () {
      test('generates valid bash syntax', () {
        const generator = BashCompletionGenerator();
        final script = generator.generate(registry);
        
        // Check basic bash function structure
        expect(script, contains('_fly_completion() {'));
        expect(script, contains('COMPREPLY=()'));
        expect(script, contains('complete -F _fly_completion fly'));
        
        // Check variable declarations
        expect(script, contains('local cur prev opts'));
        expect(script, contains(r'cur="${COMP_WORDS[COMP_CWORD]}"'));
        expect(script, contains(r'prev="${COMP_WORDS[COMP_CWORD-1]}"'));
        
        // Check command cases
        expect(script, contains(r'case "${prev}" in'));
        expect(script, contains('create)'));
        expect(script, contains('doctor)'));
        
        // Check completion logic
        expect(script, contains('compgen -W'));
        expect(script, contains('return 0'));
        expect(script, contains('esac'));
      });

      test('includes all commands', () {
        const generator = BashCompletionGenerator();
        final script = generator.generate(registry);
        
        expect(script, contains('create'));
        expect(script, contains('doctor'));
        expect(script, contains('version'));
        expect(script, contains('schema'));
        expect(script, contains('completion'));
      });

      test('includes global options', () {
        const generator = BashCompletionGenerator();
        final script = generator.generate(registry);
        
        expect(script, contains('--verbose'));
        expect(script, contains('--output'));
        expect(script, contains('global_opts'));
      });

      test('handles command-specific options', () {
        const generator = BashCompletionGenerator();
        final script = generator.generate(registry);
        
        // Create command should have template option
        expect(script, contains('--template'));
        
        // Doctor command should have fix option
        expect(script, contains('--fix'));
      });
    });

    group('Zsh Completion Validation', () {
      test('generates valid zsh syntax', () {
        const generator = ZshCompletionGenerator();
        final script = generator.generate(registry);
        
        // Check zsh completion structure
        expect(script, contains('#compdef fly'));
        expect(script, contains('_fly() {'));
        expect(script, contains('_arguments'));
        expect(script, contains(r'_fly "$@"'));
        
        // Check state handling
        expect(script, contains('local context state line'));
        expect(script, contains('typeset -A opt_args'));
        expect(script, contains(r'case $state in'));
        
        // Check command descriptions
        expect(script, contains('commands=('));
        expect(script, contains('_describe'));
      });

      test('includes command-specific functions', () {
        const generator = ZshCompletionGenerator();
        final script = generator.generate(registry);
        
        // Should generate functions for commands with options/subcommands
        expect(script, contains('_fly_create'));
        expect(script, contains('_fly_completion'));
      });

      test('includes global options in _arguments', () {
        const generator = ZshCompletionGenerator();
        final script = generator.generate(registry);
        
        expect(script, contains('--help(-h)'));
        expect(script, contains('--verbose(-v)'));
        expect(script, contains('--output(-f)'));
      });
    });

    group('Fish Completion Validation', () {
      test('generates valid fish syntax', () {
        const generator = FishCompletionGenerator();
        final script = generator.generate(registry);
        
        // Check fish completion structure
        expect(script, contains('complete -c fly'));
        expect(script, contains('__fish_use_subcommand'));
        expect(script, contains('__fish_seen_subcommand_from'));
        
        // Check command completions
        expect(script, contains('-a "create"'));
        expect(script, contains('-a "doctor"'));
        expect(script, contains('-d "Create a new Flutter project"'));
      });

      test('includes global options', () {
        const generator = FishCompletionGenerator();
        final script = generator.generate(registry);
        
        expect(script, contains('-l verbose'));
        expect(script, contains('-l output'));
        expect(script, contains('-s v'));
        expect(script, contains('-s o'));
      });

      test('includes subcommand completions', () {
        const generator = FishCompletionGenerator();
        final script = generator.generate(registry);
        
        // Add command should have subcommands
        expect(script, contains('__fish_seen_subcommand_from add'));
        expect(script, contains('-a "screen"'));
        expect(script, contains('-a "service"'));
      });
    });

    group('PowerShell Completion Validation', () {
      test('generates valid PowerShell syntax', () {
        const generator = PowerShellCompletionGenerator();
        final script = generator.generate(registry);
        
        // Check PowerShell completion structure
        expect(script, contains('Register-ArgumentCompleter'));
        expect(script, contains('-CommandName fly'));
        expect(script, contains('-ScriptBlock'));
        expect(script, contains('param('));
        
        // Check completion logic
        expect(script, contains(r'$wordToComplete'));
        expect(script, contains(r'$completions'));
        expect(script, contains(r'return $completions'));
      });

      test('includes all commands', () {
        const generator = PowerShellCompletionGenerator();
        final script = generator.generate(registry);
        
        expect(script, contains('create'));
        expect(script, contains('doctor'));
        expect(script, contains('version'));
        expect(script, contains('schema'));
        expect(script, contains('completion'));
      });

      test('includes global options', () {
        const generator = PowerShellCompletionGenerator();
        final script = generator.generate(registry);
        
        expect(script, contains('--verbose'));
        expect(script, contains('--output'));
        expect(script, contains('--help'));
      });
    });

    group('Cross-Shell Consistency', () {
      test('all generators include same commands', () {
        final bashScript = const BashCompletionGenerator().generate(registry);
        final zshScript = const ZshCompletionGenerator().generate(registry);
        final fishScript = const FishCompletionGenerator().generate(registry);
        final powershellScript = const PowerShellCompletionGenerator().generate(registry);
        
        final commands = ['create', 'doctor', 'version', 'schema', 'completion'];
        
        for (final command in commands) {
          expect(bashScript, contains(command), reason: 'Bash missing $command');
          expect(zshScript, contains(command), reason: 'Zsh missing $command');
          expect(fishScript, contains(command), reason: 'Fish missing $command');
          expect(powershellScript, contains(command), reason: 'PowerShell missing $command');
        }
      });

      test('all generators include global options', () {
        final bashScript = const BashCompletionGenerator().generate(registry);
        final zshScript = const ZshCompletionGenerator().generate(registry);
        final fishScript = const FishCompletionGenerator().generate(registry);
        final powershellScript = const PowerShellCompletionGenerator().generate(registry);
        
        final globalOptions = ['verbose', 'output', 'help'];
        
        for (final option in globalOptions) {
          expect(bashScript, contains('--$option'), reason: 'Bash missing --$option');
          expect(zshScript, contains('--$option'), reason: 'Zsh missing --$option');
          expect(fishScript, contains('-l $option'), reason: 'Fish missing -l $option');
          expect(powershellScript, contains('--$option'), reason: 'PowerShell missing --$option');
        }
      });
    });

    group('Edge Cases', () {
      test('handles empty registry', () {
        registry.clear();
        
        final bashScript = const BashCompletionGenerator().generate(registry);
        expect(bashScript, contains('_fly_completion()'));
        expect(bashScript, contains('complete -F _fly_completion fly'));
      });

      test('handles commands without options', () {
        const generator = BashCompletionGenerator();
        final script = generator.generate(registry);
        
        // Should still generate completion structure even for simple commands
        expect(script, contains('_fly_completion()'));
        expect(script, contains(r'case "${prev}" in'));
      });

      test('handles special characters in command names', () {
        const generator = BashCompletionGenerator();
        final script = generator.generate(registry);
        
        // Should handle command names with special characters properly
        expect(script, isNot(contains('undefined')));
        expect(script, isNot(contains('null')));
      });
    });
  });
}
