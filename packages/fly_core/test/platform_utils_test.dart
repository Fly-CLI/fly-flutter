import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fly_core/fly_core.dart';

void main() {
  group('PlatformUtils', () {
    group('Path normalization', () {
      test('normalizes Windows-style paths to forward slashes', () {
        final path = PlatformUtils.normalizePath(r'lib\src\main.dart');
        expect(path, 'lib/src/main.dart');
      });

      test('preserves Unix-style paths', () {
        final path = PlatformUtils.normalizePath('lib/src/main.dart');
        expect(path, 'lib/src/main.dart');
      });

      test('handles mixed separators', () {
        final path = PlatformUtils.normalizePath(r'lib\src/main.dart');
        expect(path, 'lib/src/main.dart');
      });
    });

    group('Platform detection', () {
      test('correctly detects platform', () {
        expect(PlatformUtils.isWindows, Platform.isWindows);
        expect(PlatformUtils.isMacOS, Platform.isMacOS);
        expect(PlatformUtils.isLinux, Platform.isLinux);
      });

      test('only one platform is true', () {
        final platforms = [
          PlatformUtils.isWindows,
          PlatformUtils.isMacOS,
          PlatformUtils.isLinux,
        ];
        expect(platforms.where((p) => p).length, 1);
      });
    });

    group('Line endings', () {
      test('returns correct line ending for platform', () {
        final lineEnding = PlatformUtils.lineEnding;
        if (Platform.isWindows) {
          expect(lineEnding, '\r\n');
        } else {
          expect(lineEnding, '\n');
        }
      });
    });

    group('User home directory', () {
      test('should return user home directory', () async {
        final home = await PlatformUtils.getUserHome();
        expect(home, isNotEmpty);
      });
    });

    group('Config directory', () {
      test('should return config directory with default app name', () async {
        final configDir = await PlatformUtils.getConfigDirectory();
        expect(configDir, isNotEmpty);
        expect(configDir, contains('fly_cli'));
      });

      test('should return config directory with custom app name', () async {
        final configDir = await PlatformUtils.getConfigDirectory(appName: 'my_app');
        expect(configDir, isNotEmpty);
        expect(configDir, contains('my_app'));
        expect(configDir, isNot(contains('fly_cli')));
      });
    });

    group('Cache directory', () {
      test('should return cache directory', () async {
        final cacheDir = await PlatformUtils.getCacheDirectory();
        expect(cacheDir, isNotEmpty);
        expect(cacheDir, contains('cache'));
      });

      test('should return cache directory with custom app name', () async {
        final cacheDir = await PlatformUtils.getCacheDirectory(appName: 'my_app');
        expect(cacheDir, isNotEmpty);
        expect(cacheDir, contains('cache'));
        expect(cacheDir, contains('my_app'));
      });
    });

    group('Default cache directory', () {
      test('should return default cache directory synchronously', () {
        final cacheDir = PlatformUtils.getDefaultCacheDirectory();
        expect(cacheDir, isNotEmpty);
        expect(cacheDir, contains('cache'));
      });

      test('should return default cache directory with custom app name', () {
        final cacheDir = PlatformUtils.getDefaultCacheDirectory(appName: 'my_app');
        expect(cacheDir, isNotEmpty);
        expect(cacheDir, contains('cache'));
        expect(cacheDir, contains('my_app'));
      });
    });

    group('Templates directory', () {
      test('should return templates directory', () async {
        final templatesDir = await PlatformUtils.getTemplatesDirectory();
        expect(templatesDir, isNotEmpty);
        expect(templatesDir, contains('templates'));
      });
    });

    group('Config directory creation', () {
      test('should ensure config directory exists', () async {
        final configDir = await PlatformUtils.ensureConfigDirectory();
        expect(configDir, isNotEmpty);
        expect(await Directory(configDir).exists(), isTrue);
      });
    });

    group('Shell detection', () {
      test('should return shell', () {
        final shell = PlatformUtils.getShell();
        expect(shell, isNotEmpty);
      });

      test('should detect shell type', () {
        final shellType = PlatformUtils.detectShell();
        expect(shellType, isNotEmpty);
        expect(['bash', 'zsh', 'fish', 'powershell', 'cmd', 'unknown'],
            contains(shellType));
      });
    });

    group('CI detection', () {
      test('should detect CI environment', () {
        // This test may or may not be in CI, so we just check it returns a boolean
        final isCI = PlatformUtils.isCI;
        expect(isCI, isA<bool>());
      });
    });
  });
}

