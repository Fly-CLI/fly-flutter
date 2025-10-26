# Phase 1 MVP Implementation Plan: Fly CLI

## Executive Summary

**Timeline**: 9-10 weeks (2.5 months)  
**Target Launch**: End of Week 10  
**Core Value Proposition**: AI-native Flutter CLI with Riverpod-first architecture, production-ready foundation packages, and machine-readable interfaces

---

## 1. Architecture & Technical Foundation

### 1.1 Technology Stack
- **CLI Framework**: Dart 3.0+ with `args` package for command parsing
- **Template Engine**: Mason for code generation
- **Logging**: `mason_logger` for beautiful CLI output
- **Foundation**: Flutter 3.10+ with Riverpod 2.0+
- **Monorepo**: Melos for package management
- **CI/CD**: GitHub Actions for multi-platform testing
- **AI Integration**: JSON output, declarative manifests, schema export

### 1.2 Repository Structure
```
fly/
├── packages/
│   ├── fly_cli/              # CLI tool with AI-friendly interfaces
│   ├── fly_core/             # Core foundation (BaseScreen, BaseViewModel)
│   ├── fly_networking/       # HTTP client with Riverpod integration
│   └── fly_state/            # Riverpod state management abstractions
├── templates/
│   ├── minimal/              # Bare-bones Flutter structure
│   └── riverpod/             # Full Riverpod architecture
├── examples/
│   ├── minimal_example/      # Demonstrates minimal template
│   └── riverpod_example/     # Demonstrates riverpod template
├── docs/                     # Documentation website + AI integration guide
├── test/                     # Integration tests
├── melos.yaml               # Monorepo configuration
└── README.md
```

### 1.3 Core Commands (MVP)
- `fly create <project_name>` - Create new project with interactive wizard
- `fly add screen <name>` - Generate new screen with ViewModel
- `fly add service <name>` - Generate new service class
- `fly doctor` - System diagnostics and compatibility check
- `fly version` - Show version and check for updates
- `fly schema export` - Export CLI schema for AI context
- `fly context export` - Generate AI context files for project

### 1.4 AI-Friendly Features
- `--output=json` flag on all commands for machine-readable responses
- `--plan` flag for dry-run execution plans
- `--from-manifest=<file>` for declarative project creation
- Auto-generated `.ai/project_context.md` files
- Structured error responses with actionable suggestions

---

## 2. Foundation Packages Specification

### 2.1 fly_core Package

**Key Components**:
- `BaseScreen<VM>` - Stateful widget with ViewModel lifecycle
- `BaseViewModel` - Base class with loading/error states, Riverpod integration
- `ViewState` - Sealed class for state representation (idle/loading/error/success)
- `Result<T>` - Type-safe result wrapper for error handling
- Common utilities (extensions, helpers)

**Example Implementation**:
```dart
// BaseViewModel with Riverpod integration
abstract class BaseViewModel extends StateNotifier<ViewState> {
  BaseViewModel() : super(const ViewState.idle());
  
  Future<void> initialize();
  
  Future<Result<T>> runSafe<T>(Future<T> Function() action) async {
    state = const ViewState.loading();
    try {
      final result = await action();
      state = ViewState.success(result);
      return Result.success(result);
    } catch (e, stackTrace) {
      state = ViewState.error(e);
      return Result.failure(e, stackTrace);
    }
  }
}

// Sealed class for state
sealed class ViewState {
  const ViewState();
  const factory ViewState.idle() = IdleState;
  const factory ViewState.loading() = LoadingState;
  const factory ViewState.error(Object error) = ErrorState;
  const factory ViewState.success<T>(T data) = SuccessState<T>;
}
```

### 2.2 fly_networking Package

**Key Components**:
- `ApiClient` - Dio-based HTTP client with Riverpod provider
- `ApiInterceptor` - Logging, retry, error handling interceptors
- `ApiResponse<T>` - Standardized response wrapper
- Error handling and mapping utilities

**Dependencies**: `dio: ^5.0.0`, `riverpod: ^2.0.0`

