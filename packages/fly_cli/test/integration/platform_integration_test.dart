import 'dart:io';

import 'package:fly_cli/src/core/utils/platform_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Platform Integration Tests', () {
    group('Cross-Platform Path Handling', () {
      test('path normalization works across platforms', () {
        const windowsPath = r'lib\src\main.dart';
        const unixPath = 'lib/src/main.dart';
        
        final normalizedWindows = PlatformUtils.normalizePath(windowsPath);
        final normalizedUnix = PlatformUtils.normalizePath(unixPath);
        
        expect(normalizedWindows, normalizedUnix);
        expect(normalizedWindows, 'lib/src/main.dart');
      });

      test('mixed separators are handled correctly', () {
        const mixedPath = r'lib\src/main.dart';
        final normalized = PlatformUtils.normalizePath(mixedPath);
        
        expect(normalized, 'lib/src/main.dart');
      });
    });

    group('Config Directory Creation', () {
      test('config directory paths are valid on all platforms', () async {
        final configDir = await PlatformUtils.getConfigDirectory();
        
        expect(configDir, isNotEmpty);
        expect(configDir, contains('fly_cli'));
        
        // Verify path structure
        if (Platform.isWindows) {
          expect(configDir, contains('AppData'));
          expect(configDir, contains('Local'));
        } else if (Platform.isMacOS) {
          expect(configDir, contains('Library'));
          expect(configDir, contains('Application Support'));
        } else {
          expect(configDir, contains('.config'));
        }
      });

      test('ensure config directory creates directories', () async {
        final configDir = await PlatformUtils.ensureConfigDirectory();
        final dir = Directory(configDir);
        
        expect(await dir.exists(), true);
      });

      test('cache and templates directories are under config', () async {
        final configDir = await PlatformUtils.getConfigDirectory();
        final cacheDir = await PlatformUtils.getCacheDirectory();
        final templatesDir = await PlatformUtils.getTemplatesDirectory();
        
        expect(cacheDir, contains(configDir));
        expect(templatesDir, contains(configDir));
        expect(cacheDir, contains('cache'));
        expect(templatesDir, contains('templates'));
      });
    });

    group('Platform Detection', () {
      test('platform detection matches actual platform', () {
        expect(PlatformUtils.isWindows, Platform.isWindows);
        expect(PlatformUtils.isMacOS, Platform.isMacOS);
        expect(PlatformUtils.isLinux, Platform.isLinux);
      });
    });

    group('Line Endings', () {
      test('line ending is correct for platform', () {
        final lineEnding = PlatformUtils.lineEnding;
        
        if (Platform.isWindows) {
          expect(lineEnding, '\r\n');
        } else {
          expect(lineEnding, '\n');
        }
      });
    });
  });
}
