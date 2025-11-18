import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/mason_variable_keys.dart';

/// Shared derived variables used across all generation modes.
///
/// This class contains variables that are common to project, feature, and service modes,
/// such as naming variants, template metadata, platform flags, and fly packages.
class SharedDerivedVariables {
  const SharedDerivedVariables({
    this.projectName,
    this.projectNameSnake,
    this.projectNameCamel,
    this.projectNamePascal,
    this.templateVariant,
    this.minFlutterSdk,
    this.minDartSdk,
    this.supportsIos = false,
    this.supportsAndroid = false,
    this.supportsWeb = false,
    this.supportsMacos = false,
    this.supportsWindows = false,
    this.supportsLinux = false,
    this.supportsDesktop = false,
    this.flyPackages,
    this.activeMode,
  });

  /// Project name (may be derived from component name in feature/service mode).
  final String? projectName;

  /// Project name in snake_case format.
  final String? projectNameSnake;

  /// Project name in camelCase format.
  final String? projectNameCamel;

  /// Project name in PascalCase format.
  final String? projectNamePascal;

  /// Template variant identifier.
  final String? templateVariant;

  /// Minimum Flutter SDK version.
  final String? minFlutterSdk;

  /// Minimum Dart SDK version.
  final String? minDartSdk;

  /// Whether iOS platform is supported.
  final bool supportsIos;

  /// Whether Android platform is supported.
  final bool supportsAndroid;

  /// Whether Web platform is supported.
  final bool supportsWeb;

  /// Whether macOS platform is supported.
  final bool supportsMacos;

  /// Whether Windows platform is supported.
  final bool supportsWindows;

  /// Whether Linux platform is supported.
  final bool supportsLinux;

  /// Whether desktop platforms (macOS, Windows, Linux) are supported.
  final bool supportsDesktop;

  /// List of Fly packages to include.
  final List<String>? flyPackages;

  /// Active generation mode.
  final GenerationMode? activeMode;

  /// Creates an empty instance.
  static SharedDerivedVariables empty() {
    return const SharedDerivedVariables();
  }

  /// Merges this instance with another, with [other] taking precedence.
  SharedDerivedVariables merge(SharedDerivedVariables other) {
    return SharedDerivedVariables(
      projectName: other.projectName ?? projectName,
      projectNameSnake: other.projectNameSnake ?? projectNameSnake,
      projectNameCamel: other.projectNameCamel ?? projectNameCamel,
      projectNamePascal: other.projectNamePascal ?? projectNamePascal,
      templateVariant: other.templateVariant ?? templateVariant,
      minFlutterSdk: other.minFlutterSdk ?? minFlutterSdk,
      minDartSdk: other.minDartSdk ?? minDartSdk,
      supportsIos: other.supportsIos,
      supportsAndroid: other.supportsAndroid,
      supportsWeb: other.supportsWeb,
      supportsMacos: other.supportsMacos,
      supportsWindows: other.supportsWindows,
      supportsLinux: other.supportsLinux,
      supportsDesktop: other.supportsDesktop,
      flyPackages: other.flyPackages ?? flyPackages,
      activeMode: other.activeMode ?? activeMode,
    );
  }

  /// Converts to a Mason variables map.
  Map<String, dynamic> toMasonVars() {
    final result = <String, dynamic>{};

    if (projectName != null) {
      result[MasonVarKey.projectName.key] = projectName;
    }
    if (projectNameSnake != null) {
      result[MasonVarKey.projectNameSnake.key] = projectNameSnake;
    }
    if (projectNameCamel != null) {
      result[MasonVarKey.projectNameCamel.key] = projectNameCamel;
    }
    if (projectNamePascal != null) {
      result[MasonVarKey.projectNamePascal.key] = projectNamePascal;
    }
    if (templateVariant != null) {
      result[MasonVarKey.templateVariant.key] = templateVariant;
    }
    if (minFlutterSdk != null) {
      result[MasonVarKey.minFlutterSdk.key] = minFlutterSdk;
    }
    if (minDartSdk != null) {
      result[MasonVarKey.minDartSdk.key] = minDartSdk;
    }

    result[MasonVarKey.supportsIos.key] = supportsIos;
    result[MasonVarKey.supportsAndroid.key] = supportsAndroid;
    result[MasonVarKey.supportsWeb.key] = supportsWeb;
    result[MasonVarKey.supportsMacos.key] = supportsMacos;
    result[MasonVarKey.supportsWindows.key] = supportsWindows;
    result[MasonVarKey.supportsLinux.key] = supportsLinux;
    result[MasonVarKey.supportsDesktop.key] = supportsDesktop;

    if (flyPackages != null) {
      result[MasonVarKey.flyPackages.key] = flyPackages;
    }
    if (activeMode != null) {
      result[MasonVarKey.activeMode.key] = activeMode!.key;
    }

    return result;
  }

  /// Creates a copy with updated fields.
  SharedDerivedVariables copyWith({
    String? projectName,
    String? projectNameSnake,
    String? projectNameCamel,
    String? projectNamePascal,
    String? templateVariant,
    String? minFlutterSdk,
    String? minDartSdk,
    bool? supportsIos,
    bool? supportsAndroid,
    bool? supportsWeb,
    bool? supportsMacos,
    bool? supportsWindows,
    bool? supportsLinux,
    bool? supportsDesktop,
    List<String>? flyPackages,
    GenerationMode? activeMode,
  }) {
    return SharedDerivedVariables(
      projectName: projectName ?? this.projectName,
      projectNameSnake: projectNameSnake ?? this.projectNameSnake,
      projectNameCamel: projectNameCamel ?? this.projectNameCamel,
      projectNamePascal: projectNamePascal ?? this.projectNamePascal,
      templateVariant: templateVariant ?? this.templateVariant,
      minFlutterSdk: minFlutterSdk ?? this.minFlutterSdk,
      minDartSdk: minDartSdk ?? this.minDartSdk,
      supportsIos: supportsIos ?? this.supportsIos,
      supportsAndroid: supportsAndroid ?? this.supportsAndroid,
      supportsWeb: supportsWeb ?? this.supportsWeb,
      supportsMacos: supportsMacos ?? this.supportsMacos,
      supportsWindows: supportsWindows ?? this.supportsWindows,
      supportsLinux: supportsLinux ?? this.supportsLinux,
      supportsDesktop: supportsDesktop ?? this.supportsDesktop,
      flyPackages: flyPackages ?? this.flyPackages,
      activeMode: activeMode ?? this.activeMode,
    );
  }
}

