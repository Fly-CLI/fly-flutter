<% if (service_type == 'api') { %>import 'dart:convert';
import 'package:http/http.dart' as http;
<% if (with_interceptors) { %>import 'package:dio/dio.dart';
<% } %><% } %><% if (service_type == 'local') { %>import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
<% } %><% if (service_type == 'cache') { %>import 'dart:convert';
<% } %><% if (service_type == 'analytics') { %>import 'package:firebase_analytics/firebase_analytics.dart';
<% } %><% if (service_type == 'storage') { %>import 'package:shared_preferences/shared_preferences.dart';
<% } %>

class {{service_name.pascalCase()}}Service {
<% if (service_type == 'api') { %>  final http.Client _client;
  final String baseUrl;
<% if (with_interceptors) { %>  final Dio _dio;
<% } %>

  {{service_name.pascalCase()}}Service({
    required this.baseUrl,
    http.Client? client,
<% if (with_interceptors) { %>    Dio? dio,
<% } %>  }) : _client = client ?? http.Client()<% if (with_interceptors) { %>,
        _dio = dio ?? Dio()<% } %>;

<% if (with_interceptors) { %>  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add authentication token
          options.headers['Authorization'] = 'Bearer YOUR_TOKEN';
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log successful responses
          print('Response: \${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          // Handle errors
          print('Error: \${error.message}');
          handler.next(error);
        },
      ),
    );
  }
<% } %>

  Future<Map<String, dynamic>> fetchData() async {
    try {
      final response = await _client.get(
        Uri.parse('\$baseUrl/{{service_name}}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch data: \${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  Future<Map<String, dynamic>> postData(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        Uri.parse('\$baseUrl/{{service_name}}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to post data: \${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  Future<Map<String, dynamic>> updateData(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        Uri.parse('\$baseUrl/{{service_name}}/\$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update data: \${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  Future<void> deleteData(String id) async {
    try {
      final response = await _client.delete(
        Uri.parse('\$baseUrl/{{service_name}}/\$id'),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete data: \${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  void dispose() {
    _client.close();
<% if (with_interceptors) { %>    _dio.close();
<% } %>  }
<% } %>

<% if (service_type == 'local') { %>  final String _dataPath;

  {{service_name.pascalCase()}}Service({String? dataPath}) 
      : _dataPath = dataPath ?? path.join(Directory.current.path, 'data', '{{service_name}}.json');

  Future<Map<String, dynamic>> loadData() async {
    try {
      final file = File(_dataPath);
      if (!await file.exists()) {
        return {};
      }
      
      final content = await file.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load data: \$e');
    }
  }

  Future<void> saveData(Map<String, dynamic> data) async {
    try {
      final file = File(_dataPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(json.encode(data));
    } catch (e) {
      throw Exception('Failed to save data: \$e');
    }
  }

  Future<void> deleteData() async {
    try {
      final file = File(_dataPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete data: \$e');
    }
  }

  Future<bool> dataExists() async {
    final file = File(_dataPath);
    return await file.exists();
  }
<% } %>

<% if (service_type == 'cache') { %>  final Map<String, dynamic> _cache = {};
  final Duration _cacheExpiry;
  final Map<String, DateTime> _cacheTimestamps = {};

  {{service_name.pascalCase()}}Service({Duration? cacheExpiry}) 
      : _cacheExpiry = cacheExpiry ?? const Duration(hours: 1);

  Future<Map<String, dynamic>> getData(String key) async {
    if (_isCacheValid(key)) {
      return _cache[key] as Map<String, dynamic>;
    }
    
    // TODO: Implement actual data fetching logic
    final data = <String, dynamic>{};
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    
    return data;
  }

  void setData(String key, Map<String, dynamic> data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  void removeData(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  int get cacheSize => _cache.length;
<% } %>

<% if (service_type == 'analytics') { %>  final FirebaseAnalytics _analytics;

  {{service_name.pascalCase()}}Service({FirebaseAnalytics? analytics}) 
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e) {
      throw Exception('Failed to log event: \$e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      throw Exception('Failed to log screen view: \$e');
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      throw Exception('Failed to set user property: \$e');
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      throw Exception('Failed to set user ID: \$e');
    }
  }
<% } %>

<% if (service_type == 'storage') { %>  final SharedPreferences _prefs;

  {{service_name.pascalCase()}}Service({SharedPreferences? prefs}) 
      : _prefs = prefs ?? throw Exception('SharedPreferences must be initialized');

  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (e) {
      throw Exception('Failed to set string: \$e');
    }
  }

  Future<String?> getString(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e) {
      throw Exception('Failed to get string: \$e');
    }
  }

  Future<bool> setInt(String key, int value) async {
    try {
      return await _prefs.setInt(key, value);
    } catch (e) {
      throw Exception('Failed to set int: \$e');
    }
  }

  Future<int?> getInt(String key) async {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      throw Exception('Failed to get int: \$e');
    }
  }

  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs.setBool(key, value);
    } catch (e) {
      throw Exception('Failed to set bool: \$e');
    }
  }

  Future<bool?> getBool(String key) async {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      throw Exception('Failed to get bool: \$e');
    }
  }

  Future<bool> remove(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e) {
      throw Exception('Failed to remove key: \$e');
    }
  }

  Future<bool> clear() async {
    try {
      return await _prefs.clear();
    } catch (e) {
      throw Exception('Failed to clear storage: \$e');
    }
  }
<% } %>}
