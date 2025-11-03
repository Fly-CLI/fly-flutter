/// POSIX-compliant exit codes for CLI applications
///
/// This enum provides standard exit codes following POSIX conventions
/// for better integration with shell scripts and CI/CD pipelines.
///
/// Reference: https://www.gnu.org/software/libc/manual/html_node/Exit-Status.html
enum CliExitCode {
  /// Success (0)
  success(0),

  /// General error (1) - catch-all for errors
  generalError(1),

  /// Misuse of shell command (2)
  misuse(2),

  /// Command line usage error (64) - EX_USAGE
  usageError(64),

  /// Data format error (65) - EX_DATAERR
  dataError(65),

  /// Cannot open input (66) - EX_NOINPUT
  noInput(66),

  /// User not found (67) - EX_NOUSER
  noUser(67),

  /// Host not found (68) - EX_NOHOST
  noHost(68),

  /// Service unavailable (69) - EX_UNAVAILABLE
  unavailable(69),

  /// Internal software error (70) - EX_SOFTWARE
  softwareError(70),

  /// System error (71) - EX_OSERR
  osError(71),

  /// OS file error (72) - EX_OSFILE
  osFile(72),

  /// Cannot create output file (73) - EX_CANTCREAT
  cantCreate(73),

  /// Input/output error (74) - EX_IOERR
  ioError(74),

  /// Temporary failure (75) - EX_TEMPFAIL
  tempFailure(75),

  /// Remote error in protocol (76) - EX_PROTOCOL
  protocol(76),

  /// Permission denied (77) - EX_NOPERM
  noPermission(77),

  /// Configuration error (78) - EX_CONFIG
  config(78),

  /// SIGINT (130) - Command interrupted by Ctrl+C
  sigint(130);

  const CliExitCode(this.code);

  /// The numeric exit code value
  final int code;

  /// Parse an exit code from an integer value
  ///
  /// Returns the corresponding [CliExitCode] enum value, or [CliExitCode.generalError]
  /// if the value doesn't match any standard code.
  ///
  /// [value] - The integer exit code value
  static CliExitCode fromInt(int value) {
    for (final exitCode in CliExitCode.values) {
      if (exitCode.code == value) {
        return exitCode;
      }
    }
    // Default to general error for unknown codes
    return CliExitCode.generalError;
  }

  /// Get exit code for success
  static CliExitCode get successCode => CliExitCode.success;

  /// Get exit code for general error
  static CliExitCode get errorCode => CliExitCode.generalError;
}
