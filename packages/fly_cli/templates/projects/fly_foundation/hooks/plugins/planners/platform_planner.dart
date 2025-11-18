import 'package:mason/mason.dart';
import '../foundation_model.dart';
import '../variables/shared_derived_variables.dart';
import 'cross_cutting_planner.dart';

/// Planner that computes platform support flags.
///
/// This planner is the single source of truth for all platform flags:
/// - supports_ios, supports_android, supports_web
/// - supports_macos, supports_windows, supports_linux
/// - supports_desktop (computed from desktop platforms)
///
/// These flags are stored in SharedDerivedVariables and are available
/// to all generation modes (project, feature, service).
///
/// Note: ProjectPlanner no longer duplicates platform flags. All platform
/// flags should be derived by this planner only.
class PlatformPlanner implements CrossCuttingPlanner {
  @override
  bool canHandle(BaseTemplateVariables base) {
    // Platform flags are global, so this planner always handles
    return true;
  }

  @override
  SharedDerivedVariables derive(
    BaseTemplateVariables base,
    SharedDerivedVariables acc,
    Logger logger,
  ) {
    final platformKeys = base.platforms.map((p) => p.key).toSet();
    final desktopPlatforms = {
      PlatformType.macos.key,
      PlatformType.windows.key,
      PlatformType.linux.key,
    };

    return acc.copyWith(
      supportsIos: base.platforms.contains(PlatformType.ios),
      supportsAndroid: base.platforms.contains(PlatformType.android),
      supportsWeb: base.platforms.contains(PlatformType.web),
      supportsMacos: base.platforms.contains(PlatformType.macos),
      supportsWindows: base.platforms.contains(PlatformType.windows),
      supportsLinux: base.platforms.contains(PlatformType.linux),
      supportsDesktop: platformKeys.intersection(desktopPlatforms).isNotEmpty,
    );
  }
}