### 2.3 fly_state Package

**Key Components**:
- Riverpod provider utilities and extensions
- State management patterns (AsyncValue helpers)
- Common state providers (theme, locale, connectivity)
- Code generation helpers for `@riverpod` annotations

---

## 3. Template Specifications

### 3.1 Minimal Template

**Purpose**: Bare-bones Flutter structure for developers who want full control

**Structure**:
```
my_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   └── screens/
│       └── home_screen.dart
├── test/
├── pubspec.yaml (minimal dependencies)
└── README.md
```

**Dependencies**: Flutter SDK only, no opinionated packages

### 3.2 Riverpod Template

**Purpose**: Production-ready Riverpod architecture with best practices

**Structure**:
```
my_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── providers/        # Global providers
│   │   ├── router/           # GoRouter with Riverpod
│   │   └── theme/            # Theme configuration
│   ├── features/
│   │   └── home/
│   │       ├── presentation/
│   │       │   ├── home_screen.dart
│   │       │   └── home_viewmodel.dart
│   │       └── providers.dart
│   └── shared/               # Shared widgets/utils
├── test/
│   └── features/
│       └── home/
│           └── home_viewmodel_test.dart
├── pubspec.yaml
└── README.md
```

**Dependencies**: fly_core, fly_networking, fly_state, riverpod, riverpod_annotation, go_router

### 3.3 Template Metadata (template.yaml)
```yaml
name: riverpod
version: 1.0.0
description: Production-ready Riverpod architecture
min_flutter_sdk: "3.10.0"
min_dart_sdk: "3.0.0"
variables:
  project_name:
    type: string
    required: true
  org_name:
    type: string
    default: "com.example"
  platforms:
    type: list
    choices: [ios, android, web, macos, windows, linux]
    default: [ios, android]
features:
  - routing
  - state_management
  - error_handling
  - theming
packages:
  - fly_core: ^0.1.0
  - fly_networking: ^0.1.0
  - fly_state: ^0.1.0
```

---

## 4. CLI Implementation Details

### 4.1 Interactive Project Wizard

**User Flow**:
```bash
$ fly create

🚀 Welcome to Fly CLI v0.1.0

✓ Project name: my_awesome_app
✓ Organization: com.mycompany
✓ Template: 
  ○ Minimal (bare-bones structure)
  ● Riverpod (recommended, production-ready)
✓ Platforms:
  ☑ iOS
  ☑ Android
  ☐ Web
  ☐ Desktop

✨ Creating "my_awesome_app" with Riverpod template...
  ✓ Generating project structure (2.1s)
  ✓ Installing dependencies (8.3s)
  ✓ Running code generation (3.7s)
  ✓ Applying linting rules (1.2s)

🎉 Project created successfully!

Next steps:
  cd my_awesome_app
  flutter run
  fly add screen login  # Add a new screen
```

### 4.2 AI-Friendly Command Structure

```dart
// Base command with AI support
abstract class FlyCommand extends Command<int> {
  FlyCommand() {
    argParser.addFlag('output', abbr: 'o', allowed: ['human', 'json']);
    argParser.addFlag('plan', help: 'Show execution plan without running');
  }
  
  bool get jsonOutput => argResults?['output'] == 'json';
  bool get planMode => argResults?['plan'] == true;
  
  @override
  Future<int> run() async {
    final result = await execute();
    
    if (jsonOutput) {
      print(json.encode(result.toJson()));
    } else {
      result.displayHuman();
    }
    
    return result.exitCode;
  }
  
  Future<CommandResult> execute();
}

// packages/fly_cli/lib/src/commands/create_command.dart
class CreateCommand extends FlyCommand {
  @override
  String get name => 'create';
  
  @override
  String get description => 'Create a new Flutter project';
  
  @override
  Future<CommandResult> execute() async {
    final projectName = argResults?.rest.firstOrNull;
    
    if (projectName == null) {
      // Launch interactive wizard
      return await _runInteractiveMode();
    }
    
    // Non-interactive mode with flags
    return await _runDirectMode(projectName);
  }
}
```

