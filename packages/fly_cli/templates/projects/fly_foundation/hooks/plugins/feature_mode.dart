import 'package:mason/mason.dart';

import 'planner.dart';
import 'presets.dart';

class FeatureModePlanner implements PlannerPlugin {
  @override
  bool canHandle(Vars vars) {
    try {
      return GenerationMode.fromVars(vars) == GenerationMode.feature;
    } catch (_) {
      return false;
    }
  }

  @override
  Vars derive(Vars vars, Logger logger) {
    // These vars are now derived by PresetPlanner/CoreVarsPlanner
    final screenType = (vars['screen_type'] as String?)?.toLowerCase() ?? 'list';
    final withValidation = vars['with_validation'] == true;
    final withNavigation = vars['with_navigation'] == true;
    final sm = (vars['state_mgmt'] as String?)?.toLowerCase() ?? 'riverpod';
    
    // Note: is_project/is_feature/is_service are already set by CoreVarsPlanner
    return <String, dynamic>{
      'active_mode': 'feature',
      'is_project': vars['is_project'] ?? false,
      'is_feature': vars['is_feature'] ?? true,
      'is_service': vars['is_service'] ?? false,
      'is_list_screen': screenType == 'list',
      'is_detail_screen': screenType == 'detail',
      'is_form_screen': screenType == 'form' || screenType == 'auth',
      'requires_validation': withValidation || screenType == 'form' || screenType == 'auth',
      'with_navigation': withNavigation,
      'use_riverpod': sm == 'riverpod',
      'use_bloc': sm == 'bloc',
      'use_cubit': sm == 'cubit',
    };
  }
}


