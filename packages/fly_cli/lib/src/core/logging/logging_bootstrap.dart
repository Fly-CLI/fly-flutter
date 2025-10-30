import 'package:args/args.dart';

import 'logger.dart' as flylog;
import 'logging_context.dart' as flylog_ctx;
import 'logger_factory.dart' as flylog_factory;
import 'logging_config.dart' as flylog_cfg;
import '../utils/version_utils.dart';

class LoggingBootstrap {
  static flylog.Logger createRootLogger({
    required bool isDevelopment,
    ArgResults? parsedArgs,
    String loggerName = 'fly',
  }) {
    final envCfg = flylog_cfg.LoggingConfig.fromEnvironment(isProd: !isDevelopment);
    final overrideCfg = envCfg.withOverrides(
      level: parsedArgs != null ? parsedArgs['log-level'] as String? : null,
      format: parsedArgs != null ? parsedArgs['log-format'] as String? : null,
      logFile: parsedArgs != null ? parsedArgs['log-file'] as String? : null,
      noColor: parsedArgs != null && parsedArgs['no-color'] == true ? true : null,
      trace: parsedArgs != null ? parsedArgs['trace'] as bool? : null,
    );

    final baseCtx = flylog_ctx.LoggingContext(
      environment: isDevelopment ? 'development' : 'production',
      version: VersionUtils.getCurrentVersion(),
    );

    return flylog_factory.LoggerFactory(
      overrideCfg,
      baseContext: baseCtx,
      name: loggerName,
    ).createRoot();
  }
}