### 4.3 Declarative Manifest Support

**Manifest Format (fly_project.yaml)**:
```yaml
name: my_app
template: riverpod
organization: com.example
platforms: [ios, android]

screens:
  - name: login
    type: auth
  - name: home
    type: list

services:
  - name: auth_service
    api_base: https://api.example.com

packages:
  - fly_core
  - fly_networking
  - fly_state
```

**Usage**:
```bash
# Create from manifest file
fly create --from-manifest=fly_project.yaml

# Create from stdin (AI agent integration)
echo "$AI_GENERATED_YAML" | fly create --from-stdin

# Plan mode for validation
fly create --from-manifest=fly_project.yaml --plan --output=json
```

### 4.4 JSON Response Format

```json
{
  "success": true,
  "command": "create",
  "data": {
    "project_name": "my_app",
    "template": "riverpod",
    "files_created": 42,
    "duration_ms": 12450
  },
  "next_steps": [
    {
      "command": "cd my_app",
      "description": "Navigate to project"
    },
    {
      "command": "flutter run",
      "description": "Run the app"
    }
  ],
  "metadata": {
    "cli_version": "0.1.0",
    "timestamp": "2025-01-15T10:30:00Z"
  }
}
```

### 4.5 Error Handling Strategy

```dart
// Structured error types with AI-friendly suggestions
sealed class FlyError implements Exception {
  String get message;
  String get suggestion;
  String? get docsUrl;
  Map<String, dynamic> toJson();
}

class ProjectExistsError extends FlyError {
  final String projectName;
  
  @override
  String get message => 'Directory "$projectName" already exists';
  
  @override
  String get suggestion => 
    'Choose a different name or delete the existing directory:\n'
    '  rm -rf $projectName';
  
  @override
  Map<String, dynamic> toJson() => {
    'code': 'PROJECT_EXISTS',
    'message': message,
    'suggestion': suggestion,
    'fixes': [
      {
        'action': 'rename',
        'command': 'fly create ${projectName}_new',
        'confidence': 0.9
      },
      {
        'action': 'delete',
        'command': 'rm -rf $projectName && fly create $projectName',
        'confidence': 0.8
      }
    ]
  };
}
```

---

## 5. Testing Strategy

### 5.1 CLI Testing
- **Unit Tests**: 90%+ coverage for all command logic
- **Integration Tests**: E2E project generation and validation
- **Platform Tests**: Windows, macOS, Linux in CI matrix
- **AI Integration Tests**: JSON output validation, manifest parsing

**Example Integration Test**:
```dart
test('riverpod template generates buildable project', () async {
  final tempDir = Directory.systemTemp.createTempSync('fly_test_');
  
  // Generate project
  await runCli(['create', 'test_app', '--template=riverpod'], 
               workingDir: tempDir.path);
  
  final projectPath = '${tempDir.path}/test_app';
  
  // Verify structure
  expect(File('$projectPath/lib/main.dart').existsSync(), true);
  expect(Directory('$projectPath/lib/features').existsSync(), true);
  
  // Run flutter analyze
  final analyzeResult = await runFlutter(['analyze'], workingDir: projectPath);
  expect(analyzeResult.exitCode, 0);
  
  // Run flutter test
  final testResult = await runFlutter(['test'], workingDir: projectPath);
  expect(testResult.exitCode, 0);
  
  // Cleanup
  tempDir.deleteSync(recursive: true);
});

test('JSON output format is valid', () async {
  final result = await runCli(['create', 'test_app', '--output=json', '--plan']);
  
  final jsonData = json.decode(result.stdout as String);
  expect(jsonData['success'], isA<bool>());
  expect(jsonData['command'], equals('create'));
  expect(jsonData['data'], isA<Map<String, dynamic>>());
});
```

### 5.2 Foundation Package Testing
- **Unit Tests**: 95%+ coverage
- **Widget Tests**: All BaseScreen states (loading, error, success)
- **Integration Tests**: Cross-package compatibility
- **Performance Tests**: Memory leaks, rebuild counts

