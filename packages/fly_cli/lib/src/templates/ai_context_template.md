# AI Project Context Template

## Project Information
- **Name**: {{project_name}}
- **Template**: {{template}}
- **Organization**: {{organization}}
- **Platforms**: {{platforms}}
- **Created**: {{created_date}}
- **Fly CLI Version**: {{cli_version}}

## Architecture Overview

### Template: {{template}}
{{#if template_description}}
{{template_description}}
{{/if}}

### Project Structure
```
{{project_name}}/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   {{#if template_has_features}}
│   ├── features/
│   │   └── {{feature_name}}/
│   │       ├── presentation/
│   │       │   ├── {{feature_name}}_screen.dart
│   │       │   └── {{feature_name}}_viewmodel.dart
│   │       └── providers.dart
│   {{/if}}
│   {{#if template_has_core}}
│   ├── core/
│   │   ├── providers/
│   │   ├── router/
│   │   └── theme/
│   {{/if}}
│   └── shared/
│       └── widgets/
├── test/
├── pubspec.yaml
└── README.md
```

## Development Patterns

### Screen Creation
Screens extend `BaseScreen<ViewModel>` and follow this pattern:
```dart
class {{ScreenName}}Screen extends BaseScreen<{{ScreenName}}ViewModel> {
  const {{ScreenName}}Screen({Key? key}) : super(key: key);
  
  @override
  {{ScreenName}}ViewModel createViewModel() => {{ScreenName}}ViewModel();
  
  @override
  Widget buildContent(BuildContext context, {{ScreenName}}ViewModel viewModel) {
    return Scaffold(
      body: // Your content here
    );
  }
}
```

### ViewModel Creation
ViewModels extend `BaseViewModel` and follow this pattern:
```dart
class {{ViewModelName}}ViewModel extends BaseViewModel {
  @override
  Future<void> initialize() async {
    // Initialization logic
  }
  
  // Your methods here
}
```

### State Management
- **State**: Managed via `ViewState` sealed class (idle, loading, error, success)
- **Providers**: Use Riverpod providers for dependency injection
- **Error Handling**: Use `Result<T>` type for operations that can fail

### API Integration
- **HTTP Client**: Use `ApiClient` from fly_networking package
- **Error Handling**: Wrap API calls in `runSafe()` method
- **Interceptors**: Configure logging, retry, and error handling

## Available Commands

### Project Management
```bash
# Create new project
fly create <project_name> --template={{template}}

# Add new screen
fly add screen <screen_name>

# Add new service
fly add service <service_name>

# Check system health
fly doctor
```

### AI Integration
```bash
# Export CLI schema for AI context
fly schema export --output=json

# Generate project context
fly context export --output=.ai/project_context.md

# Create from manifest
fly create --from-manifest=project.yaml
```

## Dependencies

### Core Packages
- **fly_core**: BaseScreen, BaseViewModel, ViewState, Result types
- **fly_networking**: HTTP client with Dio integration
- **fly_state**: Riverpod state management utilities

### Template-Specific Dependencies
{{#if template_dependencies}}
{{#each template_dependencies}}
- **{{this}}**: {{description}}
{{/each}}
{{/if}}

## Best Practices

### Code Organization
1. **Feature-first structure**: Organize code by features, not by type
2. **Separation of concerns**: Keep UI, business logic, and data separate
3. **Dependency injection**: Use Riverpod providers for all dependencies
4. **Error handling**: Always use `Result<T>` for operations that can fail

### Testing
1. **Unit tests**: Test ViewModels and business logic
2. **Widget tests**: Test UI components
3. **Integration tests**: Test complete user flows
4. **Coverage**: Aim for 90%+ test coverage

### Performance
1. **Lazy loading**: Use lazy providers for expensive operations
2. **Caching**: Cache API responses and computed values
3. **Memory management**: Dispose of resources properly
4. **Build optimization**: Use const constructors where possible

## Common Patterns

### Loading States
```dart
// In ViewModel
Future<void> loadData() async {
  await runSafe(() async {
    final data = await apiService.getData();
    // State automatically updated to success
  });
}

// In Screen
Widget buildContent(BuildContext context, ViewModel viewModel) {
  return viewModel.state.when(
    idle: () => const SizedBox.shrink(),
    loading: () => const LoadingWidget(),
    error: (error, stackTrace) => ErrorWidget(error: error),
    success: (data) => DataWidget(data: data),
  );
}
```

### Error Handling
```dart
// In ViewModel
Future<Result<User>> login(String email, String password) async {
  return await runSafe(() async {
    return await authService.login(email, password);
  });
}

// Usage
final result = await viewModel.login(email, password);
result.when(
  success: (user) => // Handle success
  failure: (error, stackTrace) => // Handle error
);
```

### API Integration
```dart
// In ViewModel
Future<void> fetchUsers() async {
  await runSafe(() async {
    final users = await apiClient.get<List<User>>('/users');
    // State automatically updated
  });
}
```

## Troubleshooting

### Common Issues
1. **Build errors**: Run `flutter clean && flutter pub get`
2. **State not updating**: Check if ViewModel is properly initialized
3. **API errors**: Check network connection and API endpoints
4. **Performance issues**: Use `flutter analyze` to check for issues

### Debug Commands
```bash
# Check system health
fly doctor

# Analyze project
flutter analyze

# Run tests
flutter test

# Check dependencies
flutter pub deps
```

## AI Integration Examples

### Natural Language to Commands
- "Create a login screen" → `fly add screen login --type=auth`
- "Add user service" → `fly add service user`
- "Check system health" → `fly doctor`

### Manifest Generation
```yaml
# AI can generate this from natural language
name: my_app
template: riverpod
screens:
  - name: login
    type: auth
  - name: home
    type: list
services:
  - name: auth_service
    api_base: https://api.example.com
```

### Code Generation
AI can generate:
- Screen implementations
- ViewModel implementations
- API service classes
- Test files
- Documentation

## Resources

### Documentation
- [Fly CLI Documentation](https://fly-cli.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Flutter Documentation](https://flutter.dev/docs)

### Community
- [GitHub Repository](https://github.com/fly-cli/fly)
- [Discord Community](https://discord.gg/fly-cli)
- [Issue Tracker](https://github.com/fly-cli/fly/issues)

---

*This context file was generated by Fly CLI v{{cli_version}}*
*Last updated: {{updated_date}}*
