import 'package:mason/mason.dart';

import 'planner.dart';
import 'presets.dart';

class ProjectModePlanner implements PlannerPlugin {
  @override
  bool canHandle(Vars vars) {
    try {
      return GenerationMode.fromVars(vars) == GenerationMode.project;
    } catch (_) {
      return false;
    }
  }

  @override
  Vars derive(Vars vars, Logger logger) {
    final platforms = (vars['platforms'] as List?)?.map((e) => '$e'.toLowerCase()).toSet() ?? <String>{};
    return <String, dynamic>{
      'active_mode': 'project',
      'is_project': true,
      'is_feature': false,
      'is_service': false,
      'supports_ios': platforms.contains('ios'),
      'supports_android': platforms.contains('android'),
      'supports_web': platforms.contains('web'),
      'supports_macos': platforms.contains('macos'),
      'supports_windows': platforms.contains('windows'),
      'supports_linux': platforms.contains('linux'),
      'supports_desktop': platforms.intersection({'macos', 'windows', 'linux'}).isNotEmpty,
    };
  }
}


