import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed parameters for flutter.run tool
class FlutterRunParams extends ToolParameter {

   FlutterRunParams({
    this.deviceId,
    this.debug,
    this.release,
    this.profile,
    this.target,
    this.dartDefine,
  });

  /// Create from JSON Map
  factory FlutterRunParams.fromJson(Map<String, Object?> json) {
    final dartDefineMap = json['dartDefine'] as Map?;
    return FlutterRunParams(
      deviceId: json['deviceId'] as String?,
      debug: json['debug'] as bool?,
      release: json['release'] as bool?,
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
  /// Device ID to run on
  final String? deviceId;

  /// Run in debug mode
  final bool? debug;

  /// Run in release mode
  final bool? release;

  /// Run in profile mode
  final bool? profile;

  /// Target file
  final String? target;

  /// Dart define variables
  final Map<String, String>? dartDefine;

  @override
  Map<String, Object?> toJson() => {
        if (deviceId != null) 'deviceId': deviceId,
        if (debug != null) 'debug': debug,
        if (release != null) 'release': release,
        if (profile != null) 'profile': profile,
        if (target != null) 'target': target,
        if (dartDefine != null) 'dartDefine': dartDefine,
      };
}

