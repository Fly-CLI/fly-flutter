// Enum-based definitions for all environment variables used across the monorepo.

enum EnvType { string, boolean, integer }

/// Centralized list of supported environment variables.
/// Keys are the canonical names as expected in -D defines and process env.
enum EnvVar {
  // Fly CLI output formatting
  flyJsonOutput('FLY_JSON_OUTPUT', EnvType.boolean),

  // Logging configuration
  flyLogLevel('FLY_LOG_LEVEL', EnvType.string),
  flyLogFormat('FLY_LOG_FORMAT', EnvType.string),
  flyNoColor('FLY_NO_COLOR', EnvType.boolean),
  flyLogHttpEndpoint('FLY_LOG_HTTP_ENDPOINT', EnvType.string),
  flyLogHttpToken('FLY_LOG_HTTP_TOKEN', EnvType.string),
  flyLogFile('FLY_LOG_FILE', EnvType.string),
  flyLogTrace('FLY_LOG_TRACE', EnvType.boolean),

  // Sentry
  sentryDsn('SENTRY_DSN', EnvType.string),
  sentryEnvironment('SENTRY_ENVIRONMENT', EnvType.string),
  sentryRelease('SENTRY_RELEASE', EnvType.string),

  // Datadog
  ddApiKey('DD_API_KEY', EnvType.string),
  ddSite('DD_SITE', EnvType.string),

  // Paths
  flyOutputDir('FLY_OUTPUT_DIR', EnvType.string),
  pwd('PWD', EnvType.string),

  // User directories
  home('HOME', EnvType.string),
  userProfile('USERPROFILE', EnvType.string),

  // Android SDK
  androidHome('ANDROID_HOME', EnvType.string),
  androidSdkRoot('ANDROID_SDK_ROOT', EnvType.string),

  // Shell variables
  comspec('COMSPEC', EnvType.string),
  comSpec('ComSpec', EnvType.string),
  shell('SHELL', EnvType.string),

  // Build metadata
  buildNumber('BUILD_NUMBER', EnvType.string),
  buildDate('BUILD_DATE', EnvType.string),

  // Synthetic flag: product mode (compile-time only)
  productMode('dart.vm.product', EnvType.boolean, isSynthetic: true);

  const EnvVar(this.key, this.type, {this.isSynthetic = false});
  final String key;
  final EnvType type;
  final bool isSynthetic;
}


