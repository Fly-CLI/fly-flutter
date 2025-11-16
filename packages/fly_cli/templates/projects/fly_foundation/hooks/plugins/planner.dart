import 'package:mason/mason.dart';

import 'foundation_model.dart';

abstract class PlannerPlugin {
  bool canHandle(BaseTemplateVariables base);
  DerivedTemplateVariables derive(
    BaseTemplateVariables base,
    DerivedTemplateVariables acc,
    Logger logger,
  );
}

class CompositePlanner {
  CompositePlanner(this.plugins);
  final List<PlannerPlugin> plugins;

  DerivedTemplateVariables run(
    BaseTemplateVariables base,
    Logger logger,
  ) {
    var derived = DerivedTemplateVariables.empty();
    for (final p in plugins) {
      if (p.canHandle(base)) {
        final newDerived = p.derive(base, derived, logger);
        derived = derived.merge(newDerived);
      }
    }
    return derived;
  }
}
