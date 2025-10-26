import 'dart:io';

import 'package:args/args.dart';
import 'fly_command.dart';

/// Show version information and check for updates
class VersionCommand extends FlyCommand {
  @override
  String get name => 'version';

  @override
  String get description => 'Show version information';

  @override
  ArgParser get argParser {
    final parser = super.argParser;
    parser.addFlag(
      'check-updates',
      help: 'Check for available updates',
      negatable: false,
    );
    return parser;
  }

  @override
  Future<CommandResult> execute() async {
    final checkUpdates = argResults?['check-updates'] as bool? ?? false;

    if (planMode) {
      return _createPlan(checkUpdates);
    }

    try {
      final currentVersion = _getCurrentVersion();
      final versionInfo = {
        'version': currentVersion,
        'build_number': _getBuildNumber(),
        'git_commit': _getGitCommit(),
        'build_date': _getBuildDate(),
      };

      if (checkUpdates) {
        final updateInfo = await _checkForUpdates(currentVersion);
        versionInfo.addAll(updateInfo.map((key, value) => MapEntry(key, value?.toString())));
      }

      if (jsonOutput) {
        return CommandResult.success(
          command: 'version',
          message: 'Version information retrieved',
          data: versionInfo,
        );
      } else {
        _displayVersionInfo(versionInfo);
        return CommandResult.success(
          command: 'version',
          message: 'Version information displayed',
          data: versionInfo,
        );
      }
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to get version information: $e',
        suggestion: 'Check your internet connection for update checks',
      );
    }
  }

  CommandResult _createPlan(bool checkUpdates) {
    return CommandResult.success(
      command: 'version',
      message: 'Version check plan',
      data: {
        'check_updates': checkUpdates,
        'estimated_duration_ms': checkUpdates ? 3000 : 100,
      },
    );
  }

  void _displayVersionInfo(Map<String, dynamic> versionInfo) {
    logger.info('Fly CLI ${versionInfo['version']}');
    
    if (versionInfo['build_number'] != null) {
      logger.info('Build: ${versionInfo['build_number']}');
    }
    
    if (versionInfo['git_commit'] != null) {
      logger.info('Commit: ${versionInfo['git_commit']}');
    }
    
    if (versionInfo['build_date'] != null) {
      logger.info('Built: ${versionInfo['build_date']}');
    }

    if (versionInfo['update_available'] == true) {
      logger.info('\n🔄 Update available: ${versionInfo['latest_version']}');
      logger.info('Run "dart pub global activate fly_cli" to update');
    } else if (versionInfo['update_available'] == false) {
      logger.info('\n✅ You are using the latest version');
    }
  }

  String _getCurrentVersion() {
    // In a real implementation, this would read from pubspec.yaml
    // For now, return a hardcoded version
    return '0.1.0';
  }

  String? _getBuildNumber() {
    // In a real implementation, this would be set during build
    return null;
  }

  String? _getGitCommit() {
    try {
      final result = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (e) {
      // Git not available or not in a git repository
    }
    return null;
  }

  String? _getBuildDate() {
    // In a real implementation, this would be set during build
    return DateTime.now().toIso8601String();
  }

  Future<Map<String, dynamic>> _checkForUpdates(String currentVersion) async {
    try {
      // In a real implementation, this would check pub.dev for updates
      // For now, simulate the check
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate no updates available for now
      return {
        'update_available': false,
        'latest_version': currentVersion,
        'update_check_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'update_available': null,
        'update_error': e.toString(),
        'update_check_date': DateTime.now().toIso8601String(),
      };
    }
  }
}
