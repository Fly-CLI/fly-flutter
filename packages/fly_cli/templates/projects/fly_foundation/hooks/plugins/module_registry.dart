import 'foundation_model.dart';
import 'composition.dart';

/// Disposition strategy for how a module's files should be handled during post-gen.
enum ModuleDisposition {
  /// Move module files to the output root (used for project mode).
  moveToRoot,

  /// Merge module files into existing structure (used for feature/service modes).
  mergeIntoExisting,

  /// Remove module if inactive.
  removeIfInactive,
}

/// Configuration for a template module including its disposition strategy.
class ModuleConfig {
  const ModuleConfig({
    required this.module,
    required this.disposition,
  });

  /// The template module.
  final TemplateModule module;

  /// How files from this module should be handled during post-gen.
  final ModuleDisposition disposition;
}

/// Registry that manages all template modules and their composition rules.
///
/// This registry provides a data-driven approach to module selection and
/// configuration, replacing hard-coded switch statements.
class ModuleRegistry {
  /// Creates a registry with all default modules.
  ModuleRegistry()
      : _modules = [
          ModuleConfig(
            module: ProjectModule(),
            disposition: ModuleDisposition.moveToRoot,
          ),
          ModuleConfig(
            module: FeatureModule(),
            disposition: ModuleDisposition.mergeIntoExisting,
          ),
          ModuleConfig(
            module: ServiceModule(),
            disposition: ModuleDisposition.mergeIntoExisting,
          ),
          ModuleConfig(
            module: ProviderModule(),
            disposition: ModuleDisposition.mergeIntoExisting,
          ),
        ];

  /// Creates a registry with custom modules.
  ModuleRegistry.custom(List<ModuleConfig> modules) : _modules = modules;

  final List<ModuleConfig> _modules;

  /// Resolves active modules for the given generation mode and variables.
  ///
  /// Returns a list of module configurations for modules that can compose
  /// with the given mode and variables.
  List<ModuleConfig> resolveModules(
    GenerationMode mode,
    Map<String, dynamic> vars,
  ) {
    return _modules
        .where((config) => config.module.canComposeWith(mode, vars))
        .toList();
  }

  /// Gets the disposition for a module by name.
  ///
  /// Returns null if the module is not registered.
  ModuleDisposition? getDisposition(String moduleName) {
    try {
      return _modules
          .firstWhere((config) => config.module.name == moduleName)
          .disposition;
    } catch (_) {
      return null;
    }
  }

  /// Gets all registered module names.
  List<String> get registeredModuleNames =>
      _modules.map((config) => config.module.name).toList();
}

