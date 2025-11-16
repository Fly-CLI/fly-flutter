import 'package:mason/mason.dart';

import 'planner.dart';

class FeatureModePlanner implements PlannerPlugin {
  @override
  bool canHandle(Vars vars) {
    final isFeature = vars['is_feature'] == true || vars['generation_mode'] == 'feature';
    return isFeature;
  }

  @override
  Vars derive(Vars vars, Logger logger) {
    final screenType = (vars['screen_type'] as String?)?.toLowerCase();
    final withValidation = vars['with_validation'] == true;
    final withNavigation = vars['with_navigation'] == true;
    final sm = (vars['state_mgmt'] as String?)?.toLowerCase() ?? 'riverpod';
    return <String, dynamic>{
      'active_mode': 'feature',
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


