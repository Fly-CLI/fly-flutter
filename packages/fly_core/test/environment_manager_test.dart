import 'package:flutter_test/flutter_test.dart';
import 'package:fly_core/fly_core.dart';

void main() {
  group('EnvironmentManager', () {
    const env = EnvironmentManager();

    test('exposes product flag (default false in tests)', () {
      expect(env.isProduct, isFalse);
    });

    test('jsonOutputEnabled defaults to false', () {
      expect(env.jsonOutputEnabled, isFalse);
    });

    test('getString/getBool/getInt return defaults when not present', () {
      expect(env.getString(EnvVar.flyLogLevel, defaultValue: 'info'), 'info');
      expect(env.getBool(EnvVar.flyNoColor, defaultValue: false), isFalse);
      expect(env.getInt(EnvVar.flyLogTrace, defaultValue: 0), 0);
    });
  });
}


