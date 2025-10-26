import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:fly_cli/src/commands/fly_command.dart';

/// Add a screen to your project
class AddScreenCommand extends FlyCommand {
  @override
  String get name => 'screen';

  @override
  String get description => 'Add a screen to your project';

  AddScreenCommand() {
    argParser
      ..addOption(
        'feature',
        help: 'Feature name',
        defaultsTo: 'home',
      )
      ..addFlag(
        'with-viewmodel',
        help: 'Include viewmodel/provider',
        defaultsTo: false,
      )
      ..addFlag(
        'with-tests',
        help: 'Include test files',
        defaultsTo: false,
      );
  }

  @override
  Future<CommandResult> execute() async {
    final screenName = argResults?.rest.isNotEmpty == true ? argResults!.rest.first : null;
    final feature = argResults?['feature'] as String? ?? 'home';
    final withViewModel = argResults?['with-viewmodel'] as bool? ?? false;
    final withTests = argResults?['with-tests'] as bool? ?? false;
    final output = argResults?['output'] as String? ?? 'human';

    if (screenName == null || screenName.isEmpty) {
      return CommandResult.error(
        message: 'Screen name is required',
        suggestion: 'Provide a screen name: fly add screen <screen_name>',
      );
    }

    if (!_isValidName(screenName)) {
      return CommandResult.error(
        message: 'Invalid screen name: $screenName',
        suggestion: 'Screen name must contain only lowercase letters, numbers, and underscores',
      );
    }

    try {
      final stopwatch = Stopwatch()..start();
      
      if (output != 'json') {
        logger.info('Adding screen: $screenName');
        logger.info('Feature: $feature');
        logger.info('With viewmodel: $withViewModel');
        logger.info('With tests: $withTests');
      }

      // Check if we're in a Flutter project
      final pubspecFile = File('pubspec.yaml');
      if (!pubspecFile.existsSync()) {
        return CommandResult.error(
          message: 'Not in a Flutter project directory',
          suggestion: 'Run this command from a Flutter project root directory',
        );
      }

      // Create feature directory structure
      final featureDir = Directory(path.join('lib', 'features', feature));
      if (!featureDir.existsSync()) {
        featureDir.createSync(recursive: true);
      }

      // Create screen directory
      final screenDir = Directory(path.join(featureDir.path, 'presentation'));
      screenDir.createSync(recursive: true);

      // Generate screen file
      final screenFile = File(path.join(screenDir.path, '${screenName}_screen.dart'));
      final screenContent = _generateScreenContent(screenName, feature);
      await screenFile.writeAsString(screenContent);

      int filesGenerated = 1;

      // Generate viewmodel if requested
      if (withViewModel) {
        final providerDir = Directory(path.join(featureDir.path, 'providers'));
        providerDir.createSync(recursive: true);
        
        final providerFile = File(path.join(providerDir.path, '${screenName}_provider.dart'));
        final providerContent = _generateProviderContent(screenName, feature);
        await providerFile.writeAsString(providerContent);
        filesGenerated++;
      }

      // Generate test if requested
      if (withTests) {
        final testDir = Directory(path.join('test', 'features', feature));
        testDir.createSync(recursive: true);
        
        final testFile = File(path.join(testDir.path, '${screenName}_screen_test.dart'));
        final testContent = _generateTestContent(screenName, feature);
        await testFile.writeAsString(testContent);
        filesGenerated++;
      }

      stopwatch.stop();

      final result = CommandResult.success(
        command: 'add screen',
        message: 'Screen added successfully',
        data: {
          'screen_name': screenName,
          'feature': feature,
          'with_viewmodel': withViewModel,
          'with_tests': withTests,
          'files_generated': filesGenerated,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
        nextSteps: [
          const NextStep(
            command: 'flutter run',
            description: 'Run the application to see the new screen',
          ),
        ],
      );
      
      return result;
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to add screen: $e',
        suggestion: 'Check your project structure and try again',
      );
    }
  }

  bool _isValidName(String name) {
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name) && name.length <= 50;
  }

  String _generateScreenContent(String screenName, String feature) {
    final pascalName = _toPascalCase(screenName);
    return '''
import 'package:flutter/material.dart';

class ${pascalName}Screen extends StatelessWidget {
  const ${pascalName}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$screenName'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to $screenName!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 16),
            Text(
              'This is the $screenName screen in the $feature feature.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
''';
  }

  String _generateProviderContent(String screenName, String feature) {
    final pascalName = _toPascalCase(screenName);
    return '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ${pascalName}Notifier extends StateNotifier<${pascalName}State> {
  ${pascalName}Notifier() : super(const ${pascalName}State());

  void updateData() {
    // TODO: Implement your logic here
    state = state.copyWith(isLoading: false);
  }
}

class ${pascalName}State {
  const ${pascalName}State({
    this.isLoading = false,
  });

  final bool isLoading;

  ${pascalName}State copyWith({
    bool? isLoading,
  }) {
    return ${pascalName}State(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final ${screenName}Provider = StateNotifierProvider<${pascalName}Notifier, ${pascalName}State>(
  (ref) => ${pascalName}Notifier(),
);
''';
  }

  String _generateTestContent(String screenName, String feature) {
    final pascalName = _toPascalCase(screenName);
    return '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_tools/features/$feature/presentation/${screenName}_screen.dart';

void main() {
  group('${pascalName}Screen', () {
    testWidgets('should display welcome message', (WidgetTester tester) async {
      // Arrange
      const screen = ${pascalName}Screen();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: screen,
        ),
      );

      // Assert
      expect(find.text('Welcome to $screenName!'), findsOneWidget);
      expect(find.text('This is the $screenName screen in the $feature feature.'), findsOneWidget);
    });
  });
}
''';
  }

  String _toPascalCase(String input) {
    if (input.isEmpty) return input;
    final words = input.split('_');
    return words.map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join('');
  }
}