import 'package:flutter_test/flutter_test.dart';
<% if (service_type == 'api') { %>import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
<% } %><% if (service_type == 'analytics') { %>import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mocktail/mocktail.dart';
<% } %><% if (service_type == 'storage') { %>import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
<% } %>import 'package:fly_tools/features/{{feature}}/services/{{service_name}}_service.dart';

<% if (service_type == 'api') { %>class MockHttpClient extends Mock implements http.Client {}
<% } %><% if (service_type == 'analytics') { %>class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}
<% } %><% if (service_type == 'storage') { %>class MockSharedPreferences extends Mock implements SharedPreferences {}
<% } %>

void main() {
  group('{{service_name.pascalCase()}}Service', () {
<% if (service_type == 'api') { %>    late {{service_name.pascalCase()}}Service service;
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      service = {{service_name.pascalCase()}}Service(
        baseUrl: 'https://api.example.com',
        client: mockClient,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('should fetch data successfully', () async {
      // Arrange
      final mockResponse = http.Response('{"data": "test"}', 200);
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await service.fetchData();

      // Assert
      expect(result, equals({'data': 'test'}));
      verify(() => mockClient.get(
        Uri.parse('https://api.example.com/{{service_name}}'),
        headers: {'Content-Type': 'application/json'},
      )).called(1);
    });

    test('should handle fetch data error', () async {
      // Arrange
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 500));

      // Act & Assert
      expect(
        () => service.fetchData(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to fetch data: 500'),
        )),
      );
    });

    test('should post data successfully', () async {
      // Arrange
      final testData = {'name': 'test'};
      final mockResponse = http.Response('{"id": 1}', 201);
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await service.postData(testData);

      // Assert
      expect(result, equals({'id': 1}));
    });
<% } %>

<% if (service_type == 'local') { %>    late {{service_name.pascalCase()}}Service service;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('{{service_name}}_test_');
      service = {{service_name.pascalCase()}}Service(dataPath: '${tempDir.path}/test.json');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should save and load data', () async {
      // Arrange
      final testData = {'key': 'value', 'number': 42};

      // Act
      await service.saveData(testData);
      final loadedData = await service.loadData();

      // Assert
      expect(loadedData, equals(testData));
    });

    test('should return empty map when file does not exist', () async {
      // Act
      final result = await service.loadData();

      // Assert
      expect(result, equals({}));
    });

    test('should delete data', () async {
      // Arrange
      final testData = {'key': 'value'};
      await service.saveData(testData);

      // Act
      await service.deleteData();

      // Assert
      expect(await service.dataExists(), isFalse);
    });
<% } %>

<% if (service_type == 'cache') { %>    late {{service_name.pascalCase()}}Service service;

    setUp(() {
      service = {{service_name.pascalCase()}}Service();
    });

    test('should cache data', () async {
      // Arrange
      const key = 'test_key';
      final testData = {'value': 'test'};

      // Act
      service.setData(key, testData);
      final result = await service.getData(key);

      // Assert
      expect(result, equals(testData));
    });

    test('should return cached data when valid', () async {
      // Arrange
      const key = 'test_key';
      final testData = {'value': 'test'};
      service.setData(key, testData);

      // Act
      final result1 = await service.getData(key);
      final result2 = await service.getData(key);

      // Assert
      expect(result1, equals(testData));
      expect(result2, equals(testData));
    });

    test('should clear cache', () {
      // Arrange
      service.setData('key1', {'value': 'test1'});
      service.setData('key2', {'value': 'test2'});

      // Act
      service.clearCache();

      // Assert
      expect(service.cacheSize, equals(0));
    });
<% } %>

<% if (service_type == 'analytics') { %>    late {{service_name.pascalCase()}}Service service;
    late MockFirebaseAnalytics mockAnalytics;

    setUp(() {
      mockAnalytics = MockFirebaseAnalytics();
      service = {{service_name.pascalCase()}}Service(analytics: mockAnalytics);
    });

    test('should log event', () async {
      // Arrange
      when(() => mockAnalytics.logEvent(name: any(named: 'name'), parameters: any(named: 'parameters')))
          .thenAnswer((_) async {});

      // Act
      await service.logEvent('test_event', parameters: {'key': 'value'});

      // Assert
      verify(() => mockAnalytics.logEvent(
        name: 'test_event',
        parameters: {'key': 'value'},
      )).called(1);
    });

    test('should log screen view', () async {
      // Arrange
      when(() => mockAnalytics.logScreenView(screenName: any(named: 'screenName')))
          .thenAnswer((_) async {});

      // Act
      await service.logScreenView('test_screen');

      // Assert
      verify(() => mockAnalytics.logScreenView(screenName: 'test_screen')).called(1);
    });
<% } %>

<% if (service_type == 'storage') { %>    late {{service_name.pascalCase()}}Service service;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      service = {{service_name.pascalCase()}}Service(prefs: mockPrefs);
    });

    test('should set and get string', () async {
      // Arrange
      when(() => mockPrefs.setString('key', 'value'))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.getString('key'))
          .thenReturn('value');

      // Act
      await service.setString('key', 'value');
      final result = await service.getString('key');

      // Assert
      expect(result, equals('value'));
    });

    test('should set and get bool', () async {
      // Arrange
      when(() => mockPrefs.setBool('key', true))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.getBool('key'))
          .thenReturn(true);

      // Act
      await service.setBool('key', true);
      final result = await service.getBool('key');

      // Assert
      expect(result, equals(true));
    });
<% } %>  });
}