---

## 6. Documentation Deliverables

### 6.1 Website Structure (GitHub Pages / VitePress)
```
docs/
├── index.md                    # Landing page
├── getting-started/
│   ├── installation.md         # Installation instructions
│   ├── quickstart.md          # 5-minute quick start
│   └── first-project.md       # Detailed first project tutorial
├── guides/
│   ├── templates.md           # Template comparison
│   ├── architecture.md        # Riverpod architecture guide
│   ├── commands.md            # CLI command reference
│   ├── foundation-packages.md # Package documentation
│   └── ai-integration.md      # AI integration guide
├── migration/
│   ├── from-very-good-cli.md
│   ├── from-stacked-cli.md
│   └── from-vanilla-flutter.md
├── api/
│   ├── fly-core.md            # Auto-generated API docs
│   ├── fly-networking.md
│   └── fly-state.md
└── ai/
    ├── manifest-format.md     # Declarative manifest specification
    ├── json-schema.md         # JSON response schemas
    └── agent-examples.md       # AI agent integration examples
```

### 6.2 AI Integration Guide Content
- **Getting Started**: How to use Fly CLI with AI coding assistants
- **Manifest Format**: Complete specification for fly_project.yaml
- **JSON Schemas**: All command response formats
- **Agent Examples**: Python, Node.js, and shell script examples
- **Best Practices**: Tips for AI-assisted Flutter development

---

## 7. Quality Assurance Checklist

### 7.1 Pre-Launch Validation
- [ ] All CI/CD tests passing (Windows, macOS, Linux)
- [ ] Both templates generate projects that compile without errors
- [ ] `flutter analyze` passes with 0 warnings on generated projects
- [ ] All foundation packages published to pub.dev (dry-run verified)
- [ ] Documentation website deployed and accessible
- [ ] Example projects build and run successfully
- [ ] CLI installation works via `dart pub global activate`
- [ ] Shell completion scripts tested (bash, zsh, fish)
- [ ] JSON output validated for all commands
- [ ] Manifest parsing tested with various configurations
- [ ] AI context files generated correctly

### 7.2 Code Quality Standards
- [ ] 90%+ test coverage on fly_cli
- [ ] 95%+ test coverage on foundation packages
- [ ] All code passes `very_good_analysis` linting
- [ ] All public APIs documented with dartdoc
- [ ] No TODOs or FIXMEs in production code
- [ ] Changelog entries for all packages
- [ ] JSON schemas validated against examples

---

## 8. Success Metrics (Week 10 Evaluation)

### 8.1 Quantitative Metrics
- **Target**: 100+ pub.dev downloads (fly_cli)
- **Target**: 50+ pub.dev downloads (foundation packages)
- **Target**: 10+ GitHub stars
- **Target**: 0 critical (P0/P1) bugs reported
- **Target**: < 30 seconds project creation time
- **Target**: 5+ AI agent integrations demonstrated

### 8.2 Qualitative Metrics
- **Target**: 2+ production projects using Fly CLI
- **Target**: 10+ community feedback responses (surveys/interviews)
- **Target**: 5+ GitHub issues/feature requests (quality engagement)
- **Target**: 1+ positive community mention (Reddit/Discord/Twitter)
- **Target**: 90%+ "would recommend" from early adopters
- **Target**: 1+ AI coding assistant integration (Cursor/Copilot)

### 8.3 Technical Metrics
- **Target**: 90%+ test coverage (CLI)
- **Target**: 95%+ test coverage (foundation packages)
- **Target**: All platforms pass CI (Windows, macOS, Linux)
- **Target**: Generated projects pass `flutter analyze` (0 errors)
- **Target**: All JSON outputs validate against schemas

---

## 9. Risk Mitigation Strategies

### 9.1 Technical Risks
| Risk | Mitigation |
|------|------------|
| Mason API breaking changes | Abstract Mason behind own interface, pin versions |
| Flutter SDK incompatibility | Test against Flutter 3.10, 3.13, 3.16, 3.19 |
| Riverpod code generation issues | Extensive testing with riverpod_generator |
| Cross-platform bugs | Daily CI runs on all platforms |
| JSON schema evolution | Version schemas, maintain backward compatibility |
| AI integration complexity | Start simple, iterate based on feedback |

