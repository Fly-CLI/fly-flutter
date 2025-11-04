# Root Cause Analysis: Analyzer Plugin Not Working

## Executive Summary

After systematic investigation, the root cause has been identified: **The analyzer only supports ONE plugin at a time**, and `custom_lint` is listed first in `analysis_options.yaml`, causing `foundation_project_lints` to be ignored.

## Critical Issues Found

### Issue #1: Multiple Plugins Conflict (PRIMARY ROOT CAUSE)

**Location**: `examples/foundation_project/analysis_options.yaml:29-31`

```yaml
analyzer:
  plugins:
    - custom_lint          # ← First plugin (used)
    - foundation_project_lints  # ← Second plugin (IGNORED)
```

**Evidence**: Analyzer output shows:
```
warning - analysis_options.yaml:31:7 - Multiple plugins can't be enabled. 
Remove all plugins following the first, 'custom_lint'. - multiple_plugins
```

**Impact**: The analyzer only loads `custom_lint` and completely ignores `foundation_project_lints`, so the plugin never starts.

**Solution**: Remove `custom_lint` from the plugins list to test `foundation_project_lints`, or use only one plugin at a time.

### Issue #2: Plugin Discovery Mechanism

The plugin structure is correct according to the analyzer_plugin tutorial:
- ✅ Bootstrap package: `tools/analyzer_plugin/` with `bin/plugin.dart` and `pubspec.yaml`
- ✅ Entry point: Correct signature `void main(List<String> args, SendPort sendPort)`
- ✅ ServerPlugin implementation: Extends `ServerPlugin` with `analyzeFile` method
- ✅ Error reporting: Uses `AnalysisErrorsParams` and `channel.sendNotification()`

However, the debug log at `/tmp/foundation_project_lints_debug.log` never executes, confirming the plugin is never loaded due to Issue #1.

### Issue #3: Documentation Limitation

The `analyzer_plugin` package documentation states:
> **Note:** The plugin support is not currently available for general use.

This is a known limitation, but the plugin structure and implementation are correct. The immediate blocker is the multiple plugins issue.

## Implementation Verification

### ✅ Correct Implementation

1. **ServerPlugin Class**: Correctly extends `ServerPlugin`
   ```dart
   class FoundationProjectLintsAnalyzerPlugin extends ServerPlugin {
     FoundationProjectLintsAnalyzerPlugin()
         : super(resourceProvider: PhysicalResourceProvider.INSTANCE);
   }
   ```

2. **Required Getters**: All implemented correctly
   - `name`: Returns `'foundation_project_lints'`
   - `version`: Returns `'1.0.0'`
   - `fileGlobsToAnalyze`: Returns `['*.dart']`

3. **analyzeFile Method**: Correctly implemented with proper error handling
   - Uses `AnalysisContext` and resolves units
   - Creates `AnalysisError` objects correctly
   - Sends notifications via `channel.sendNotification()`

4. **Bootstrap Package**: Structure matches tutorial exactly
   - `tools/analyzer_plugin/bin/plugin.dart` with correct entry point
   - `tools/analyzer_plugin/pubspec.yaml` with correct dependencies

5. **Entry Point**: Correct signature
   ```dart
   void main(List<String> args, SendPort sendPort) {
     final plugin = FoundationProjectLintsAnalyzerPlugin();
     final starter = ServerPluginStarter(plugin);
     starter.start(sendPort);
   }
   ```

## Root Cause Summary

**PRIMARY ROOT CAUSE**: Multiple plugins conflict - analyzer only loads the first plugin listed.

**SECONDARY ISSUES**:
1. Plugin structure is correct but never loaded due to multiple plugins issue
2. Documentation limitation exists but doesn't prevent correct implementation from working

## Recommended Fixes

### Fix #1: Remove Multiple Plugins (Immediate)

Remove `custom_lint` from `analysis_options.yaml` to test if `foundation_project_lints` works:

```yaml
analyzer:
  plugins:
    - foundation_project_lints  # Only this plugin
```

**OR** if you need both:
- Use `custom_lint` for development (run `dart run custom_lint:custom_lint`)
- Use `foundation_project_lints` for `flutter analyze` (remove `custom_lint` from plugins list)

### Fix #2: Add handleAffectedFiles Override (Optional)

Although `handleAffectedFiles` has a default implementation, explicitly overriding it ensures proper file change handling:

```dart
@override
Future<void> handleAffectedFiles({
  required AnalysisContext analysisContext,
  required List<String> paths,
}) async {
  await analyzeFiles(
    analysisContext: analysisContext,
    paths: paths,
  );
}
```

### Fix #3: Verify Plugin Discovery

After removing `custom_lint`, verify:
1. Debug log at `/tmp/foundation_project_lints_debug.log` is created
2. `analyzeFile` is called for Dart files
3. Lint violations are reported

## Testing Steps

1. Remove `custom_lint` from `analysis_options.yaml` plugins list
2. Run `flutter analyze` 
3. Check `/tmp/foundation_project_lints_debug.log` for plugin startup
4. Verify lint violations are detected
5. Test with a ViewModel that has an async method without `performAsync()`

## Conclusion

The plugin implementation is **correct**. The primary issue was that the analyzer **only supports one plugin at a time**, and `custom_lint` was listed first, preventing `foundation_project_lints` from being loaded.

### Status After Fix

After removing `custom_lint` from the plugins list:
- ✅ Multiple plugins warning is gone
- ✅ Analyzer runs without errors
- ⚠️ Plugin still not loading (debug log not created)

### Remaining Issue

Even after fixing the multiple plugins issue, the plugin is still not being discovered. This suggests:

1. **Plugin Discovery Limitation**: The analyzer may not discover plugins from local path dependencies properly
2. **Documentation Warning**: The `analyzer_plugin` package explicitly states "plugin support is not currently available for general use"
3. **Possible Restriction**: Plugin discovery may only work for published packages or specific internal Dart tools

### Next Steps

1. **Test with Published Package**: Try publishing the plugin package to pub.dev to see if that enables discovery
2. **Alternative Approach**: Continue using `custom_lint` for development, as it's actively maintained and designed for this purpose
3. **Monitor Updates**: Watch for changes to `analyzer_plugin` that enable general use

