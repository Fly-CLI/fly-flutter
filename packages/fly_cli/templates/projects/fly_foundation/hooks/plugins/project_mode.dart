import 'package:mason/mason.dart';

import 'foundation_model.dart';
import 'planner.dart';

class ProjectModePlanner implements PlannerPlugin {
  @override
  bool canHandle(BaseTemplateVariables base) {
    return base.generationMode == GenerationMode.project;
  }

  @override
  DerivedTemplateVariables derive(
    BaseTemplateVariables base,
    DerivedTemplateVariables acc,
    Logger logger,
  ) {
    final platformKeys = base.platforms.map((p) => p.key).toSet();
    final desktopPlatforms = {
      PlatformType.macos.key,
      PlatformType.windows.key,
      PlatformType.linux.key,
    };

    return DerivedTemplateVariables(
      isProject: true,
      isFeature: false,
      isService: false,
      activeMode: GenerationMode.project,
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
