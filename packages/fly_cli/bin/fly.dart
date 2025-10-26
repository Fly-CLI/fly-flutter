#!/usr/bin/env dart

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fly_cli/src/command_runner.dart';

/// Fly CLI - AI-Native Flutter Development Tool
/// 
/// The first Flutter CLI tool designed from the ground up for AI integration.
/// Provides intelligent automation, multi-architecture support, and seamless
/// integration with modern AI coding assistants.
Future<void> main(List<String> arguments) async {
  final commandRunner = FlyCommandRunner();
  
  try {
    await commandRunner.run(arguments);
  } on UsageException catch (error) {
    // Handle usage errors gracefully
    stderr.writeln(error);
    exit(64); // EX_USAGE
  } catch (error, stackTrace) {
    // Handle unexpected errors
    stderr.writeln('Unexpected error: $error');
    if (arguments.contains('--verbose')) {
      stderr.writeln(stackTrace);
    }
    exit(1);
  }
}
