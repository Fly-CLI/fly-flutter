import 'mode_specific_variables.dart';
import '../foundation_model.dart';
import '../mason_variable_keys.dart';

/// Project-specific derived variables.
final class ProjectVariables extends ModeSpecificVariables {
  const ProjectVariables({
    this.isProject = true,
    this.supportsIos = false,
    this.supportsAndroid = false,
    this.supportsWeb = false,
    this.supportsMacos = false,
    this.supportsWindows = false,
    this.supportsLinux = false,
    this.supportsDesktop = false,
  });

  final bool isProject;
  final bool supportsIos;
  final bool supportsAndroid;
  final bool supportsWeb;
  final bool supportsMacos;
  final bool supportsWindows;
  final bool supportsLinux;
  final bool supportsDesktop;

  @override
  GenerationMode get mode => GenerationMode.project;

  @override
  Map<String, dynamic> toMasonVars() {
    return {
      MasonVarKey.isProject.key: isProject,
      MasonVarKey.supportsIos.key: supportsIos,
      MasonVarKey.supportsAndroid.key: supportsAndroid,
      MasonVarKey.supportsWeb.key: supportsWeb,
      MasonVarKey.supportsMacos.key: supportsMacos,
      MasonVarKey.supportsWindows.key: supportsWindows,
      MasonVarKey.supportsLinux.key: supportsLinux,
      MasonVarKey.supportsDesktop.key: supportsDesktop,
    };
  }

  /// Creates a copy with updated fields.
  ProjectVariables copyWith({
    bool? isProject,
    bool? supportsIos,
    bool? supportsAndroid,
    bool? supportsWeb,
    bool? supportsMacos,
    bool? supportsWindows,
    bool? supportsLinux,
    bool? supportsDesktop,
  }) {
    return ProjectVariables(
      isProject: isProject ?? this.isProject,
      supportsIos: supportsIos ?? this.supportsIos,
      supportsAndroid: supportsAndroid ?? this.supportsAndroid,
      supportsWeb: supportsWeb ?? this.supportsWeb,
      supportsMacos: supportsMacos ?? this.supportsMacos,
      supportsWindows: supportsWindows ?? this.supportsWindows,
      supportsLinux: supportsLinux ?? this.supportsLinux,
      supportsDesktop: supportsDesktop ?? this.supportsDesktop,
    );
  }
}

