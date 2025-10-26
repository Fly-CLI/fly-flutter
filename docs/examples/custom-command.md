# Custom Command Implementation Example

This example demonstrates how to create a custom command using the new Fly CLI architecture. We'll build a `deploy` command that shows all the features of the enhanced architecture.

## Command Overview

The `deploy` command will:
- Deploy a Flutter app to various platforms
- Support multiple deployment targets (Firebase, App Store, Google Play)
- Include validation for deployment prerequisites
- Use middleware for logging and metrics
- Implement lifecycle hooks for deployment phases
- Support both interactive and non-interactive modes

## Implementation

### 1. Command Definition

```dart
import 'dart:io';
import 'package:args/args.dart';

import '../features/command_foundation/application/command_base.dart';
import '../features/command_foundation/domain/command_context.dart';
import '../features/command_foundation/domain/command_result.dart';
import '../features/validation/validators/common_validators.dart';
import '../features/middleware/middleware/built_in_middleware.dart';

/// Deploy command for deploying Flutter applications
class DeployCommand extends FlyCommand {
  DeployCommand(CommandContext context) : super(context);

  @override
  String get name => 'deploy';

  @override
  String get description => 'Deploy Flutter application to various platforms';

  @override
  ArgParser get argParser {
    final parser = super.argParser;
    parser
      ..addOption(
        'target',
        abbr: 't',
        help: 'Deployment target',
        allowed: ['firebase', 'appstore', 'playstore', 'web'],
        defaultsTo: 'firebase',
      )
      ..addOption(
        'environment',
        abbr: 'e',
        help: 'Deployment environment',
        allowed: ['development', 'staging', 'production'],
        defaultsTo: 'development',
      )
      ..addFlag(
        'interactive',
        abbr: 'i',
        help: 'Run in interactive mode',
        negatable: false,
      )
      ..addFlag(
        'skip-tests',
        help: 'Skip running tests before deployment',
        negatable: false,
      )
      ..addFlag(
        'force',
        help: 'Force deployment even if checks fail',
        negatable: false,
      );
    return parser;
  }

  @override
  List<CommandValidator> get validators => [
    const FlutterProjectValidator(),
    const EnvironmentValidator(),
    const NetworkValidator(['firebase.google.com', 'api.appstoreconnect.apple.com']),
    const DeploymentPrerequisitesValidator(),
  ];

  @override
  List<CommandMiddleware> get middleware => [
    const LoggingMiddleware(),
    const MetricsMiddleware(),
    const DryRunMiddleware(),
    const DeploymentSafetyMiddleware(),
  ];

  @override
  Future<CommandResult> execute() async {
    final target = argResults!['target'] as String;
    final environment = argResults!['environment'] as String;
    final interactive = argResults!['interactive'] as bool;
    final skipTests = argResults!['skip-tests'] as bool;
    final force = argResults!['force'] as bool;

    if (interactive) {
      return _runInteractiveMode(target, environment, skipTests, force);
    }

    return _deploy(target, environment, skipTests, force);
  }

  /// Run in interactive mode
  Future<CommandResult> _runInteractiveMode(
    String target,
    String environment,
    bool skipTests,
    bool force,
  ) async {
    logger.info('🚀 Flutter App Deployment');
    logger.info('Configure your deployment settings:\n');

    try {
      final prompter = context.interactivePrompt;

      // 1. Deployment target
      final finalTarget = await prompter.promptChoice(
        prompt: 'Deployment target',
        choices: ['firebase', 'appstore', 'playstore', 'web'],
        defaultChoice: target,
      );

      // 2. Environment
      final finalEnvironment = await prompter.promptChoice(
        prompt: 'Deployment environment',
        choices: ['development', 'staging', 'production'],
        defaultChoice: environment,
      );

      // 3. Skip tests
      final finalSkipTests = await prompter.promptConfirm(
        prompt: 'Skip running tests before deployment?',
      );

      // 4. Force deployment
      final finalForce = await prompter.promptConfirm(
        prompt: 'Force deployment (skip safety checks)?',
      );

      // 5. Display summary
      logger.info('\n📋 Deployment Configuration:');
      logger.info('  Target: $finalTarget');
      logger.info('  Environment: $finalEnvironment');
      logger.info('  Skip Tests: $finalSkipTests');
      logger.info('  Force: $finalForce');

      // 6. Confirmation
      final confirmed = await prompter.promptConfirm(
        prompt: '\nProceed with deployment?',
      );

      if (!confirmed) {
        return CommandResult.error(
          message: 'Deployment cancelled',
          suggestion: 'Run the command again to start over',
        );
      }

      logger.info('\nStarting deployment...\n');

      return _deploy(finalTarget, finalEnvironment, finalSkipTests, finalForce);
    } catch (e) {
      return CommandResult.error(
        message: 'Interactive mode failed: $e',
        suggestion: 'Try running without --interactive flag',
      );
    }
  }

  /// Execute deployment
  Future<CommandResult> _deploy(
    String target,
    String environment,
    bool skipTests,
    bool force,
  ) async {
    try {
      // Pre-deployment checks
      if (!skipTests) {
        logger.info('🧪 Running tests...');
        final testResult = await _runTests();
        if (!testResult.success) {
          return CommandResult.error(
            message: 'Tests failed',
            suggestion: 'Fix test failures or use --skip-tests flag',
            metadata: {'test_output': testResult.data},
          );
        }
        logger.info('✅ All tests passed');
      }

      // Build application
      logger.info('🔨 Building application...');
      final buildResult = await _buildApp(target, environment);
      if (!buildResult.success) {
        return CommandResult.error(
          message: 'Build failed',
          suggestion: 'Check your Flutter configuration and try again',
          metadata: {'build_output': buildResult.data},
        );
      }
      logger.info('✅ Build completed');

      // Deploy to target
      logger.info('🚀 Deploying to $target...');
      final deployResult = await _deployToTarget(target, environment, buildResult.data);
      if (!deployResult.success) {
        return CommandResult.error(
          message: 'Deployment failed',
          suggestion: 'Check your deployment configuration and credentials',
          metadata: {'deployment_output': deployResult.data},
        );
      }

      return CommandResult.success(
        command: 'deploy',
        message: 'Deployment completed successfully',
        data: {
          'target': target,
          'environment': environment,
          'build_info': buildResult.data,
          'deployment_info': deployResult.data,
          'timestamp': DateTime.now().toIso8601String(),
        },
        nextSteps: [
          NextStep(
            command: 'fly status --target=$target',
            description: 'Check deployment status',
          ),
          NextStep(
            command: 'fly logs --target=$target',
            description: 'View deployment logs',
          ),
        ],
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Deployment failed: $e',
        suggestion: 'Check your deployment configuration and try again',
      );
    }
  }

  /// Run tests
  Future<CommandResult> _runTests() async {
    try {
      final result = await Process.run('flutter', ['test']);
      return CommandResult(
        success: result.exitCode == 0,
        command: 'test',
        message: result.exitCode == 0 ? 'Tests passed' : 'Tests failed',
        data: {
          'exit_code': result.exitCode,
          'stdout': result.stdout,
          'stderr': result.stderr,
        },
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to run tests: $e',
      );
    }
  }

  /// Build application
  Future<CommandResult> _buildApp(String target, String environment) async {
    try {
      final buildArgs = _getBuildArgs(target, environment);
      final result = await Process.run('flutter', ['build', ...buildArgs]);
      
      return CommandResult(
        success: result.exitCode == 0,
        command: 'build',
        message: result.exitCode == 0 ? 'Build successful' : 'Build failed',
        data: {
          'target': target,
          'environment': environment,
          'exit_code': result.exitCode,
          'stdout': result.stdout,
          'stderr': result.stderr,
        },
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to build app: $e',
      );
    }
  }

  /// Deploy to specific target
  Future<CommandResult> _deployToTarget(
    String target,
    String environment,
    Map<String, dynamic> buildData,
  ) async {
    switch (target) {
      case 'firebase':
        return _deployToFirebase(environment, buildData);
      case 'appstore':
        return _deployToAppStore(environment, buildData);
      case 'playstore':
        return _deployToPlayStore(environment, buildData);
      case 'web':
        return _deployToWeb(environment, buildData);
      default:
        return CommandResult.error(
          message: 'Unsupported deployment target: $target',
        );
    }
  }

  /// Deploy to Firebase
  Future<CommandResult> _deployToFirebase(
    String environment,
    Map<String, dynamic> buildData,
  ) async {
    try {
      logger.info('Deploying to Firebase...');
      
      // Firebase deployment logic would go here
      await Future.delayed(Duration(seconds: 2)); // Simulate deployment
      
      return CommandResult.success(
        command: 'firebase-deploy',
        message: 'Successfully deployed to Firebase',
        data: {
          'environment': environment,
          'url': 'https://your-app.web.app',
          'deployment_id': 'deploy_${DateTime.now().millisecondsSinceEpoch}',
        },
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Firebase deployment failed: $e',
      );
    }
  }

  /// Deploy to App Store
  Future<CommandResult> _deployToAppStore(
    String environment,
    Map<String, dynamic> buildData,
  ) async {
    try {
      logger.info('Deploying to App Store...');
      
      // App Store deployment logic would go here
      await Future.delayed(Duration(seconds: 3)); // Simulate deployment
      
      return CommandResult.success(
        command: 'appstore-deploy',
        message: 'Successfully uploaded to App Store Connect',
        data: {
          'environment': environment,
          'build_number': '1.0.0',
          'upload_id': 'upload_${DateTime.now().millisecondsSinceEpoch}',
        },
      );
    } catch (e) {
      return CommandResult.error(
        message: 'App Store deployment failed: $e',
      );
    }
  }

  /// Deploy to Google Play Store
  Future<CommandResult> _deployToPlayStore(
    String environment,
    Map<String, dynamic> buildData,
  ) async {
    try {
      logger.info('Deploying to Google Play Store...');
      
      // Play Store deployment logic would go here
      await Future.delayed(Duration(seconds: 3)); // Simulate deployment
      
      return CommandResult.success(
        command: 'playstore-deploy',
        message: 'Successfully uploaded to Google Play Console',
        data: {
          'environment': environment,
          'version_code': 1,
          'upload_id': 'upload_${DateTime.now().millisecondsSinceEpoch}',
        },
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Play Store deployment failed: $e',
      );
    }
  }

  /// Deploy to Web
  Future<CommandResult> _deployToWeb(
    String environment,
    Map<String, dynamic> buildData,
  ) async {
    try {
      logger.info('Deploying to Web...');
      
      // Web deployment logic would go here
      await Future.delayed(Duration(seconds: 1)); // Simulate deployment
      
      return CommandResult.success(
        command: 'web-deploy',
        message: 'Successfully deployed to Web',
        data: {
          'environment': environment,
          'url': 'https://your-app.com',
          'deployment_id': 'deploy_${DateTime.now().millisecondsSinceEpoch}',
        },
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Web deployment failed: $e',
      );
    }
  }

  /// Get build arguments for specific target
  List<String> _getBuildArgs(String target, String environment) {
    switch (target) {
      case 'firebase':
        return ['web', '--release'];
      case 'appstore':
        return ['ios', '--release', '--no-codesign'];
      case 'playstore':
        return ['appbundle', '--release'];
      case 'web':
        return ['web', '--release'];
      default:
        return ['apk', '--release'];
    }
  }

  // Lifecycle hooks
  @override
  Future<void> onBeforeExecute(CommandContext context) async {
    logger.info('🔧 Preparing deployment environment...');
  }

  @override
  Future<void> onAfterExecute(CommandContext context, CommandResult result) async {
    if (result.success) {
      logger.info('🎉 Deployment completed successfully!');
    } else {
      logger.err('💥 Deployment failed');
    }
  }

  @override
  Future<void> onError(CommandContext context, Object error, StackTrace stackTrace) async {
    logger.err('💥 Deployment error: $error');
    if (context.verbose) {
      logger.err('Stack trace: $stackTrace');
    }
  }
}
```