### 9.2 Schedule Risks
| Risk | Mitigation |
|------|------------|
| Scope creep | Strict feature freeze after Week 7 |
| Testing bottleneck | Automated testing from Week 1 |
| Documentation delay | Write docs alongside code |
| Unexpected complexity | 1-week buffer in timeline |
| AI features taking longer | Core AI features integrated into existing work |

### 9.3 Market Risks
| Risk | Mitigation |
|------|------------|
| Low adoption | Target Flutter communities early, gather feedback |
| Competing tool launches | Focus on unique value (AI-native + Riverpod-first) |
| Negative feedback | Rapid iteration based on user input |
| AI integration not valued | Demonstrate clear productivity gains |

---

## 10. Go/No-Go Decision Criteria

### 10.1 Proceed to Public Launch If:
✅ All technical metrics met (90%+ coverage, 0 P0 bugs)  
✅ Both templates generate working projects  
✅ Documentation complete and reviewed  
✅ At least 3 beta testers report positive experience  
✅ Pub.dev publication dry-run successful  
✅ AI integration features working and documented  

### 10.2 Delay Launch If:
⚠️ Critical bugs discovered in testing  
⚠️ Generated projects fail `flutter analyze`  
⚠️ Platform-specific failures in CI  
⚠️ Incomplete documentation (< 80% coverage)  
⚠️ JSON output schemas not validated  

### 10.3 Cancel/Pivot If:
🛑 Beta feedback indicates fundamental architecture issues  
🛑 Competing tool launches identical solution  
🛑 Resource constraints prevent quality delivery  

---

## 11. Post-MVP Roadmap (Phase 2 Preview)

**Months 4-6 Focus Areas**:
1. **Additional Templates**: MVVM (GetX/Provider), Clean Architecture
2. **VSCode Extension**: Right-click code generation, snippets
3. **Migration Tools**: Automated migration from Very Good CLI, Stacked
4. **Enhanced Packages**: fly_navigation, fly_di, fly_error_handling
5. **Community Features**: Template sharing, plugin system foundation
6. **Advanced AI Features**: Natural language command parsing, visual diff tools

**Success Trigger for Phase 2**:
- 500+ downloads
- 50+ GitHub stars
- Active community engagement (Discord/discussions)
- Proven production usage (5+ apps)
- Demonstrated AI integration value

---

## 12. Resource Requirements

### 12.1 Team Composition
- **1-2 Senior Flutter Developers** (full-time, 9-10 weeks)
  - CLI architecture and implementation
  - Foundation packages development
  - AI integration features
  - Testing and quality assurance
  
- **1 Technical Writer** (part-time, 3-4 weeks)
  - Documentation website
  - AI integration guide
  - Migration guides
  - API documentation review

### 12.2 Infrastructure Costs
- **Domain**: $12/year (fly-cli.dev)
- **GitHub**: Free (open source)
- **GitHub Pages**: Free (documentation hosting)
- **CI/CD**: Free (GitHub Actions for open source)
- **Total Year 1**: ~$12

### 12.3 Time Allocation (per developer)
- **Weeks 1-2**: Architecture setup, monorepo structure, AI schema design (40 hours)
- **Weeks 3-4**: Foundation packages (fly_core, fly_networking, fly_state) (80 hours)
- **Weeks 5-6**: CLI commands, template engine, AI integration (80 hours)
- **Week 7**: Template development (minimal + riverpod) (40 hours)
- **Week 8**: Testing, bug fixes, integration tests (40 hours)
- **Week 9**: AI context generation, documentation (40 hours)
- **Week 10**: Polish, launch preparation, AI examples (40 hours)
- **Total**: ~360 hours per developer

---

## 13. Launch Strategy

