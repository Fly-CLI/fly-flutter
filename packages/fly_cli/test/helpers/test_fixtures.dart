/// Test fixtures and sample data for Fly CLI tests
class TestFixtures {
  /// Sample project names for testing
  static const List<String> validProjectNames = [
    'my_app',
    'flutter_app',
    'test_project',
    'sample_app',
    'demo_app',
    'hello_world',
    'counter_app',
    'todo_app',
    'weather_app',
    'news_app',
  ];

  /// Invalid project names for testing validation
  static final List<String> invalidProjectNames = [
    'MyApp', // uppercase
    'my-app', // hyphen
    'my.app', // dot
    'my app', // space
    '123app', // starts with number
    'app@test', // special character
    'a', // too short
    'a' * 51, // too long (51 characters)
    '', // empty
    'null', // reserved word
  ];

  /// Sample organization identifiers
  static const List<String> validOrganizations = [
    'com.example',
    'com.company',
    'org.nonprofit',
    'io.github',
    'dev.test',
    'app.sample',
    'net.example',
    'co.company',
  ];

  /// Invalid organization identifiers
  static const List<String> invalidOrganizations = [
    'com', // too short
    'com.example.company.too.long', // too long
    'com.example-company', // hyphen
    'com.example company', // space
    'com.example@company', // special character
    '', // empty
  ];

  /// Available platforms
  static const List<String> allPlatforms = [
    'ios',
    'android',
    'web',
    'macos',
    'windows',
    'linux',
  ];

  /// Default platforms
  static const List<String> defaultPlatforms = [
    'ios',
    'android',
  ];

  /// Available templates
  static const List<String> availableTemplates = [
    'minimal',
    'riverpod',
  ];

  /// Sample template configurations
  static const Map<String, Map<String, dynamic>> templateConfigs = {
    'minimal': {
      'name': 'minimal',
      'version': '1.0.0',
      'description': 'Minimal Flutter project template',
      'minFlutterSdk': '3.0.0',
      'minDartSdk': '3.0.0',
      'features': ['minimal'],
      'packages': ['flutter'],
    },
    'riverpod': {
      'name': 'riverpod',
      'version': '1.0.0',
      'description': 'Flutter project with Riverpod state management',
      'minFlutterSdk': '3.0.0',
      'minDartSdk': '3.0.0',
      'features': ['riverpod', 'state_management'],
      'packages': ['flutter', 'flutter_riverpod', 'riverpod'],
    },
  };

  /// Sample screen names for testing
  static const List<String> validScreenNames = [
    'home',
    'login',
    'profile',
    'settings',
    'dashboard',
    'user_profile',
    'product_list',
    'order_detail',
    'payment_screen',
    'search_results',
  ];

  /// Invalid screen names
  static const List<String> invalidScreenNames = [
    'Home', // uppercase
    'home-screen', // hyphen
    'home.screen', // dot
    'home screen', // space
    '123screen', // starts with number
    'screen@test', // special character
    'a', // too short
    '', // empty
  ];

  /// Sample service names for testing
  static const List<String> validServiceNames = [
    'auth',
    'api',
    'database',
    'storage',
    'notification',
    'payment',
    'analytics',
    'crash_reporting',
    'user_service',
    'product_service',
  ];

  /// Invalid service names
  static const List<String> invalidServiceNames = [
    'Auth', // uppercase
    'auth-service', // hyphen
    'auth.service', // dot
    'auth service', // space
    '123service', // starts with number
    'service@test', // special character
    'a', // too short
    '', // empty
  ];

  /// Sample feature names
  static const List<String> validFeatureNames = [
    'authentication',
    'user_management',
    'product_catalog',
    'shopping_cart',
    'order_management',
    'payment_processing',
    'notification_system',
    'analytics_dashboard',
    'admin_panel',
    'search_functionality',
  ];

  /// Sample package names for testing
  static const List<String> samplePackages = [
    'flutter',
    'flutter_riverpod',
    'riverpod',
    'dio',
    'http',
    'json_annotation',
    'freezed',
    'path',
    'yaml',
    'args',
  ];

