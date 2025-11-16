import 'package:mason/mason.dart';

typedef Vars = Map<String, dynamic>;

abstract class PlannerPlugin {
  bool canHandle(Vars vars);
  Vars derive(Vars vars, Logger logger);
}

class CompositePlanner {
  CompositePlanner(this.plugins);
  final List<PlannerPlugin> plugins;

  Vars run(Vars vars, Logger logger) {
    final derived = <String, dynamic>{};
    for (final p in plugins) {
      if (p.canHandle(vars)) {
        final out = p.derive({...vars, ...derived}, logger);
        derived.addAll(out);
      }
    }
    return derived;
  }
}