### 2. Custom Validator

```dart
/// Validates deployment prerequisites
class DeploymentPrerequisitesValidator extends CommandValidator {
  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final errors = <String>[];
    final target = args['target'] as String? ?? 'firebase';

    // Check target-specific prerequisites
    switch (target) {
      case 'firebase':
        if (!await _checkFirebaseCLI()) {
          errors.add('Firebase CLI not found. Install with: npm install -g firebase-tools');
        }
        break;
      case 'appstore':
        if (!await _checkXcode()) {
          errors.add('Xcode not found. Required for iOS deployment');
        }
        break;
      case 'playstore':
        if (!await _checkAndroidSDK()) {
          errors.add('Android SDK not found. Required for Android deployment');
        }
        break;
    }

    // Check Flutter build tools
    if (!await _checkFlutterBuildTools(target)) {
      errors.add('Flutter build tools not properly configured for $target');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    }

    return ValidationResult.success();
  }

  Future<bool> _checkFirebaseCLI() async {
    try {
      final result = await Process.run('firebase', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkXcode() async {
    try {
      final result = await Process.run('xcodebuild', ['-version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkAndroidSDK() async {
    try {
      final result = await Process.run('flutter', ['doctor', '--android-licenses']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkFlutterBuildTools(String target) async {
    try {
      final result = await Process.run('flutter', ['doctor']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  int get priority => 800; // Run after basic validators
}
```