### 13.1 Pre-Launch (Week 9)
- [ ] Create landing page with clear value proposition
- [ ] Prepare announcement blog post highlighting AI integration
- [ ] Set up Twitter/X account (@fly_cli_dev)
- [ ] Join Flutter Discord/Reddit communities
- [ ] Identify 5-10 beta testers from community
- [ ] Create AI integration demo videos

### 13.2 Launch Day (Week 10, Day 1)
- [ ] Publish all packages to pub.dev
- [ ] Deploy documentation website
- [ ] Post announcement on:
  - r/FlutterDev (Reddit) - emphasize AI-native features
  - Flutter Discord #tools channel
  - Twitter/X with hashtags #Flutter #FlutterDev #AI
  - LinkedIn Flutter groups
- [ ] Send email to beta testers
- [ ] Create GitHub release with changelog
- [ ] Submit to AI coding assistant communities

### 13.3 Post-Launch (Weeks 10-13)
- [ ] Monitor GitHub issues daily
- [ ] Respond to community questions within 24 hours
- [ ] Collect feedback via surveys
- [ ] Publish 1-2 tutorial videos/articles
- [ ] Engage with users who mention Fly CLI
- [ ] Iterate based on feedback (bug fixes, minor enhancements)
- [ ] Track AI integration usage and gather case studies

---

## 14. Detailed Week-by-Week Breakdown

### **Week 1: Foundation Setup + AI Schema Design**
- Set up monorepo structure with Melos
- Configure CI/CD pipeline (GitHub Actions)
- Create basic CLI entry point and command parser
- Set up linting (very_good_analysis)
- Initialize all package directories
- **AI Integration**: Define JSON output schema for all commands
- **AI Integration**: Design fly_project.yaml manifest format
- Write project README and CONTRIBUTING.md

### **Week 2: Core Architecture + AI Infrastructure**
- Implement fly_core package structure
- Build BaseViewModel with Riverpod StateNotifier
- Create ViewState sealed class hierarchy
- Implement Result<T> type for error handling
- Add common utilities and extensions
- **AI Integration**: Create AI context file templates
- Write unit tests (target: 95% coverage)

### **Week 3: Networking & State Packages**
- Implement fly_networking with Dio + Riverpod
- Create ApiClient, interceptors, error handling
- Build fly_state package with provider utilities
- Add AsyncValue helpers and common providers
- Integration testing between packages
- Documentation for all public APIs

### **Week 4: CLI Commands (Part 1) + AI Output**
- Implement `fly create` command
- Build interactive wizard with prompts
- Add project validation logic
- Implement `fly doctor` diagnostics command
- Add `fly version` with update checking
- **AI Integration**: Implement `--output=json` flag infrastructure
- **AI Integration**: Build `fly schema export` command
- Unit tests for all commands

### **Week 5: Template Engine & Generation**
- Integrate Mason for code generation
- Create template management system
- Build Mason bricks for minimal template
- Build Mason bricks for Riverpod template
- Implement hooks (pre_gen, post_gen)
- **AI Integration**: Add `--plan` (dry-run) mode to create command
- Test template rendering and variable substitution

### **Week 6: CLI Commands (Part 2) + AI Manifests**
- Implement `fly add screen` command
- Implement `fly add service` command
- Add code formatting after generation
- Enhance error messages with suggestions
- Add progress indicators and spinners
- **AI Integration**: Add `--from-manifest` support for project creation
- **AI Integration**: Implement `fly context export` command
- Integration tests for full workflows

### **Week 7: Example Projects & AI Aliases**
- Create minimal_example app
- Create riverpod_example app (realistic app with API calls)
- Add shell completion scripts (bash, zsh)
- Performance optimization (lazy loading, caching)
- **AI Integration**: Add semantic command aliases (generate, scaffold, new)
- Final bug fixes and edge case handling
- Code review and refactoring

### **Week 8: Testing & Quality Assurance**
- E2E integration tests (full project generation)
- Platform-specific testing (Windows, macOS, Linux)
- Performance testing (project creation speed)
- Memory leak detection
- Generated project validation (analyze, test)
- Security review (input validation, file operations)
- **AI Integration**: JSON output validation tests

