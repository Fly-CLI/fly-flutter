# fly_foundation Template

Welcome to `fly_foundation`, the unified Fly CLI template that bootstraps a production-ready Flutter codebase with MVVM, navigation, accessibility, localization, and AI integrations out of the box.

## Quick Start (⏱️ ~5 minutes)

1. **Install prerequisites**
   ```bash
   dart pub global activate fly_cli
   flutter upgrade
   ```
2. **Create a project**
   ```bash
   fly generate project {{project_name.snakeCase()}} --template=fly_foundation \
     --organization={{organization}} --platforms=ios,android,web
   ```
3. **Install dependencies & run code generation**
   ```bash
   cd {{project_name.snakeCase()}}
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Run the app**
   ```bash
   flutter run
   ```
5. **Add context for AI workflows (optional)**
   ```bash
   fly context export
   ```

## Generated Architecture

- **Core foundation**: `BaseScreen`/`BaseViewModel` built on `fly_mvvm`
- **Navigation**: Enum-backed `FeatureScreen`, `AppRouteConfig`, and `AppNavigator`
- **State management**: Riverpod 3 with `NotifierProvider`
- **Localization**: `l10n.yaml` and starter `app_en.arb`
- **Accessibility**: Semantics wrappers, focus traversal, WCAG-compliant themes, widget tests
- **Code generation**: Opinionated `build.yaml` configured for Riverpod, Drift, AutoMappr, and JSON serialization
- **AI/MCP hooks**: `.ai/project_context.md` scaffold plus optional `fly_mcp` dependency

## Recommended Workflows

### Adding a Feature Screen

1. Run `fly generate screen home_dashboard --feature=home` (coming soon).
2. Wire new route inside `FeatureScreen` enum and `AppRouteConfig`.
3. Update localization strings in `lib/l10n` and regenerate via `flutter gen-l10n`.

### Running Incremental Builds

Use watch mode to keep generated files fresh:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

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

## Next Steps

- Connect Fly MCP: `fly mcp serve`
- Export project context for AI agents: `fly context export`
- Add analytics/services/providers as the unified template modes roll out

Happy building! 🚀
