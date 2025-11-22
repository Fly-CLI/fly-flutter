import 'package:fly_brick_composer/src/variables/variable_bag.dart';
import 'package:test/test.dart';

void main() {
  group('VariableBag', () {
    test('empty creates an empty bag', () {
      final bag = VariableBag.empty();
      expect(bag.keys, isEmpty);
      expect(bag.toMap(), isEmpty);
    });

    test('set adds a value', () {
      final bag = VariableBag.empty().set('key1', 'value1');
      expect(bag.get<String>('key1'), 'value1');
      expect(bag.containsKey('key1'), isTrue);
    });

    test('set returns a new bag (immutability)', () {
      final bag1 = VariableBag.empty().set('key1', 'value1');
      final bag2 = bag1.set('key2', 'value2');
      expect(bag1.containsKey('key2'), isFalse);
      expect(bag2.containsKey('key2'), isTrue);
    });

    test('set with null returns original bag', () {
      final bag1 = VariableBag.empty().set('key1', 'value1');
      final bag2 = bag1.set('key2', null);
      expect(bag1, equals(bag2));
    });

    test('setAll adds multiple values', () {
      final bag = VariableBag.empty().setAll({
        'key1': 'value1',
        'key2': 42,
        'key3': true,
      });
      expect(bag.get<String>('key1'), 'value1');
      expect(bag.get<int>('key2'), 42);
      expect(bag.get<bool>('key3'), true);
    });

    test('merge combines two bags', () {
      final bag1 = VariableBag.empty().setAll({'key1': 'value1', 'key2': 'value2'});
      final bag2 = VariableBag.empty().setAll({'key2': 'overridden', 'key3': 'value3'});
      final merged = bag1.merge(bag2);
      expect(merged.get<String>('key1'), 'value1');
      expect(merged.get<String>('key2'), 'overridden'); // bag2 takes precedence
      expect(merged.get<String>('key3'), 'value3');
    });

    test('get returns null for non-existent key', () {
      final bag = VariableBag.empty();
      expect(bag.get<String>('nonexistent'), isNull);
    });

    test('get returns null for wrong type', () {
      final bag = VariableBag.empty().set('key1', 'string');
      expect(bag.get<int>('key1'), isNull);
    });

    test('toMap returns unmodifiable map', () {
      final bag = VariableBag.empty().set('key1', 'value1');
      final map = bag.toMap();
      expect(() => map['key2'] = 'value2', throwsA(isA<UnsupportedError>()));
    });

    test('equality works correctly', () {
      final bag1 = VariableBag.empty().setAll({'key1': 'value1', 'key2': 42});
      final bag2 = VariableBag.empty().setAll({'key1': 'value1', 'key2': 42});
      final bag3 = VariableBag.empty().setAll({'key1': 'value1', 'key2': 43});
      expect(bag1, equals(bag2));
      expect(bag1, isNot(equals(bag3)));
    });

    test('fromMap creates bag from map', () {
      final bag = VariableBag.fromMap({'key1': 'value1', 'key2': 42});
      expect(bag.get<String>('key1'), 'value1');
      expect(bag.get<int>('key2'), 42);
    });
  });
}

