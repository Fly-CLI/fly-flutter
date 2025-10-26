import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_state/fly_state.dart';

void main() {
  group('AsyncValueExtension', () {
    test('should check loading state', () {
      final asyncValue = const AsyncValue<String>.loading();
      expect(asyncValue.isLoading, true);
      expect(asyncValue.hasData, false);
      expect(asyncValue.hasAnError, false);
    });

    test('should check data state', () {
      final asyncValue = AsyncValue<String>.data('test');
      expect(asyncValue.isLoading, false);
      expect(asyncValue.hasData, true);
      expect(asyncValue.hasAnError, false);
      expect(asyncValue.dataOrNull, 'test');
    });

    test('should check error state', () {
      final asyncValue = AsyncValue<String>.error('error', StackTrace.current);
      expect(asyncValue.isLoading, false);
      expect(asyncValue.hasData, false);
      expect(asyncValue.hasAnError, true);
      expect(asyncValue.errorOrNull, 'error');
    });

    test('should map data', () {
      const asyncValue = AsyncValue.data(42);
      final mapped = asyncValue.mapData((data) => data * 2);
      expect(mapped.hasData, true);
      expect(mapped.dataOrNull, 84);
    });

    test('should get or else', () {
      final asyncValue = AsyncValue<String>.error('error', StackTrace.current);
      final value = asyncValue.getOrElse('default');
      expect(value, 'default');
    });

    test('should get or else compute', () {
      final asyncValue = AsyncValue<String>.error('error', StackTrace.current);
      final value = asyncValue.getOrElseCompute(() => 'computed');
      expect(value, 'computed');
    });
  });

  group('AsyncValueListExtension', () {
    test('should check empty list', () {
      const asyncValue = AsyncValue.data(<String>[]);
      expect(asyncValue.isEmpty, true);
      expect(asyncValue.isNotEmpty, false);
      expect(asyncValue.length, 0);
    });

    test('should check non-empty list', () {
      const asyncValue = AsyncValue.data(<String>['a', 'b', 'c']);
      expect(asyncValue.isEmpty, false);
      expect(asyncValue.isNotEmpty, true);
      expect(asyncValue.length, 3);
    });

    test('should get first or null', () {
      const asyncValue = AsyncValue.data(<String>['a', 'b', 'c']);
      expect(asyncValue.firstOrNull, 'a');
    });

    test('should get last or null', () {
      const asyncValue = AsyncValue.data(<String>['a', 'b', 'c']);
      expect(asyncValue.lastOrNull, 'c');
    });

    test('should check contains', () {
      const asyncValue = AsyncValue.data(<String>['a', 'b', 'c']);
      expect(asyncValue.contains('b'), true);
      expect(asyncValue.contains('d'), false);
    });

    test('should find first where or null', () {
      const asyncValue = AsyncValue.data(<String>['a', 'b', 'c']);
      expect(asyncValue.firstWhereOrNull((e) => e == 'b'), 'b');
      expect(asyncValue.firstWhereOrNull((e) => e == 'd'), null);
    });

    test('should filter list', () {
      const asyncValue = AsyncValue.data(<int>[1, 2, 3, 4, 5]);
      final filtered = asyncValue.where((e) => e % 2 == 0);
      expect(filtered.hasData, true);
      expect(filtered.dataOrNull, [2, 4]);
    });

    test('should map list', () {
      const asyncValue = AsyncValue.data(<int>[1, 2, 3]);
      final mapped = asyncValue.mapList((e) => e * 2);
      expect(mapped.hasData, true);
      expect(mapped.dataOrNull, [2, 4, 6]);
    });

    test('should sort list', () {
      const asyncValue = AsyncValue.data(<int>[3, 1, 2]);
      final sorted = asyncValue.sorted();
      expect(sorted.hasData, true);
      expect(sorted.dataOrNull, [1, 2, 3]);
    });

    test('should reverse list', () {
      const asyncValue = AsyncValue.data(<int>[1, 2, 3]);
      final reversed = asyncValue.reversed();
      expect(reversed.hasData, true);
      expect(reversed.dataOrNull, [3, 2, 1]);
    });

    test('should take elements', () {
      const asyncValue = AsyncValue.data(<int>[1, 2, 3, 4, 5]);
      final taken = asyncValue.take(3);
      expect(taken.hasData, true);
      expect(taken.dataOrNull, [1, 2, 3]);
    });

    test('should skip elements', () {
      const asyncValue = AsyncValue.data(<int>[1, 2, 3, 4, 5]);
      final skipped = asyncValue.skip(2);
      expect(skipped.hasData, true);
      expect(skipped.dataOrNull, [3, 4, 5]);
    });

    test('should get sublist', () {
      const asyncValue = AsyncValue.data(<int>[1, 2, 3, 4, 5]);
      final sublist = asyncValue.sublist(1, 4);
      expect(sublist.hasData, true);
      expect(sublist.dataOrNull, [2, 3, 4]);
    });
  });

  group('AsyncValueMapExtension', () {
    test('should check empty map', () {
      const asyncValue = AsyncValue.data(<String, int>{});
      expect(asyncValue.isEmpty, true);
      expect(asyncValue.isNotEmpty, false);
      expect(asyncValue.length, 0);
    });

    test('should check non-empty map', () {
      const asyncValue = AsyncValue.data(<String, int>{'a': 1, 'b': 2});
      expect(asyncValue.isEmpty, false);
      expect(asyncValue.isNotEmpty, true);
      expect(asyncValue.length, 2);
    });

    test('should check contains key', () {
      const asyncValue = AsyncValue.data(<String, int>{'a': 1, 'b': 2});
      expect(asyncValue.containsKey('a'), true);
      expect(asyncValue.containsKey('c'), false);
    });

    test('should check contains value', () {
      const asyncValue = AsyncValue.data(<String, int>{'a': 1, 'b': 2});
      expect(asyncValue.containsValue(1), true);
      expect(asyncValue.containsValue(3), false);
    });

    test('should get value by key', () {
      const asyncValue = AsyncValue.data(<String, int>{'a': 1, 'b': 2});
      expect(asyncValue.getValue('a'), 1);
      expect(asyncValue.getValue('c'), null);
    });

    test('should get keys', () {
      const asyncValue = AsyncValue.data(<String, int>{'a': 1, 'b': 2});
      final keys = asyncValue.keys;
      expect(keys.hasData, true);
      expect(keys.dataOrNull, ['a', 'b']);
    });

    test('should get values', () {
      const asyncValue = AsyncValue.data(<String, int>{'a': 1, 'b': 2});
      final values = asyncValue.values;
      expect(values.hasData, true);
      expect(values.dataOrNull, [1, 2]);
    });

    test('should get entries', () {
      const asyncValue = AsyncValue.data(<String, int>{'a': 1, 'b': 2});
      final entries = asyncValue.entries;
      expect(entries.hasData, true);
      expect(entries.dataOrNull?.length, 2);
    });

    test('should map values', () {
      const asyncValue = AsyncValue.data(<String, int>{'a': 1, 'b': 2});
      final mapped = asyncValue.mapValues((value) => value * 2);
      expect(mapped.hasData, true);
      expect(mapped.dataOrNull, {'a': 2, 'b': 4});
    });

    test('should map keys', () {
      const asyncValue = AsyncValue.data(<String, int>{'a': 1, 'b': 2});
      final mapped = asyncValue.mapKeys((key) => key.toUpperCase());
      expect(mapped.hasData, true);
      expect(mapped.dataOrNull, {'A': 1, 'B': 2});
    });

    test('should filter map', () {
      const asyncValue = AsyncValue.data(<String, int>{'a': 1, 'b': 2, 'c': 3});
      final filtered = asyncValue.where((key, value) => value % 2 == 0);
      expect(filtered.hasData, true);
      expect(filtered.dataOrNull, {'b': 2});
    });

    test('should remove null values', () {
      const asyncValue = AsyncValue.data(<String, int?>{'a': 1, 'b': null, 'c': 3});
      final cleaned = asyncValue.removeNullValues();
      expect(cleaned.hasData, true);
      expect(cleaned.dataOrNull, {'a': 1, 'c': 3});
    });
  });
}
