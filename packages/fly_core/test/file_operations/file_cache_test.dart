import 'package:flutter_test/flutter_test.dart';
import 'package:fly_core/src/file_operations/file_cache.dart';

void main() {
  group('FileCache', () {
    test('stores and retrieves content', () {
      final cache = FileCache();
      
      cache.set('test.txt', 'content');
      expect(cache.get('test.txt'), 'content');
    });

    test('returns null for missing entry', () {
      final cache = FileCache();
      
      expect(cache.get('missing.txt'), null);
    });

    test('has returns true for existing entry', () {
      final cache = FileCache();
      
      cache.set('test.txt', 'content');
      expect(cache.has('test.txt'), true);
    });

    test('has returns false for missing entry', () {
      final cache = FileCache();
      
      expect(cache.has('missing.txt'), false);
    });

    test('remove deletes entry', () {
      final cache = FileCache();
      
      cache.set('test.txt', 'content');
      cache.remove('test.txt');
      expect(cache.has('test.txt'), false);
    });

    test('clear removes all entries', () {
      final cache = FileCache();
      
      cache.set('test1.txt', 'content1');
      cache.set('test2.txt', 'content2');
      cache.clear();
      
      expect(cache.size, 0);
      expect(cache.get('test1.txt'), null);
      expect(cache.get('test2.txt'), null);
    });

    test('size returns number of entries', () {
      final cache = FileCache();
      
      expect(cache.size, 0);
      cache.set('test1.txt', 'content1');
      expect(cache.size, 1);
      cache.set('test2.txt', 'content2');
      expect(cache.size, 2);
    });

    test('getStats returns correct statistics', () {
      final cache = FileCache();
      
      cache.set('test1.txt', 'content1');
      cache.set('test2.txt', 'content2');
      
      final stats = cache.getStats();
      expect(stats.entries, 2);
      expect(stats.totalBytes, 16); // 'content1' + 'content2'
    });

    test('evictExpired removes expired entries', () async {
      final cache = FileCache(
        defaultTtl: const Duration(milliseconds: 100),
      );
      
      cache.set('test.txt', 'content');
      expect(cache.has('test.txt'), true);
      
      await Future.delayed(const Duration(milliseconds: 150));
      cache.evictExpired();
      
      expect(cache.has('test.txt'), false);
    });

    test('keys returns all cache keys', () {
      final cache = FileCache();
      
      cache.set('test1.txt', 'content1');
      cache.set('test2.txt', 'content2');
      
      final keys = cache.keys;
      expect(keys.length, 2);
      expect(keys, contains('test1.txt'));
      expect(keys, contains('test2.txt'));
    });

    test('respects custom TTL', () async {
      final cache = FileCache(defaultTtl: const Duration(hours: 1));
      
      cache.set('test.txt', 'content', ttl: const Duration(milliseconds: 100));
      expect(cache.has('test.txt'), true);
      
      await Future.delayed(const Duration(milliseconds: 150));
      cache.evictExpired();
      
      expect(cache.has('test.txt'), false);
    });
  });
}

