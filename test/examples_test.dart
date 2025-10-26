import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('Example Projects', () {
    test('minimal_example has correct structure', () {
      final projectDir = Directory('examples/minimal_example');
      expect(projectDir.existsSync(), isTrue);
      
      // Check required files
      expect(File(path.join(projectDir.path, 'pubspec.yaml')).existsSync(), isTrue);
      expect(File(path.join(projectDir.path, 'lib', 'main.dart')).existsSync(), isTrue);
      expect(File(path.join(projectDir.path, 'test', 'widget_test.dart')).existsSync(), isTrue);
      expect(File(path.join(projectDir.path, 'README.md')).existsSync(), isTrue);
    });
    
    test('riverpod_example has correct structure', () {
      final projectDir = Directory('examples/riverpod_example');
      expect(projectDir.existsSync(), isTrue);
      
      // Check required files
      expect(File(path.join(projectDir.path, 'pubspec.yaml')).existsSync(), isTrue);
      expect(File(path.join(projectDir.path, 'lib', 'main.dart')).existsSync(), isTrue);
      expect(File(path.join(projectDir.path, 'test', 'widget_test.dart')).existsSync(), isTrue);
      expect(File(path.join(projectDir.path, 'README.md')).existsSync(), isTrue);
      
      // Check feature structure
      expect(Directory(path.join(projectDir.path, 'lib', 'features')).existsSync(), isTrue);
      expect(Directory(path.join(projectDir.path, 'lib', 'core')).existsSync(), isTrue);
      expect(Directory(path.join(projectDir.path, 'lib', 'features', 'home')).existsSync(), isTrue);
      expect(Directory(path.join(projectDir.path, 'lib', 'features', 'profile')).existsSync(), isTrue);
    });
    
    test('minimal_example pubspec.yaml is valid', () {
      final pubspecFile = File('examples/minimal_example/pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);
      
      final content = pubspecFile.readAsStringSync();
      expect(content.contains('name: minimal_example'), isTrue);
      expect(content.contains('description: A minimal Flutter app created with Fly CLI'), isTrue);
      expect(content.contains('flutter:'), isTrue);
    });
    
    test('riverpod_example pubspec.yaml is valid', () {
      final pubspecFile = File('examples/riverpod_example/pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);
      
      final content = pubspecFile.readAsStringSync();
      expect(content.contains('name: riverpod_example'), isTrue);
      expect(content.contains('description: A production-ready Riverpod Flutter app created with Fly CLI'), isTrue);
      expect(content.contains('fly_core:'), isTrue);
      expect(content.contains('fly_networking:'), isTrue);
      expect(content.contains('fly_state:'), isTrue);
      expect(content.contains('riverpod:'), isTrue);
    });
    
    test('minimal_example main.dart is valid', () {
      final mainFile = File('examples/minimal_example/lib/main.dart');
      expect(mainFile.existsSync(), isTrue);
      
      final content = mainFile.readAsStringSync();
      expect(content.contains('MinimalExampleApp'), isTrue);
      expect(content.contains('MinimalExampleHomePage'), isTrue);
      expect(content.contains('_incrementCounter'), isTrue);
    });
    
    test('riverpod_example main.dart is valid', () {
      final mainFile = File('examples/riverpod_example/lib/main.dart');
      expect(mainFile.existsSync(), isTrue);
      
      final content = mainFile.readAsStringSync();
      expect(content.contains('RiverpodExampleApp'), isTrue);
      expect(content.contains('ProviderScope'), isTrue);
      expect(content.contains('appRouterProvider'), isTrue);
    });
    
    test('riverpod_example has proper feature structure', () {
      final homeScreen = File('examples/riverpod_example/lib/features/home/presentation/home_screen.dart');
      expect(homeScreen.existsSync(), isTrue);
      
      final homeProvider = File('examples/riverpod_example/lib/features/home/providers/home_provider.dart');
      expect(homeProvider.existsSync(), isTrue);
      
      final profileScreen = File('examples/riverpod_example/lib/features/profile/presentation/profile_screen.dart');
      expect(profileScreen.existsSync(), isTrue);
      
      final profileProvider = File('examples/riverpod_example/lib/features/profile/providers/profile_provider.dart');
      expect(profileProvider.existsSync(), isTrue);
    });
    
    test('examples have proper test files', () {
      final minimalTest = File('examples/minimal_example/test/widget_test.dart');
      expect(minimalTest.existsSync(), isTrue);
      
      final riverpodTest = File('examples/riverpod_example/test/widget_test.dart');
      expect(riverpodTest.existsSync(), isTrue);
      
      // Check test content
      final minimalTestContent = minimalTest.readAsStringSync();
      expect(minimalTestContent.contains('MinimalExampleApp'), isTrue);
      expect(minimalTestContent.contains('testWidgets'), isTrue);
      
      final riverpodTestContent = riverpodTest.readAsStringSync();
      expect(riverpodTestContent.contains('RiverpodExampleApp'), isTrue);
      expect(riverpodTestContent.contains('ProviderScope'), isTrue);
    });
    
    test('examples have proper README files', () {
      final minimalReadme = File('examples/minimal_example/README.md');
      expect(minimalReadme.existsSync(), isTrue);
      
      final riverpodReadme = File('examples/riverpod_example/README.md');
      expect(riverpodReadme.existsSync(), isTrue);
      
      // Check README content
      final minimalReadmeContent = minimalReadme.readAsStringSync();
      expect(minimalReadmeContent.contains('# Minimal Example'), isTrue);
      expect(minimalReadmeContent.contains('Fly CLI'), isTrue);
      
      final riverpodReadmeContent = riverpodReadme.readAsStringSync();
      expect(riverpodReadmeContent.contains('# Riverpod Example'), isTrue);
      expect(riverpodReadmeContent.contains('Riverpod'), isTrue);
      expect(riverpodReadmeContent.contains('Fly CLI'), isTrue);
    });
  });
  
  group('Shell Completions', () {
    test('bash completion script exists', () {
      final bashCompletion = File('completions/fly.bash');
      expect(bashCompletion.existsSync(), isTrue);
      
      final content = bashCompletion.readAsStringSync();
      expect(content.contains('_fly_completion'), isTrue);
      expect(content.contains('create'), isTrue);
      expect(content.contains('add'), isTrue);
      expect(content.contains('doctor'), isTrue);
    });
    
    test('zsh completion script exists', () {
      final zshCompletion = File('completions/_fly');
      expect(zshCompletion.existsSync(), isTrue);
      
      final content = zshCompletion.readAsStringSync();
      expect(content.contains('_fly()'), isTrue);
      expect(content.contains('create'), isTrue);
      expect(content.contains('add'), isTrue);
      expect(content.contains('doctor'), isTrue);
    });
  });
  
  group('Performance Optimization', () {
    test('performance optimizer exists', () {
      final optimizerFile = File('packages/fly_cli/lib/src/utils/performance_optimizer.dart');
      expect(optimizerFile.existsSync(), isTrue);
      
      final content = optimizerFile.readAsStringSync();
      expect(content.contains('PerformanceOptimizer'), isTrue);
      expect(content.contains('PerformanceMonitor'), isTrue);
      expect(content.contains('optimizeTemplateLoading'), isTrue);
      expect(content.contains('benchmarkTemplateRendering'), isTrue);
    });
  });
}