### **Week 9: Documentation & AI Examples**
- Build documentation website (VitePress/Docusaurus)
- Write all guides (installation, quickstart, templates)
- Create migration guides (3 competing tools)
- Generate API documentation (dartdoc)
- **AI Integration**: Create "AI Integration Guide"
- **AI Integration**: Document JSON schemas and manifest formats
- **AI Integration**: Provide example AI agent integration scripts
- Create video tutorial (5-10 minutes)

### **Week 10: Launch Preparation & Execution**
- Prepare launch announcements
- Final testing and bug fixes
- Publish to pub.dev
- Deploy documentation website
- **Launch!** 🚀
- Monitor initial feedback and usage

---

## 15. Appendix: Key Files & Their Purposes

### CLI Package Files
- `bin/fly.dart` - Entry point, delegates to CommandRunner
- `lib/src/command_runner.dart` - Main command orchestration
- `lib/src/commands/create_command.dart` - Project creation logic
- `lib/src/commands/add_command.dart` - Component generation (screens, services)
- `lib/src/commands/doctor_command.dart` - System diagnostics
- `lib/src/commands/schema_command.dart` - AI schema export
- `lib/src/commands/context_command.dart` - AI context generation
- `lib/src/generators/project_generator.dart` - Project scaffolding
- `lib/src/templates/template_manager.dart` - Template loading and caching
- `lib/src/manifests/manifest_parser.dart` - Declarative manifest parsing
- `lib/src/utils/logger.dart` - Styled console output
- `lib/src/utils/pub_utils.dart` - Pub.dev operations (install, get)
- `lib/src/utils/file_utils.dart` - File system operations
- `lib/src/ai/context_generator.dart` - AI context file generation

### Foundation Package Files
- `packages/fly_core/lib/src/screens/base_screen.dart`
- `packages/fly_core/lib/src/viewmodels/base_viewmodel.dart`
- `packages/fly_core/lib/src/models/view_state.dart`
- `packages/fly_core/lib/src/models/result.dart`
- `packages/fly_networking/lib/src/api_client.dart`
- `packages/fly_networking/lib/src/interceptors/`
- `packages/fly_state/lib/src/providers/`

### Configuration Files
- `melos.yaml` - Monorepo configuration
- `.github/workflows/ci.yml` - CI/CD pipeline
- `templates/minimal/template.yaml` - Minimal template config
- `templates/riverpod/template.yaml` - Riverpod template config
- `docs/ai/manifest-schema.json` - Manifest format schema

---

## 16. AI-Friendly Architecture Integration

### 16.1 Core AI Features (MVP)

**Machine-Readable Output**:
- Every command supports `--output=json` flag for structured responses
- Errors include machine-readable suggestions with fix commands
- All responses follow consistent JSON schema

**Declarative Manifests**:
- Support `--from-manifest=fly_project.yaml` for project creation
- AI can generate complete project specifications
- Manifest includes screens, services, packages, and configuration

**CLI Introspection**:
- `fly schema export --output=json` - Export command schemas for AI context
- `fly template describe <name> --output=json` - Get template specifications
- Self-documenting CLI that AI can learn from

**Dry-Run Mode**:
- `--plan` flag shows execution plan without running
- AI can validate commands before execution
- Includes file creation preview and estimated duration

**AI Context Generation**:
- Auto-generate `.ai/project_context.md` after project creation
- Provides architecture overview, conventions, and available commands
- Helps AI coding assistants understand project structure

### 16.2 Implementation Details

**Base Command Structure**:
```dart
abstract class FlyCommand extends Command<int> {
  FlyCommand() {
    argParser.addFlag('output', abbr: 'o', allowed: ['human', 'json']);
    argParser.addFlag('plan', help: 'Show execution plan without running');
  }
  
  bool get jsonOutput => argResults?['output'] == 'json';
  bool get planMode => argResults?['plan'] == true;
  
  @override
  Future<int> run() async {
    final result = await execute();
    
    if (jsonOutput) {
      print(json.encode(result.toJson()));
    } else {
      result.displayHuman();
    }
    
    return result.exitCode;
  }
  
  Future<CommandResult> execute();
}
```

