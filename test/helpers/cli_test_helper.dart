import 'dart:io';
import 'package:path/path.dart' as path;

/// Centralized helper for running CLI commands in tests with proper environment setup
class CliTestHelper {
  final Directory testOutputDir;

  CliTestHelper(this.testOutputDir);
  
  /// Run a CLI command with proper environment setup
  Future<ProcessResult> runCliCommand(
    List<String> arguments, {
    Map<String, String>? additionalEnvironment,
  }) async {
    // Find fly.dart path
    final flyDartPath = path.join(
      Directory.current.path,
      'packages',
      'fly_cli',
      'bin',
      'fly.dart',
    );
    
    // Prepare environment variables
    final environment = <String, String>{
      'FLY_OUTPUT_DIR': testOutputDir.path,  // Force CLI to use test directory
      ...?additionalEnvironment,
    };
    
        // Run command
        return await Process.run(
          'dart',
          ['run', flyDartPath, ...arguments],
          workingDirectory: testOutputDir.path,
          environment: environment,
        );
  }
  
  /// Create a project using the CLI
  Future<ProcessResult> createProject(
    String projectName, {
    String template = 'minimal',
    String? organization,
    List<String>? platforms,
    bool jsonOutput = true,
  }) async {
    final args = [
      'create',
      projectName,
      '--template=$template',
      if (organization != null) '--organization=$organization',
      if (platforms != null) '--platforms=${platforms.join(',')}',
      '--output-dir', testOutputDir.path,
      if (jsonOutput) '--output=json',
    ];
    
    return await runCliCommand(args);
  }
  
  /// Add a screen using the CLI
  Future<ProcessResult> addScreen(
    String screenName, {
    String feature = 'home',
    String type = 'list',
    bool withViewModel = false,
    bool withTests = false,
    bool jsonOutput = true,
  }) async {
    final args = [
      'add',
      'screen',
      screenName,
      '--feature=$feature',
      '--type=$type',
      if (withViewModel) '--with-viewmodel',
      if (withTests) '--with-tests',
      '--output-dir', testOutputDir.path,
      if (jsonOutput) '--output=json',
    ];
    
    return await runCliCommand(args);
  }
  
  /// Add a service using the CLI
  Future<ProcessResult> addService(
    String serviceName, {
    String feature = 'core',
    String type = 'api',
    bool withTests = false,
    bool withMocks = false,
    String? baseUrl,
    bool jsonOutput = true,
  }) async {
    final args = [
      'add',
      'service',
      serviceName,
      '--feature=$feature',
      '--type=$type',
      if (withTests) '--with-tests',
      if (withMocks) '--with-mocks',
      if (baseUrl != null) '--base-url=$baseUrl',
      '--output-dir', testOutputDir.path,
      if (jsonOutput) '--output=json',
    ];
    
    return await runCliCommand(args);
  }
  
  /// Run any CLI command with environment variable set
  Future<ProcessResult> runCommand(
    String command, {
    List<String> args = const [],
    bool jsonOutput = true,
  }) async {
    final arguments = [
      command,
      ...args,
      '--output-dir', testOutputDir.path,
      if (jsonOutput) '--output=json',
    ];
    
    return await runCliCommand(arguments);
  }
}
