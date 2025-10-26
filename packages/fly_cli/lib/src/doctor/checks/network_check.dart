import 'dart:io';
import 'package:mason_logger/mason_logger.dart';

import '../system_checker.dart';

/// Check network connectivity and accessibility of required services
class NetworkCheck extends SystemCheck {
  NetworkCheck({this.logger});
  
  final Logger? logger;

  @override
  String get name => 'Network Connectivity';

  @override
  String get category => 'Network';

  @override
  String get description => 'Check internet connectivity and accessibility of required services';

  @override
  Future<CheckResult> run() async {
    final issues = <String>[];
    final suggestions = <String>[];
    final data = <String, dynamic>{};

    // Check basic internet connectivity
    final connectivityResult = await _checkBasicConnectivity();
    if (!connectivityResult.healthy) {
      issues.add('Basic connectivity: ${connectivityResult.message}');
      if (connectivityResult.suggestion != null) {
        suggestions.add(connectivityResult.suggestion!);
      }
      data['connectivity'] = connectivityResult.data;
    } else {
      data['connectivity'] = connectivityResult.data;
    }

    // Check pub.dev accessibility
    final pubDevResult = await _checkPubDev();
    if (!pubDevResult.healthy) {
      issues.add('pub.dev: ${pubDevResult.message}');
      if (pubDevResult.suggestion != null) {
        suggestions.add(pubDevResult.suggestion!);
      }
      data['pubDev'] = pubDevResult.data;
    } else {
      data['pubDev'] = pubDevResult.data;
    }

    // Check GitHub accessibility (for templates)
    final githubResult = await _checkGitHub();
    if (!githubResult.healthy) {
      issues.add('GitHub: ${githubResult.message}');
      if (githubResult.suggestion != null) {
        suggestions.add(githubResult.suggestion!);
      }
      data['github'] = githubResult.data;
    } else {
      data['github'] = githubResult.data;
    }

    if (issues.isEmpty) {
      return CheckResult.success(
        message: 'Network connectivity and required services are accessible',
        data: data,
      );
    } else if (issues.length == 1) {
      return CheckResult.warning(
        message: 'Network issue: ${issues.first}',
        suggestion: suggestions.isNotEmpty ? suggestions.first : null,
        data: data,
      );
    } else {
      return CheckResult.warning(
        message: 'Multiple network issues found',
        suggestion: suggestions.join('; '),
        data: data,
      );
    }
  }

  /// Check basic internet connectivity
  Future<CheckResult> _checkBasicConnectivity() async {
    try {
      // Try to connect to a reliable service
      final socket = await Socket.connect('google.com', 80, timeout: const Duration(seconds: 10));
      await socket.close();
      
      return CheckResult.success(
        message: 'Basic internet connectivity is working',
        data: {'testHost': 'google.com', 'port': 80},
      );
    } catch (e) {
      return CheckResult.error(
        message: 'No internet connectivity detected',
        suggestion: 'Check your internet connection and network settings',
        data: {'error': e.toString()},
      );
    }
  }

  /// Check pub.dev accessibility
  Future<CheckResult> _checkPubDev() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client.getUrl(Uri.parse('https://pub.dev/api/packages/flutter'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        return CheckResult.success(
          message: 'pub.dev is accessible',
          data: {
            'url': 'https://pub.dev/api/packages/flutter',
            'statusCode': response.statusCode,
          },
        );
      } else {
        return CheckResult.warning(
          message: 'pub.dev returned status code ${response.statusCode}',
          suggestion: 'Check if pub.dev is experiencing issues',
          data: {
            'url': 'https://pub.dev/api/packages/flutter',
            'statusCode': response.statusCode,
          },
        );
      }
    } catch (e) {
      return CheckResult.error(
        message: 'Cannot access pub.dev: $e',
        suggestion: 'Check your internet connection and firewall settings',
        data: {'error': e.toString()},
      );
    }
  }

  /// Check GitHub accessibility
  Future<CheckResult> _checkGitHub() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client.getUrl(Uri.parse('https://api.github.com'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        return CheckResult.success(
          message: 'GitHub is accessible',
          data: {
            'url': 'https://api.github.com',
            'statusCode': response.statusCode,
          },
        );
      } else {
        return CheckResult.warning(
          message: 'GitHub returned status code ${response.statusCode}',
          suggestion: 'Check if GitHub is experiencing issues',
          data: {
            'url': 'https://api.github.com',
            'statusCode': response.statusCode,
          },
        );
      }
    } catch (e) {
      return CheckResult.error(
        message: 'Cannot access GitHub: $e',
        suggestion: 'Check your internet connection and firewall settings',
        data: {'error': e.toString()},
      );
    }
  }
}
