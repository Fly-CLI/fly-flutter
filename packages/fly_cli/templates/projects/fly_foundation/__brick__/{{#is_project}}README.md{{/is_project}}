# {{project_name.pascalCase()}}

{{description}}

## Quick Start (⏱️ ~5 minutes)

1. **Install prerequisites**
   ```bash
   dart pub global activate fly_cli
   flutter upgrade
   ```
2. **Install dependencies**
   ```bash
   cd {{project_name.snakeCase()}}
   flutter pub get
   ```
{{#code_generation}}
3. **Run code generation**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
{{/code_generation}}
{{^code_generation}}
3. **Code generation is disabled** in this preset.
{{/code_generation}}
4. **Run the app**
   ```bash
{{#supports_ios}}
   # iOS
   flutter run -d ios
{{/supports_ios}}
{{#supports_android}}
   # Android
   flutter run -d android
{{/supports_android}}
{{#supports_web}}
   # Web
   flutter run -d chrome
{{/supports_web}}
{{#supports_desktop}}
   # Desktop
   flutter run -d macos  # or windows, linux
{{/supports_desktop}}
   ```
{{#ai_integration}}
5. **Add context for AI workflows (optional)**
   ```bash
   fly context export
   ```
   See `.ai/project_context.md` for project context.
{{/ai_integration}}
{{#with_mcp}}
6. **Connect Fly MCP (optional)**
   ```bash
   fly mcp serve
   ```
   See `.mcp/fly_mcp.yaml` for configuration.
{{/with_mcp}}

## Generated Architecture

- **Core foundation**: `BaseScreen`/`BaseViewModel` built on `fly_mvvm`
- **Navigation**: Enum-backed `FeatureScreen`, `AppRouteConfig`, and `AppNavigator`
- **State management**: {{#use_riverpod}}Riverpod 3 with `NotifierProvider`{{/use_riverpod}}{{^use_riverpod}}Configured via preset{{/use_riverpod}}
- **Localization**: `l10n.yaml` and starter `app_en.arb`
- **Accessibility**: Semantics wrappers, focus traversal, WCAG-compliant themes{{#with_tests}}, widget tests{{/with_tests}}
{{#code_generation}}
- **Code generation**: Opinionated `build.yaml` configured for Riverpod, Drift, AutoMappr, and JSON serialization
{{/code_generation}}
{{#ai_integration}}
- **AI integration**: `.ai/project_context.md` scaffold plus `fly_mcp` dependency
{{/ai_integration}}
{{#with_mcp}}
- **MCP integration**: `.mcp/fly_mcp.yaml` configuration
{{/with_mcp}}

## Platform Support

{{#supports_ios}}
- ✅ **iOS**: Fully supported
{{/supports_ios}}
{{#supports_android}}
- ✅ **Android**: Fully supported
{{/supports_android}}
{{#supports_web}}
- ✅ **Web**: Fully supported
{{/supports_web}}
{{#supports_desktop}}
- ✅ **Desktop** (macOS, Windows, Linux): Supported
{{/supports_desktop}}

## Preset Configuration

This project was generated with the **{{preset}}** preset, which includes:

{{#with_tests}}
- ✅ **Tests**: Enabled
{{/with_tests}}
{{^with_tests}}
- ❌ **Tests**: Disabled
{{/with_tests}}
{{#with_docs}}
- ✅ **Documentation**: Enabled (see `docs/` directory)
{{/with_docs}}
{{^with_docs}}
- ❌ **Documentation**: Disabled
{{/with_docs}}
{{#code_generation}}
- ✅ **Code Generation**: Enabled
{{/code_generation}}
{{^code_generation}}
- ❌ **Code Generation**: Disabled
{{/code_generation}}
{{#ai_integration}}
- ✅ **AI Integration**: Enabled
{{/ai_integration}}
{{^ai_integration}}
- ❌ **AI Integration**: Disabled
{{/ai_integration}}
{{#with_mcp}}
- ✅ **MCP Integration**: Enabled
{{/with_mcp}}
{{^with_mcp}}
- ❌ **MCP Integration**: Disabled
{{/with_mcp}}

## Fly Packages

The following Fly packages are included:

{{#fly_packages}}
- `{{.}}`: Core Fly Foundation package
{{/fly_packages}}

## Recommended Workflows

### Adding a Feature Screen

1. Run `fly generate screen home_dashboard --feature=home` (coming soon).
2. Wire new route inside `FeatureScreen` enum and `AppRouteConfig`.
3. Update localization strings in `lib/l10n` and regenerate via `flutter gen-l10n`.

{{#code_generation}}
### Running Incremental Builds

Use watch mode to keep generated files fresh:
```bash
dart run build_runner watch --delete-conflicting-outputs
```
{{/code_generation}}

### Accessibility Checklist

- Provide descriptive `Semantics` labels for every interactive widget.
- Use the provided `AppTheme` color schemes or verify custom palettes with WCAG tools.
- Keep hit targets ≥ 48px and ensure focus order via `FocusTraversalGroup`.

## Troubleshooting

| Issue | Fix |
| --- | --- |
| `build_runner` conflicts | Run `dart run build_runner build --delete-conflicting-outputs` |
| Missing Flutter SDK | Install from [flutter.dev](https://flutter.dev) and ensure `flutter` is on PATH |
| Template variables validation | Check `generation_mode`, `project_name`, `organization`, and `platforms` values |

{{#with_docs}}
## Documentation

Additional documentation is available in the `docs/` directory:

- `docs/architecture.md`: Architecture overview
{{#features}}
- `docs/features/{{feature}}.md`: {{feature.pascalCase()}} feature documentation
{{/features}}
{{/with_docs}}

## Next Steps

{{#with_mcp}}
- Connect Fly MCP: `fly mcp serve`
{{/with_mcp}}
{{#ai_integration}}
- Export project context for AI agents: `fly context export`
{{/ai_integration}}
- Add features/services using `fly generate feature` or `fly generate service`
- Customize the generated code to fit your needs

Happy building! 🚀

