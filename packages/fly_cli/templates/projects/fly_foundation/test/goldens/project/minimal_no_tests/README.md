# StarterApp

Minimal Fly foundation project without tests

## Quick Start (⏱️ ~5 minutes)

1. **Install prerequisites**
   ```bash
   dart pub global activate fly_cli
   flutter upgrade
   ```
2. **Install dependencies**
   ```bash
   cd starter_app
   flutter pub get
   ```


3. **Code generation is disabled** in this preset.

4. **Run the app**
   ```bash




   ```



## Generated Architecture

- **Core foundation**: `BaseScreen`/`BaseViewModel` built on `fly_mvvm`
- **Navigation**: Enum-backed `FeatureScreen`, `AppRouteConfig`, and `AppNavigator`
- **State management**: Configured via preset
- **Localization**: `l10n.yaml` and starter `app_en.arb`
- **Accessibility**: Semantics wrappers, focus traversal, WCAG-compliant themes




## Platform Support






## Preset Configuration

This project was generated with the **minimal** preset, which includes:



- ❌ **Tests**: Disabled



- ❌ **Documentation**: Disabled



- ❌ **Code Generation**: Disabled



- ❌ **AI Integration**: Disabled



- ❌ **MCP Integration**: Disabled


## Fly Packages

The following Fly packages are included:


- `fly_core`: Core Fly Foundation package

- `fly_mvvm`: Core Fly Foundation package

- `fly_state`: Core Fly Foundation package

- `fly_navigation`: Core Fly Foundation package

- `fly_flow_guard`: Core Fly Foundation package

- `fly_logger`: Core Fly Foundation package

- `fly_events`: Core Fly Foundation package

- `fly_networking`: Core Fly Foundation package


## Recommended Workflows

### Adding a Feature Screen

1. Run `fly generate screen home_dashboard --feature=home` (coming soon).
2. Wire new route inside `FeatureScreen` enum and `AppRouteConfig`.
3. Update localization strings in `lib/l10n` and regenerate via `flutter gen-l10n`.



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



- Add features/services using `fly generate feature` or `fly generate service`
- Customize the generated code to fit your needs

Happy building! 🚀

