# Fly 🚀

**The Complete Flutter Ecosystem with AI-Powered Flexibility**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.5.0+-blue.svg)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.10.0+-blue.svg)](https://flutter.dev/)

Fly is more than a CLI tool—it's a **complete, integrated Flutter ecosystem** where architecture,
networking, state management, navigation, storage, forms, and every core component work together
seamlessly. Powered by AI assistants through Model Context Protocol (MCP) integration, Fly gives you
the flexibility to build exactly what you need, when you need it.

---

## 🎯 The Core Idea

### A Unified Flutter Ecosystem

Fly provides a **complete Flutter development ecosystem** where all components are deeply
integrated:

- **Architecture** seamlessly connects with **networking**
- **State management** understands **navigation** flows
- **Forms** integrate with **validation** and **error handling**
- **Storage** works with **caching** and **state synchronization**
- **Every component** knows about and works with every other component

Unlike piecing together disparate packages, Fly delivers a **cohesive system** where components are
designed to work together from day one.

### AI-Powered Flexibility

The true power of Fly comes from its **Model Context Protocol (MCP) integration**, which enables AI
assistants to:

- **Understand your entire project** structure and architecture
- **Generate code** that follows your exact patterns and conventions
- **Modify components** while maintaining integration integrity
- **Suggest improvements** based on your complete ecosystem context
- **Adapt to your needs** dynamically through AI-assisted development

Your AI assistant doesn't just generate code—it understands how your networking layer connects to
your state management, how your forms integrate with validation, and how your navigation flows
through your architecture. This is **complete flexibility** powered by AI.

### The Problem Fly Solves

AI assistants excel at creating **self-contained components** that work well in isolation. However,
they face critical limitations:

- **No Standard Ecosystem** – AI assistants don't have a consistent, integrated ecosystem where all
  components work together seamlessly
- **Inconsistent Patterns** – AI can't always follow the same strict templates or rules every time,
  introducing randomness and variation
- **Integration Hassles** – Developers must constantly think about and ensure full project
  integration with every AI-assisted intervention
- **Manual Oversight Required** – Each AI-generated component requires developer review to ensure it
  integrates properly with existing code

**The Result:** You spend more time fixing integration issues than building features.

### How Fly Addresses This

Fly provides the **standardized ecosystem** that AI assistants need:

- **Built-in Integration** – All components are designed to integrate automatically. No manual
  wiring required.
- **Consistent Templates** – Fly enforces strict templates and patterns that AI assistants can
  follow reliably through MCP integration.
- **Ecosystem Awareness** – AI assistants understand your complete project structure and can
  generate code that maintains integration integrity.
- **Zero Integration Overhead** – Every AI-generated component automatically works with your
  existing ecosystem.

**The Result:** You can trust AI-generated code to integrate seamlessly, every time.

---

## ✨ Key Features

### 🤖 AI-Native Architecture

- **MCP Integration** – Native Model Context Protocol support for direct AI assistant connectivity
- **Machine-Readable Output** – All commands support `--output=json` for structured responses
- **Self-Documenting Schemas** – Export JSON Schema, OpenAPI, or CLI-spec metadata for every command
- **Dry-Run Capabilities** – Preview operations with `--plan` before execution
- **Declarative Manifests** – Define entire projects via YAML specifications
- **Context Generation** – Auto-generate project context for AI assistants with AST analysis,
  dependency scanning, and architecture detection

### 🏗️ Complete Package Ecosystem

Fly provides a curated set of **13 integrated packages** that work together seamlessly:

| Package              | Purpose                 | Integration Points                     |
|----------------------|-------------------------|----------------------------------------|
| **fly_core**         | Architecture foundation | Base for all components                |
| **fly_networking**   | HTTP client             | Integrates with state, errors, logging |
| **fly_state**        | State management        | Connects to networking, navigation     |
| **fly_navigation**   | Routing                 | Understands state and flow guards      |
| **fly_mvvm**         | MVVM patterns           | Works with state and networking        |
| **fly_errors**       | Error handling          | Integrated across all layers           |
| **fly_events**       | Event architecture      | Connects components loosely            |
| **fly_logger**       | Structured logging      | Logs across all components             |
| **fly_localization** | i18n                    | Works with forms, navigation, state    |
| **fly_connectivity** | Network monitoring      | Integrates with networking retry       |
| **fly_feedback**     | User feedback           | Connects with errors and state         |
| **fly_flow_guard**   | Flow control            | Integrates with navigation and auth    |
| **fly_mcp**          | AI integration          | Understands entire ecosystem           |

### ⚡ Lightning Fast

- Create complete Flutter projects in **under 30 seconds**
- Intelligent caching for sub-second repeated operations
- Parallel processing for context generation and analysis
- Optimized template system with Mason integration

### 🎨 Production-Ready Templates

- **Minimal Template** – Clean, simple structure perfect for learning and rapid prototyping
- **Riverpod Template** – Production-ready architecture with state management, routing, networking,
  theming, and all Fly foundation packages

### 🔧 Developer Experience

- **Interactive Wizards** – Guided project creation with `--interactive` flag
- **Shell Completions** – Bash, Zsh, Fish, and PowerShell completion scripts
- **Progress Indicators** – Beautiful CLI output with progress tracking
- **Comprehensive Error Messages** – Actionable suggestions for every error
- **Semantic Aliases** – `create`, `new`, `scaffold`, `init` all work the same way
- **System Diagnostics** – `fly doctor` checks your environment and fixes issues

---

## 🚀 Quick Start

### Installation

```bash
# Install Fly CLI globally
dart pub global activate fly_cli

# Verify installation
fly --help
```

### Create Your First Project

```bash
# Generate a production-ready Riverpod project
fly create my_app --template=riverpod --platforms=ios,android,web

# Or start minimal
fly create my_app --template=minimal
```

### Enable AI Integration

```bash
# Export project context for AI assistants
fly context export --output-file=.cursor/fly_context.json \
  --include-code --include-architecture

# Start MCP server for direct AI integration
fly mcp serve
```

### Generate Components

```bash
# Add a new screen with ViewModel and tests
fly generate screen home --feature=auth --type=list \
  --with-viewmodel --with-tests

# Create an API service with interceptors
fly generate service user_api --feature=core --type=api \
  --with-tests --base-url=https://api.example.com
```

---

## 📦 Package Ecosystem

Fly is organized as a monorepo with the following packages:

### Core Packages

- **[fly_cli](/packages/fly_cli)** – Main CLI tool with AI-friendly interfaces
- **[fly_core](/packages/fly_core)** – Core foundation with BaseScreen, BaseViewModel, and common
  utilities
- **[fly_mcp](/packages/fly_mcp)** – Model Context Protocol integration for AI assistants

### Architecture & State

- **[fly_state](/packages/fly_state)** – State management abstraction layer
- **[fly_mvvm](/packages/fly_mvvm)** – MVVM architecture patterns

### Networking & Data

- **[fly_networking](/packages/fly_networking)** – HTTP client with Dio integration and Riverpod
  providers
- **[fly_connectivity](/packages/fly_connectivity)** – Network connectivity monitoring

### Navigation & Flow

- **[fly_navigation](/packages/fly_navigation)** – Navigation abstractions and routing utilities
- **[fly_flow_guard](/packages/fly_flow_guard)** – Flow control and navigation guards

### Cross-Cutting Concerns

- **[fly_errors](/packages/fly_errors)** – Centralized error handling and exception management
- **[fly_events](/packages/fly_events)** – Event-driven architecture support
- **[fly_logger](/packages/fly_logger)** – Structured logging with multiple output formats
- **[fly_localization](/packages/fly_localization)** – Internationalization and localization
  utilities
- **[fly_feedback](/packages/fly_feedback)** – User feedback collection and management

### Development Tools

- **[foundation_project_lints](/packages/foundation_project_lints)** – Custom linting rules for Fly
  projects

---

## 🏗️ Project Structure

```
Fly/
├── packages/                    # Core packages
│   ├── fly_cli/                # CLI tool
│   ├── fly_core/               # Core foundation
│   ├── fly_networking/         # Networking layer
│   ├── fly_state/              # State management
│   ├── fly_navigation/         # Navigation
│   ├── fly_mvvm/               # MVVM patterns
│   ├── fly_errors/             # Error handling
│   ├── fly_events/             # Event architecture
│   ├── fly_logger/             # Logging
│   ├── fly_localization/       # i18n
│   ├── fly_connectivity/       # Network monitoring
│   ├── fly_feedback/           # User feedback
│   ├── fly_flow_guard/         # Flow guards
│   ├── fly_mcp/                # MCP integration
│   └── foundation_project_lints/ # Linting rules
├── examples/                   # Example projects
│   ├── foundation_project/     # Full-featured example
│   ├── minimal_example/        # Minimal template example
│   └── riverpod_example/       # Riverpod template example
├── docs/                       # Documentation
│   ├── ai-integration/         # AI integration guides
│   ├── mcp/                    # MCP documentation
│   ├── guide/                  # User guides
│   ├── architecture/           # Architecture docs
│   └── technical/              # Technical documentation
├── scripts/                    # Development scripts
├── test/                       # Integration tests
├── pubspec.yaml                # Workspace configuration
└── melos.yaml                  # Melos monorepo config
```

---

## 🤖 AI Integration

### Model Context Protocol (MCP)

Fly includes native MCP integration that enables AI assistants to understand and interact with your
entire project:

```bash
# Start MCP server
fly mcp serve

# Validate MCP setup
fly mcp doctor
```

With MCP running, your AI assistant can:

- **Call Fly commands** programmatically
- **Understand your ecosystem** structure
- **Generate integrated code** that maintains component relationships
- **Modify components** while preserving integration
- **Suggest improvements** based on complete context

### Consistency Through MCP

**Without Fly (Traditional AI Development):**

- AI generates isolated components with random patterns
- Each component uses different integration approaches
- Manual integration fixes required
- Constant oversight needed

**With Fly (MCP-Powered Consistency):**

- AI uses Fly's standard templates consistently
- All components follow identical patterns
- Automatic integration guaranteed
- Zero integration overhead

### Integration Examples

#### Cursor Integration

```bash
# Export project context
fly context export --output-file=.cursor/project_context.md \
  --include-code --include-architecture

# Add to .cursorignore
echo ".ai/" >> .cursorignore
```

#### GitHub Copilot

```bash
# Export command schemas
fly schema export --format=json-schema --output-file=project_schema.json
```

#### ChatGPT Code Interpreter

```bash
# Export comprehensive project info
fly context export --include-dependencies --include-architecture \
  --output-file=project_context.json
fly schema export --format=json-schema --include-examples \
  --output-file=fly_schema.json
```

---

## 📚 Documentation

### Getting Started

- **[Installation Guide](/docs/guide/installation.md)** – Get Fly CLI up and running
- **[Quick Start Guide](/docs/guide/quickstart.md)** – Create your first project
- **[AI Integration Overview](/docs/ai-integration/overview.md)** – Deep dive into AI workflows

### Core Concepts

- **[Command System](/docs/architecture/command-system.md)** – How Fly commands work
- **[Template System](/docs/configuration.md)** – Understanding Fly templates
- **[Package Ecosystem](/packages/fly_cli/README.md)** – Complete package documentation

### AI Integration

- **[MCP Integration Guide](/docs/mcp/AI_INTEGRATION_GUIDE.md)** – Model Context Protocol details
- **[AI Assistant Prompt](/docs/mcp/AI_ASSISTANT_PROMPT.md)** – Optimize AI assistant prompts
- **[Practical Integration Guide](/docs/mcp/PRACTICAL_INTEGRATION_GUIDE.md)** – Real-world examples

### Advanced Topics

- **[Architecture Documentation](/docs/technical/architecture-and-analysis.md)** – Technical deep
  dive
- **[Command Workflow](/docs/architecture/command-workflow.md)** – Command execution flow
- **[Security Assessment](/docs/mcp/SECURITY_ASSESSMENT.md)** – Security considerations

---

## 🛠️ Development

### Prerequisites

- **Dart SDK** `>=3.5.0 <4.0.0`
- **Flutter SDK** `>=3.10.0`
- **Melos** (for monorepo management)

### Setup

```bash
# Clone the repository
git clone https://github.com/fly-cli/fly.git
cd fly

# Install dependencies
melos bootstrap

# Install CLI locally
melos install

# Run tests
melos test

# Format code
melos format

# Run analysis
melos analyze
```

### Melos Scripts

```bash
# Install CLI locally
melos install

# Run all tests
melos test

# Format all code
melos format

# Run analysis
melos analyze

# Build examples
melos build:examples

# Export CLI schema
melos schema:export

# Clean all packages
melos clean
```

### Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests and ensure everything passes (`melos test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

---

## 🎯 Use Cases

### For Flutter Developers

- **Rapid Prototyping** – Generate production-ready projects in seconds
- **Consistent Architecture** – Enforce best practices across your team
- **Component Generation** – Create screens, services, and components with proper integration
- **AI-Assisted Development** – Leverage AI assistants that understand your project structure

### For AI Coding Assistants

- **Structured Project Understanding** – Access complete project context via MCP
- **Consistent Code Generation** – Follow strict templates and patterns
- **Integration Awareness** – Generate code that maintains ecosystem integrity
- **Schema Access** – Understand all available commands and their parameters

### For Enterprise Teams

- **Standardized Projects** – Enforce consistent architecture across teams
- **Governance** – Control project structure and dependencies
- **Scalability** – Generate projects that scale with your organization
- **Documentation** – Auto-generate project documentation and context

---

## 🚦 Status

**Current Version:** 0.1.0  
**Status:** Phase 0 - Critical Foundation

### Completed

- ✅ Monorepo structure with Melos
- ✅ Core CLI package architecture
- ✅ Minimal and Riverpod templates
- ✅ Foundation packages (fly_core, fly_networking, fly_state)
- ✅ Basic command structure
- ✅ Template system with Mason integration
- ✅ JSON output format
- ✅ MCP integration
- ✅ E2E test framework

### In Progress

- 🔄 Security framework (template validation, dependency scanning)
- 🔄 License compliance (MIT compatibility, attribution system)
- 🔄 Platform testing (cross-platform CI/CD)
- 🔄 Additional templates (MVVM, Clean, BLoC)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with [Mason](https://github.com/felangel/mason) for template generation
- Uses [Melos](https://melos.invertase.dev/) for monorepo management
- Inspired by [Very Good CLI](https://github.com/VeryGoodOpenSource/very_good_cli) and other Flutter
  CLI tools

---

## 📞 Support

- **Documentation:** [docs/](/docs)
- **Issues:** [GitHub Issues](https://github.com/fly-cli/fly/issues)
- **Discussions:** [GitHub Discussions](https://github.com/fly-cli/fly/discussions)

---

## 🌟 Star History

If you find Fly useful, please consider giving it a star on GitHub!

---

**Ready to experience the complete Flutter ecosystem?** 🚀

Fly gives you a **unified, integrated Flutter development platform** where all components work
together seamlessly, with **AI-powered flexibility** that adapts to your needs. Start building with
Fly today!

```bash
dart pub global activate fly_cli
fly create my_app --template=riverpod
```

---

*For detailed technical documentation, architecture notes, and contribution guidelines, see
the [documentation directory](/docs).*