  /// Sample JSON responses for testing
  static const Map<String, dynamic> sampleSuccessResponse = {
    'success': true,
    'command': 'create',
    'message': 'Project created successfully',
    'data': {
      'project_name': 'test_app',
      'template': 'riverpod',
      'organization': 'com.example',
      'platforms': ['ios', 'android'],
      'files_generated': 25,
      'duration_ms': 1500,
      'target_directory': '/path/to/test_app',
    },
    'next_steps': [
      {
        'command': 'cd test_app',
        'description': 'Navigate to project directory',
      },
      {
        'command': 'flutter run',
        'description': 'Run the application',
      },
    ],
  };

  static const Map<String, dynamic> sampleErrorResponse = {
    'success': false,
    'command': 'create',
    'message': 'Invalid project name: MyApp',
    'suggestion': 'Project name must contain only lowercase letters, numbers, and underscores',
    'data': {
      'error_type': 'validation_error',
      'field': 'project_name',
      'value': 'MyApp',
    },
  };

  /// Sample command arguments for testing
  static const Map<String, List<String>> sampleCommandArgs = {
    'create_minimal': ['create', 'test_app', '--template=minimal'],
    'create_riverpod': ['create', 'test_app', '--template=riverpod', '--organization=com.test'],
    'create_with_platforms': ['create', 'test_app', '--platforms=ios,android,web'],
    'create_interactive': ['create', 'test_app', '--interactive'],
    'create_from_manifest': ['create', '--from-manifest=manifest.yaml'],
    'doctor': ['doctor'],
    'doctor_fix': ['doctor', '--fix'],
    'version': ['version'],
    'schema': ['schema', 'export'],
    'add_screen': ['add', 'screen', 'login'],
    'add_service': ['add', 'service', 'auth'],
  };

  /// Sample manifest content
  static const String sampleManifestContent = '''
name: test_app
template: riverpod
organization: com.example
platforms:
  - ios
  - android
description: A test Flutter application
features:
  - authentication
  - user_management
packages:
  - flutter_riverpod
  - dio
''';

  /// Sample pubspec.yaml content
  static const String samplePubspecContent = '''
name: test_app
description: A test Flutter application
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  dio: ^5.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
''';

  /// Sample template.yaml content
  static const String sampleTemplateYamlContent = '''
name: test_template
version: 1.0.0
description: A test template for Fly CLI
minFlutterSdk: 3.0.0
minDartSdk: 3.0.0
features:
  - test
  - example
packages:
  - flutter
  - flutter_riverpod
''';

  /// Get a random valid project name
  static String getRandomProjectName() => validProjectNames[
        DateTime.now().millisecondsSinceEpoch % validProjectNames.length];

  /// Get a random valid organization
  static String getRandomOrganization() => validOrganizations[
        DateTime.now().millisecondsSinceEpoch % validOrganizations.length];

  /// Get a random valid screen name
  static String getRandomScreenName() => validScreenNames[
        DateTime.now().millisecondsSinceEpoch % validScreenNames.length];

  /// Get a random valid service name
  static String getRandomServiceName() => validServiceNames[
        DateTime.now().millisecondsSinceEpoch % validServiceNames.length];

  /// Create a test project name with timestamp
  static String createTestProjectName({String? prefix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix ?? 'test'}_app_$timestamp';
  }

  /// Validate project name format
  static bool isValidProjectName(String name) {
    if (name.isEmpty || name.length > 50) return false;
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name);
  }

  /// Validate organization format
  static bool isValidOrganization(String org) {
    if (org.isEmpty || org.length > 100) return false;
    final regex = RegExp(r'^[a-z][a-z0-9.]*$');
    return regex.hasMatch(org);
  }

  /// Validate screen name format
  static bool isValidScreenName(String name) {
    if (name.isEmpty || name.length < 2 || name.length > 50) return false;
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name);
  }

  /// Validate service name format
  static bool isValidServiceName(String name) {
    if (name.isEmpty || name.length < 2 || name.length > 50) return false;
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name);
  }
}
