/// Base mapper for bidirectional conversion between source and target types
/// 
/// Provides a simple interface for converting between two types with
/// support for optional mapping options.
abstract class BaseMapper<TSource, TTarget> {
  /// Convert source to target
  /// 
  /// [source] - Source object to convert
  /// [options] - Optional mapping options (e.g., syncStatus, isSelected)
  /// Returns converted target object
  TTarget toTarget(TSource source, {Map<String, dynamic>? options});
  
  /// Convert target to source
  /// 
  /// [target] - Target object to convert back
  /// [options] - Optional mapping options
  /// Returns converted source object
  TSource toSource(TTarget target, {Map<String, dynamic>? options});
  
  /// Convert list of sources to targets
  /// 
  /// [sources] - List of source objects to convert
  /// [options] - Optional mapping options applied to all conversions
  /// Returns list of converted target objects
  List<TTarget> toTargetList(
    List<TSource> sources, {
    Map<String, dynamic>? options,
  }) {
    return sources.map((s) => toTarget(s, options: options)).toList();
  }
  
  /// Convert list of targets to sources
  /// 
  /// [targets] - List of target objects to convert back
  /// [options] - Optional mapping options applied to all conversions
  /// Returns list of converted source objects
  List<TSource> toSourceList(
    List<TTarget> targets, {
    Map<String, dynamic>? options,
  }) {
    return targets.map((t) => toSource(t, options: options)).toList();
  }
}

/// Extension methods for nullable mapper operations
extension MapperExtensions<TSource, TTarget> on BaseMapper<TSource, TTarget> {
  /// Convert nullable source to nullable target
  ///
  /// Returns null if source is null or conversion fails
  TTarget? toTargetNullable(TSource? source, {Map<String, dynamic>? options}) {
    if (source == null) return null;
    try {
      return toTarget(source, options: options);
    } catch (e) {
      return null;
    }
  }

  /// Convert nullable target to nullable source
  ///
  /// Returns null if target is null or conversion fails
  TSource? toSourceNullable(TTarget? target, {Map<String, dynamic>? options}) {
    if (target == null) return null;
    try {
      return toSource(target, options: options);
    } catch (e) {
      return null;
    }
  }
}