### 3. Custom Middleware

```dart
/// Middleware for deployment safety checks
class DeploymentSafetyMiddleware extends CommandMiddleware {
  const DeploymentSafetyMiddleware();

  @override
  Future<CommandResult?> handle(CommandContext context, NextMiddleware next) async {
    final args = context.config['args'] as Map<String, dynamic>? ?? {};
    final environment = args['environment'] as String? ?? 'development';
    final force = args['force'] as bool? ?? false;

    // Safety check for production deployments
    if (environment == 'production' && !force) {
      final confirmed = await _confirmProductionDeployment(context);
      if (!confirmed) {
        return CommandResult.error(
          message: 'Production deployment cancelled',
          suggestion: 'Use --force flag to skip confirmation',
        );
      }
    }

    return next();
  }

  Future<bool> _confirmProductionDeployment(CommandContext context) async {
    if (context.quiet) {
      return false; // Don't prompt in quiet mode
    }

    context.logger.warn('⚠️  You are about to deploy to PRODUCTION!');
    context.logger.warn('This will affect live users. Are you sure?');
    
    // In a real implementation, you would use the interactive prompt
    // For this example, we'll return false to be safe
    return false;
  }

  @override
  int get priority => 50; // High priority for safety
}
```

### 4. Command Registration

```dart
// In command_runner.dart
void _registerCommands() {
  // ... existing commands
  
  // Register the new deploy command
  addCommand(DeployCommand(context));
}
```

