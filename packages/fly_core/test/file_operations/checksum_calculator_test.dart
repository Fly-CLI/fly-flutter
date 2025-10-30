import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fly_core/src/file_operations/checksum_calculator.dart';

void main() {
  group('ChecksumCalculator', () {
    const calculator = ChecksumCalculator();

    test('calculateForString returns deterministic hash', () {
      final hash1 = calculator.calculateForString('test');
      final hash2 = calculator.calculateForString('test');
      
      expect(hash1, hash2);
    });

    test('calculateForString returns different hashes for different strings', () {
      final hash1 = calculator.calculateForString('test1');
      final hash2 = calculator.calculateForString('test2');
      
      expect(hash1, isNot(hash2));
    });

    test('calculateForList combines items', () {
      final hash1 = calculator.calculateForList(['a', 'b', 'c']);
      final hash2 = calculator.calculateForList(['a', 'b', 'c']);
      
      expect(hash1, hash2);
    });

    test('calculateForList respects order', () {
      final hash1 = calculator.calculateForList(['a', 'b']);
      final hash2 = calculator.calculateForList(['b', 'a']);
      
      expect(hash1, isNot(hash2));
    });

    test('calculateForMap returns deterministic hash', () {
      final map = {'key1': 'value1', 'key2': 'value2'};
      final hash1 = calculator.calculateForMap(map);
      final hash2 = calculator.calculateForMap(map);
      
      expect(hash1, hash2);
    });

    test('calculateForMap sorts keys', () {
      final map1 = {'b': 'value1', 'a': 'value2'};
      final map2 = {'a': 'value2', 'b': 'value1'};
      final hash1 = calculator.calculateForMap(map1);
      final hash2 = calculator.calculateForMap(map2);
      
      expect(hash1, hash2);
    });

    test('validate returns true for matching hashes', () {
      final hash1 = calculator.calculateForString('test');
      final hash2 = calculator.calculateForString('test');
      
      expect(calculator.validate(hash1, hash2), true);
    });

    test('validate returns false for different hashes', () {
      final hash1 = calculator.calculateForString('test1');
      final hash2 = calculator.calculateForString('test2');
      
      expect(calculator.validate(hash1, hash2), false);
    });

    test('calculateForFile returns empty for non-existent file', () async {
      final tempFile = File('/tmp/test_nonexistent_${DateTime.now().millisecondsSinceEpoch}.txt');
      final hash = await calculator.calculateForFile(tempFile);
      
      expect(hash, '');
    });

    test('calculateForFile returns hash for existing file', () async {
      final tempFile = File('/tmp/test_file_${DateTime.now().millisecondsSinceEpoch}.txt');
      await tempFile.writeAsString('test content');
      
      final hash1 = await calculator.calculateForFile(tempFile);
      final hash2 = await calculator.calculateForFile(tempFile);
      
      expect(hash1, hash2);
      expect(hash1, isNot(''));
      
      // Clean up
      await tempFile.delete();
    });
  });
}

