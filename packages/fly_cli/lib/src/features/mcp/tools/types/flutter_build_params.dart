import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed parameters for flutter.build tool
class FlutterBuildParams extends ToolParameter {

   FlutterBuildParams({
    required this.platform,
    this.release,
    this.debug,
    this.profile,
    this.target,
    this.dartDefine,
  });

  /// Create from JSON Map
  factory FlutterBuildParams.fromJson(Map<String, Object?> json) {
    final dartDefineMap = json['dartDefine'] as Map?;
    return FlutterBuildParams(
      platform: json['platform'] as String? ?? '',
      release: json['release'] as bool?,
      debug: json['debug'] as bool?,
      profile: json['profile'] as bool?,
      target: json['target'] as String?,
      dartDefine: dartDefineMap != null
          ? Map<String, String>.from(
              dartDefineMap.map((key, value) => MapEntry(
                    key.toString(),
                    value.toString(),
                  )))
          : null,
    );
  }
  /// Target platform (required)
  final String platform;

  /// Build in release mode
  final bool? release;

  /// Build in debug mode
  final bool? debug;

  /// Build in profile mode
  final bool? profile;

  /// Target file
  final String? target;

  /// Dart define variables
  final Map<String, String>? dartDefine;

  @override
  Map<String, Object?> toJson() => {
        'platform': platform,
        if (release != null) 'release': release,
        if (debug != null) 'debug': debug,
        if (profile != null) 'profile': profile,
        if (target != null) 'target': target,
        if (dartDefine != null) 'dartDefine': dartDefine,
      };
}