### 5. Testing

```dart
void main() {
  group('DeployCommand Tests', () {
    late CommandTestHarness harness;

    setUp(() {
      harness = CommandTestHarness();
    });

    test('should deploy to Firebase successfully', () async {
      // Arrange
      final context = harness.createMockContext();
      final command = DeployCommand(context);
      
      // Configure mocks
      harness.container.mockTemplateManager.setFailure(false);

      // Act
      final result = await command.execute();

      // Assert
      harness.assertSuccess(result, expectedMessage: 'Deployment completed');
      harness.assertLogMessages(
        infoMessages: ['Deploying to Firebase...'],
        successMessages: ['Deployment completed successfully'],
      );
    });

    test('should fail deployment when tests fail', () async {
      // Arrange
      final context = harness.createMockContext();
      final command = DeployCommand(context);

      // Act
      final result = await command.execute();

      // Assert
      harness.assertFailure(result, expectedMessage: 'Tests failed');
    });
  });
}
```

## Usage Examples

### Basic Deployment
```bash
fly deploy --target=firebase --environment=development
```

### Interactive Mode
```bash
fly deploy --interactive
```

### Production Deployment
```bash
fly deploy --target=appstore --environment=production --force
```

### Skip Tests
```bash
fly deploy --target=web --skip-tests
```

### Dry Run
```bash
fly deploy --target=playstore --plan
```

## Key Features Demonstrated

1. **Dependency Injection**: Uses `context.templateManager` and `context.interactivePrompt`
2. **Validation Pipeline**: Multiple validators for different aspects
3. **Middleware System**: Logging, metrics, dry-run, and safety middleware
4. **Lifecycle Hooks**: Pre/post execution and error handling
5. **Interactive Mode**: User-friendly configuration
6. **Comprehensive Testing**: Using test harness with mocks
7. **Error Handling**: Meaningful error messages and suggestions
8. **Result Structure**: Rich data and next steps

This example shows how the new architecture enables clean, maintainable, and extensible command implementations while following SOLID principles.
