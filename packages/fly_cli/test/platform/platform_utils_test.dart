import 'dart:io';
import 'package:test/test.dart';
import 'package:fly_cli/src/platform/platform_utils.dart' as platform_utils;

void main() {
  group('PlatformUtils', () {
    group('Path normalization', () {
      test('normalizes Windows-style paths to forward slashes', () {
        final path = platform_utils.PlatformUtils.normalizePath('lib\\src\\main.dart');
        expect(path, 'lib/src/main.dart');
      });

      test('preserves Unix-style paths', () {
        final path = platform_utils.PlatformUtils.normalizePath('lib/src/main.dart');
        expect(path, 'lib/src/main.dart');
      });

      test('handles mixed separators', () {
        final path = platform_utils.PlatformUtils.normalizePath('lib\\src/main.dart');
        expect(path, 'lib/src/main.dart');
      });
    });

    group('Platform detection', () {
      test('correctly detects platform', () {
        expect(platform_utils.PlatformUtils.isWindows, Platform.isWindows);
        expect(platform_utils.PlatformUtils.isMacOS, Platform.isMacOS);
        expect(platform_utils.PlatformUtils.isLinux, Platform.isLinux);
      });

      test('only one platform is true', () {
        final platforms = [
          platform_utils.PlatformUtils.isWindows,
          platform_utils.PlatformUtils.isMacOS,
          platform_utils.PlatformUtils.isLinux,
        ];
        expect(platforms.where((p) => p).length, 1);
      });
    });

    group('Line endings', () {
      test('returns correct line ending for platform', () {
        final lineEnding = platform_utils.PlatformUtils.lineEnding;
        if (Platform.isWindows) {
          expect(lineEnding, '\r\n');
        } else {
          expect(lineEnding, '\n');
        }
      });
    });

    group('User home directory', () {
      test('returns correct home directory', () async {
        final home = await platform_utils.PlatformUtils.getUserHome();
        expect(home, isNotEmpty);
        
        if (Platform.isWindows) {
          // Windows uses USERPROFILE
          expect(Platform.environment['USERPROFILE'], isNotNull);
        } else {
          // Unix-like systems use HOME
          expect(Platform.environment['HOME'], isNotNull);
        }
      });
    });

    group('Config directory', () {
      test('returns platform-specific config directory', () async {
        final configDir = await platform_utils.PlatformUtils.getConfigDirectory();
        
        if (Platform.isWindows) {
          expect(configDir, contains('AppData'));
          expect(configDir, contains('Local'));
          expect(configDir, contains('fly_cli'));
        } else if (Platform.isMacOS) {
          expect(configDir, contains('Library'));
          expect(configDir, contains('Application Support'));
          expect(configDir, contains('fly_cli'));
        } else {
          // Linux and other Unix-like
          expect(configDir, contains('.config'));
          expect(configDir, contains('fly_cli'));
        }
      });

      test('config directory path format is valid', () async {
        final configDir = await platform_utils.PlatformUtils.getConfigDirectory();
        
        // Should not contain double slashes (except protocol)
        expect(configDir.replaceAll('\\', '/'), isNot(contains('//')));
        
        // Should end with fly_cli
        expect(configDir, endsWith('fly_cli'));
      });
    });

    group('Cache directory', () {
      test('cache directory is under config directory', () async {
        final configDir = await platform_utils.PlatformUtils.getConfigDirectory();
        final cacheDir = await platform_utils.PlatformUtils.getCacheDirectory();
        
        expect(cacheDir, contains(configDir));
        expect(cacheDir, contains('cache'));
      });
    });

    group('Templates directory', () {
      test('templates directory is under config directory', () async {
        final configDir = await platform_utils.PlatformUtils.getConfigDirectory();
        final templatesDir = await platform_utils.PlatformUtils.getTemplatesDirectory();
        
        expect(templatesDir, contains(configDir));
        expect(templatesDir, contains('templates'));
      });
    });

    group('Ensure config directory', () {
      test('creates config directory if it does not exist', () async {
        final configDir = await platform_utils.PlatformUtils.ensureConfigDirectory();
        
        expect(Directory(configDir).existsSync(), true);
      });
    });

    group('Shell detection', () {
      test('returns shell for current platform', () {
        final shell = platform_utils.PlatformUtils.getShell();
        expect(shell, isNotEmpty);
        
        if (Platform.isWindows) {
          // Windows should return COMSPEC or default to powershell
          expect(shell, anyOf(contains('cmd.exe'), contains('powershell.exe')));
        } else {
          // Unix-like should return SHELL or default to /bin/bash
          expect(shell, isNotEmpty);
        }
      });
    });

    group('CI detection', () {
      test('detects CI environment', () {
        final isCI = platform_utils.PlatformUtils.isCI;
        
        // Check if running in CI
        final hasCIVar = Platform.environment.containsKey('CI') ||
            Platform.environment.containsKey('CONTINUOUS_INTEGRATION');
        
        expect(isCI, hasCIVar);
      });
    });
  });
}
