#!/usr/bin/env dart

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fly_cli/src/command_runner.dart';
import 'package:fly_cli/src/core/cli/cli_exit_code.dart';

/// Fly CLI - AI-Native Flutter Development Tool
///
/// The first Flutter CLI tool designed from the ground up for AI integration.
/// Provides intelligent automation, multi-architecture support, and seamless
/// integration with modern AI coding assistants.
Future<void> main(List<String> arguments) async {
  final commandRunner = FlyCommandRunner.create(arguments);

  try {
    final exitCode = await commandRunner.run(arguments);
    exit(exitCode);
  } on UsageException catch (error) {
    // Handle usage errors gracefully
    stderr.writeln(error);
    exit(CliExitCode.usageError.code); // EX_USAGE
  } catch (error, stackTrace) {
    // Handle unexpected errors
    // Note: This should rarely happen as ErrorHandler in FlyCommandRunner
    // handles most errors. This is a fallback for truly unexpected errors.
    stderr.writeln('Unexpected error: $error');
    if (arguments.contains('--verbose')) {
      stderr.writeln(stackTrace);
    }
    exit(CliExitCode.generalError.code);
  }
}