**Manifest Format (fly_project.yaml)**:
```yaml
name: my_app
template: riverpod
organization: com.example
platforms: [ios, android]

screens:
  - name: login
    type: auth
  - name: home
    type: list

services:
  - name: auth_service
    api_base: https://api.example.com

packages:
  - fly_core
  - fly_networking
  - fly_state
```

**JSON Response Format**:
```json
{
  "success": true,
  "command": "create",
  "data": {
    "project_name": "my_app",
    "template": "riverpod",
    "files_created": 42,
    "duration_ms": 12450
  },
  "next_steps": [
    {
      "command": "cd my_app",
      "description": "Navigate to project"
    },
    {
      "command": "flutter run",
      "description": "Run the app"
    }
  ],
  "metadata": {
    "cli_version": "0.1.0",
    "timestamp": "2025-01-15T10:30:00Z"
  }
}
```

### 16.3 New Commands for AI Integration

- `fly schema export` - Export CLI schema for AI training/context
- `fly context export` - Generate AI context files for project
- `fly create --from-manifest=<file>` - Create from declarative manifest
- All commands support `--output=json` and `--plan` flags

### 16.4 Updated Week-by-Week Integration

**Week 1 Additions**:
- Define JSON output schema for all command responses
- Design fly_project.yaml manifest format
- Create AI context file templates

**Week 4 Additions**:
- Implement `--output=json` flag infrastructure
- Build `fly schema export` command
- Add `--plan` (dry-run) mode to create command

**Week 6 Additions**:
- Add `--from-manifest` support for project creation
- Implement `fly context export` command
- Add semantic command aliases (generate, scaffold, new)

**Week 9 Additions**:
- Create "AI Integration Guide" in documentation
- Document JSON schemas and manifest formats
- Provide example AI agent integration scripts

### 16.5 Timeline Impact

**New Timeline**: 9-10 weeks (additional 1 week)
- Core AI features integrated into existing work (+3 days)
- Schema export and manifest support (+2 days)
- AI context generation and documentation (+2 days)

### 16.6 Competitive Advantage

**First AI-Native Flutter CLI**:
- ✅ Native integration with Cursor, GitHub Copilot, ChatGPT
- ✅ Declarative project generation from natural language
- ✅ Machine-readable everything (output, errors, schemas)
- ✅ Self-documenting for AI learning
- ✅ Future-proof for next-gen AI coding assistants

---

## Conclusion

This plan delivers a **focused, production-ready, AI-native MVP** in **9-10 weeks** with:

- ✅ 2 high-quality templates (minimal + Riverpod)
- ✅ 3 foundation packages (core, networking, state)
- ✅ 7 core CLI commands + AI integration commands
- ✅ **AI-friendly architecture (JSON output, manifests, schemas)**
- ✅ Comprehensive documentation including AI integration guide
- ✅ Multi-platform support
- ✅ Clear path to Phase 2

**Next Action**: Approve updated plan and begin Week 1 implementation.

### To-dos

- [ ] Set up monorepo structure with Melos, CI/CD pipeline, linting, and AI schema design
- [ ] Implement fly_core package with BaseViewModel, ViewState, Result types, and utilities
- [ ] Build fly_networking package with Dio client, Riverpod integration, and interceptors
- [ ] Create fly_state package with Riverpod provider utilities and AsyncValue helpers
- [ ] Implement core CLI commands: create, doctor, version with interactive wizard and AI output
- [ ] Integrate Mason template engine and create minimal + Riverpod templates
- [ ] Implement fly add screen/service commands with code generation and AI manifests
- [ ] Create minimal_example and riverpod_example applications
- [ ] Write integration tests, E2E tests, platform-specific testing, and AI integration tests
- [ ] Build documentation website, write guides, create migration docs, AI integration guide, and tutorial video
- [ ] Publish packages to pub.dev, deploy docs, prepare announcements, and execute launch
