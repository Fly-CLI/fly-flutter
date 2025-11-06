import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/src/haptics/haptic_types.dart';

void main() {
  group('HapticType', () {
    test('should have all expected values', () {
      expect(HapticType.values.length, 6);
      expect(HapticType.values, contains(HapticType.none));
      expect(HapticType.values, contains(HapticType.lightImpact));
      expect(HapticType.values, contains(HapticType.mediumImpact));
      expect(HapticType.values, contains(HapticType.heavyImpact));
      expect(HapticType.values, contains(HapticType.selectionClick));
      expect(HapticType.values, contains(HapticType.vibrate));
    });

    test('should have correct enum names', () {
      expect(HapticType.none.name, 'none');
      expect(HapticType.lightImpact.name, 'lightImpact');
      expect(HapticType.mediumImpact.name, 'mediumImpact');
      expect(HapticType.heavyImpact.name, 'heavyImpact');
      expect(HapticType.selectionClick.name, 'selectionClick');
      expect(HapticType.vibrate.name, 'vibrate');
    });
  });
}

