# Fly CLI Test Project

A dedicated Flutter project for testing Fly CLI capabilities through natural usage scenarios.

## Purpose

This project serves as a test bed for:
- **Developers** to validate their CLI changes
- **AI Assistants** (Cursor, Claude Desktop, etc.) to test CLI features via MCP protocol
- **Natural usage scenario testing** of all CLI capabilities

## Usage

### For Developers

1. **Test CLI Changes**: Make changes to Fly CLI, then test them on this project
2. **Validate Features**: Use this project to verify new CLI features work correctly
3. **Reset When Needed**: Delete and regenerate this project as needed

### For AI Assistants

1. **Discover CLI Features**: Use `./scripts/mcp/list.sh --type=tools` to see available tools
2. **Execute Scenarios**: Call MCP tools to test CLI features on this project
3. **Validate Results**: Check project state after running CLI commands
4. **Reset Project**: Delete and recreate project when needed for clean testing

## Testing Scenarios

This project is designed to test:

### Project Structure
- Feature-based architecture
- Core utilities (router, theme)
- Service layer structure

### CLI Commands to Test

1. **Create Project** (if resetting):
   ```bash
   fly create test_project --template=riverpod
   ```

2. **Add Screens**:
   ```bash
   fly add screen ProductDetail --feature=catalog
   fly add screen Checkout --feature=cart
   ```

3. **Add Services**:
   ```bash
   fly add service ApiService --feature=core --type=api
   fly add service DatabaseService --feature=core --type=database
   ```

4. **Build & Run**:
   ```bash
   flutter build apk --debug
   flutter run
   ```

### MCP Tools to Test

- `fly.template.list` - List available templates
- `fly.template.apply` - Apply template to project
- `fly.add.screen` - Add new screen
- `fly.add.service` - Add new service
- `flutter.build` - Build project
- `flutter.run` - Run project

### MCP Prompts to Test

- `fly.scaffold.page` - Scaffold a new page
- `fly.scaffold.feature` - Scaffold a complete feature
- `fly.scaffold.api.client` - Scaffold an API client

## Project Structure

```
test_project/
├── lib/
│   ├── core/
│   │   ├── router/          # Navigation (test routing generation)
│   │   └── theme/           # Theming (test theme generation)
│   ├── features/
│   │   └── home/            # Home feature (test feature generation)
│   ├── services/            # Services (test service generation)
│   └── main.dart
├── test/
│   └── widget_test.dart     # Tests (test test generation)
└── pubspec.yaml
```

## Resetting the Project

When you need a clean slate for testing:

1. Delete the project directory:
   ```bash
   rm -rf examples/test_project
   ```

2. Recreate using Fly CLI:
   ```bash
   cd examples
   fly create test_project --template=riverpod
   cd test_project
   ```

Or let an AI assistant do this via MCP tools.

## Notes

- This project is intentionally minimal to start
- AI assistants will add features as they test CLI capabilities
- The project can be regenerated anytime
- Keep it in `.gitignore` if it becomes too large

