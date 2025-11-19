# Fly CLI 🚀

**The Complete Flutter Ecosystem with AI-Powered Flexibility**

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
  integration
  with every AI-assisted intervention
- **Manual Oversight Required** – Each AI-generated component requires developer review to ensure it
  integrates properly with existing code

**The Result:** You spend more time fixing integration issues than building features.

### How Fly Addresses This

Fly provides the **standardized ecosystem** that AI assistants need:

- **Built-in Integration** – All components are designed to integrate automatically. No manual
  wiring
  required.
- **Consistent Templates** – Fly enforces strict templates and patterns that AI assistants can
  follow
  reliably through MCP integration.
- **Ecosystem Awareness** – AI assistants understand your complete project structure and can
  generate
  code that maintains integration integrity.
- **Zero Integration Overhead** – Every AI-generated component automatically works with your
  existing
  ecosystem.

**The Result:** You can trust AI-generated code to integrate seamlessly, every time.

---

## 🏗️ The Complete Ecosystem

### Deeply Integrated Components

Every Fly project comes with a **curated, integrated package suite** where components are designed
to work together:

#### **Architecture Foundation**

- **`fly_core`** – BaseScreen, BaseViewModel, and architectural patterns that form the foundation
- **`fly_mvvm`** – MVVM architecture patterns that integrate with state and navigation
- **`fly_state`** – State management abstractions that work seamlessly with networking and
  navigation

#### **Networking & Data**

- **`fly_networking`** – HTTP client with Dio integration, Riverpod providers, and automatic state
  synchronization
- **`fly_connectivity`** – Network monitoring that integrates with networking retry logic and state
  management

#### **Navigation & Flow**

- **`fly_navigation`** – Routing utilities that understand state management and architecture
  patterns
- **`fly_flow_guard`** – Flow control and navigation guards that integrate with authentication and
  state

#### **Forms & Validation**

- Form generation with integrated validation that connects to state management and error handling
- Form state synchronization with networking layer for seamless API integration

#### **Error Handling & Feedback**

- **`fly_errors`** – Centralized error handling that integrates across networking, forms, and state
- **`fly_feedback`** – User feedback collection that connects with error handling and state
  management
- **`fly_events`** – Event-driven architecture that enables loose coupling while maintaining
  integration

#### **Cross-Cutting Concerns**

- **`fly_logger`** – Structured logging that integrates with networking, state, and error handling
- **`fly_localization`** – i18n support that works seamlessly with forms, navigation, and state

#### **AI Integration**

- **`fly_mcp`** – Model Context Protocol integration that enables AI assistants to understand and
  modify your entire ecosystem

### How Integration Works

When you generate a screen with Fly, it automatically:

1. **Creates the ViewModel** that integrates with `fly_state`
2. **Sets up networking** that connects to your API services
3. **Configures navigation** that understands your routing patterns
4. **Adds form validation** that integrates with error handling
5. **Wires up state management** that synchronizes with networking
6. **Connects logging** that tracks across all layers
7. **Exposes everything** to AI assistants via MCP

**Everything works together. Nothing is isolated.**

---

## 🤖 AI-Powered Flexibility Through MCP

### Complete AI Understanding

Fly's MCP integration enables AI assistants to understand your **entire ecosystem**:

```bash
# Start MCP server - your AI assistant now understands everything
fly mcp serve
```

Your AI assistant can:

- **See your architecture** – Understand how components connect
- **Read your networking** – Know your API patterns and endpoints
- **Understand your state** – See how state flows through your app
- **Know your navigation** – Understand routing and flow guards
- **Access your forms** – See validation rules and form patterns
- **Modify safely** – Make changes that maintain integration integrity

### Flexible Development Workflow

With AI understanding your complete ecosystem, you get **unprecedented flexibility**:

```bash
# Your AI assistant can generate code that integrates perfectly
# because it understands your entire project structure

# Generate a screen that automatically integrates with:
# - Your networking layer
# - Your state management
# - Your navigation patterns
# - Your form validation
# - Your error handling
fly generate screen user_profile --feature=auth --type=detail
```

The AI doesn't just generate code—it generates **integrated code** that fits your ecosystem
perfectly.

### Declarative Flexibility

Define your entire project structure declaratively, and let Fly (and AI) handle the integration:

```yaml
# fly_project.yaml
name: my_app
template: fly_foundation
organization: com.example
platforms: [ios, android, web]

screens:
  - name: home
    feature: home
    type: list
    # AI understands this integrates with networking, state, navigation
    
services:
  - name: user_api
    feature: core
    type: api
    base_url: https://api.example.com
    # AI knows this connects to state management and error handling
```

```bash
# Create the entire integrated ecosystem
fly create --from-manifest=fly_project.yaml
```

---

## 🚀 Quick Start

### Installation

```bash
# Install globally
dart pub global activate fly_cli

# Verify installation
fly --help
```

### Create Your Integrated Ecosystem

```bash
# Generate a complete Flutter project with all integrated components
fly create my_app --template=fly_foundation --platforms=ios,android,web

# This creates:
# - Architecture foundation (fly_core, fly_mvvm)
# - Networking layer (fly_networking) integrated with state
# - State management (fly_state) connected to networking
# - Navigation (fly_navigation) that understands state
# - Error handling (fly_errors) integrated everywhere
# - Logging (fly_logger) connected to all layers
# - And more...
```

### Enable AI Integration

```bash
# Export complete project context for AI understanding
fly context export --output-file=.cursor/fly_context.json \
  --include-code \
  --include-architecture \
  --include-dependencies

# Start MCP server for direct AI integration
fly mcp serve

# Now your AI assistant understands your complete ecosystem
```

### Generate Integrated Components

```bash
# Generate a screen with complete integration
fly generate screen home --feature=auth --type=list \
  --with-viewmodel \
  --with-tests

# This automatically integrates:
# - ViewModel with state management
# - Networking service connections
# - Navigation routing
# - Form validation (if applicable)
# - Error handling
# - Logging

# Generate a service that integrates with state and networking
fly generate service user_api --feature=core --type=api \
  --with-tests \
  --base-url=https://api.example.com

# This automatically integrates:
# - State management providers
# - Error handling
# - Logging and monitoring
# - Retry logic with connectivity
```

---

## 🎨 Key Features

### Complete Integration

- **Architecture ↔ Networking** – ViewModels automatically connect to API services
- **State ↔ Navigation** – State management understands routing flows
- **Forms ↔ Validation ↔ Errors** – Form validation integrates with error handling
- **Storage ↔ State ↔ Networking** – Storage synchronizes with state and API calls
- **Logging ↔ Everything** – Structured logging across all layers
- **AI ↔ Everything** – MCP integration understands the complete ecosystem

### AI-Powered Flexibility

- **MCP Integration** – Native Model Context Protocol support for AI assistants
- **Complete Context** – AI understands your entire project structure and integration
- **Intelligent Generation** – Generate code that maintains integration integrity
- **Adaptive Development** – AI suggests changes that fit your ecosystem
- **Declarative Manifests** – Define projects that AI can understand and modify

### Professional Package Suite

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

---

## 📚 Command Reference

### Project Generation

```bash
# Create a complete integrated ecosystem
fly create my_app --template=fly_foundation

# Create with multiple features
fly generate project my_app --features=home,profile,settings

# Create from manifest (AI can understand and modify)
fly create --from-manifest=fly_project.yaml

# Preview before creating
fly create my_app --template=fly_foundation --plan
```

### Component Generation

```bash
# Generate integrated screen
fly generate screen home --feature=auth --type=list \
  --with-viewmodel --with-tests

# Generate integrated service
fly generate service user_api --feature=core --type=api \
  --with-tests --base-url=https://api.example.com
```

### AI Integration

```bash
# Export complete ecosystem context
fly context export \
  --include-code \
  --include-architecture \
  --include-dependencies \
  --output-file=.cursor/fly_context.json

# Export schemas for AI understanding
fly schema export \
  --format=json-schema \
  --include-examples \
  --output-file=.ai/fly_schema.json

# Start MCP server
fly mcp serve
```

---

## 🤖 AI Integration Guide

### For Cursor Users

```bash
# Export complete ecosystem context
fly context export \
  --output-file=.cursor/project_context.md \
  --include-code \
  --include-architecture \
  --include-dependencies

# Start MCP server for direct integration
fly mcp serve

# Add to .cursorignore
echo ".ai/" >> .cursorignore
```

### For GitHub Copilot

```bash
# Export command schemas
fly schema export --format=json-schema --output-file=project_schema.json

# Export ecosystem context
fly context export --include-dependencies --include-architecture \
  --output-file=project_context.json

# Reference in Copilot Chat prompts
```

### MCP Integration

Fly's MCP integration is the key to AI-powered flexibility:

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

```
You: "Generate a user profile screen"
AI: Creates a screen with random state management pattern
You: "Now generate a settings screen"
AI: Uses different state management pattern
You: "Now generate a home screen"
AI: Uses yet another pattern
Result: Three screens, three different patterns, manual integration required
```

**With Fly (MCP-Powered Consistency):**

```
You: "Generate a user profile screen"
AI (via MCP): Uses Fly's standard template → fly generate screen user_profile
Result: Screen integrates automatically with networking, state, navigation

You: "Now generate a settings screen"
AI (via MCP): Uses same Fly template → fly generate screen settings
Result: Same integration pattern, consistent with user_profile

You: "Now generate a home screen"
AI (via MCP): Uses same Fly template → fly generate screen home
Result: All three screens follow identical patterns, zero integration overhead
```

**Fly's MCP integration ensures AI assistants follow your strict templates and patterns every time,
eliminating randomness and integration hassles.**

---

## 🏗️ How Integration Works

### Example: Generating a User Profile Screen

When you run:

```bash
fly generate screen user_profile --feature=user --type=detail --with-viewmodel
```

Fly automatically creates:

1. **Screen Widget** (`UserProfileScreen`) that extends `BaseScreen` from `fly_core`
2. **ViewModel** (`UserProfileViewModel`) that extends `BaseViewModel` and integrates with:
   - `fly_state` for state management
   - `fly_networking` for API calls
   - `fly_errors` for error handling
   - `fly_logger` for logging
3. **Service Integration** – Connects to user API service with automatic state synchronization
4. **Navigation Integration** – Routing that understands state and flow guards
5. **Form Integration** (if applicable) – Form validation connected to error handling
6. **AI Context** – Exposes everything to MCP so AI understands the integration

**All of this happens automatically. The components are integrated by design.**

### Example: Networking ↔ State Integration

When you generate a service:

```bash
fly generate service user_api --feature=core --type=api
```

Fly creates:

1. **API Service** with Dio client from `fly_networking`
2. **Riverpod Providers** that integrate with `fly_state`
3. **Error Handling** that uses `fly_errors` patterns
4. **Logging** that uses `fly_logger` consistently
5. **Retry Logic** that integrates with `fly_connectivity`
6. **State Synchronization** that works with your ViewModels

**The networking layer knows about state. The state layer knows about networking. They work
together.**

---

## 📖 Templates & Manifests

### Project Templates

- **fly_foundation** – Unified Fly architecture with MVVM, navigation, accessibility, AI scaffolding,
  and build configuration baked in

### Declarative Manifests

Define your complete integrated ecosystem:

```yaml
name: my_app
template: fly_foundation
organization: com.example
platforms: [ios, android, web]

screens:
  - name: home
    feature: home
    type: list
    # AI understands this integrates with networking, state, navigation

services:
  - name: user_api
    feature: core
    type: api
    base_url: https://api.example.com
    # AI knows this connects to state management and error handling
```

```bash
# Create the entire integrated ecosystem
fly create --from-manifest=fly_project.yaml
```

---

## 🎯 The Fly Advantage

### Traditional AI-Assisted Development

```
❌ AI generates isolated components
❌ Each component uses different patterns
❌ No standard ecosystem to follow
❌ Inconsistent integration approaches
❌ Developer must review every AI output
❌ Manual integration fixes required
❌ Randomness introduces bugs
❌ Constant oversight needed
❌ Integration breaks over time
```

### Fly's AI-Powered Ecosystem

```
✅ AI generates integrated components
✅ Consistent patterns enforced by templates
✅ Standard ecosystem for AI to follow
✅ Automatic integration guaranteed
✅ Zero integration overhead
✅ MCP ensures consistency
✅ Components work together by design
✅ Trust AI-generated code
✅ Integration maintained automatically
```

### Traditional Package Approach

```
❌ Find networking package
❌ Find state management package
❌ Find navigation package
❌ Find form validation package
❌ Wire them together manually
❌ Handle integration issues
❌ Maintain compatibility
❌ Update packages individually
❌ Hope they work together
```

### Fly's Integrated Ecosystem

```
✅ Generate complete integrated ecosystem
✅ All components work together by design
✅ AI understands your entire project
✅ Modify with confidence through AI
✅ Update ecosystem cohesively
✅ Everything integrates automatically
```

---

## 🚀 Getting Started

1. **Install Fly CLI** – `dart pub global activate fly_cli`
2. **Create Your Ecosystem** – `fly create my_app --template=fly_foundation`
3. **Enable AI Integration** – `fly mcp serve`
4. **Generate Components** – Let Fly (and AI) handle the integration
5. **Build with Confidence** – Everything works together

---

## 📚 Additional Resources

- **[Documentation Index](/docs/INDEX.md)** – High-level overview and quick links
- **[AI Integration Guide](/docs/ai-integration/overview.md)** – Deep dive into AI workflows and MCP
  integration
- **[Command Architecture](/packages/fly_cli/lib/src/features/README.md)** – Technical architecture
  details
- **[MCP Integration](/packages/fly_cli/lib/src/integrations/README.md)** – Model Context Protocol
  implementation
- **[Performance Improvements](./PERFORMANCE_IMPROVEMENTS.md)** – Performance optimizations and benchmarks
- **[Development Workflow](./DEVELOPMENT_WORKFLOW.md)** – Development guidelines and best practices

---

**Ready to experience the complete Flutter ecosystem?** 🚀

Fly gives you a **unified, integrated Flutter development platform** where all components work
together seamlessly, with **AI-powered flexibility** that adapts to your needs. Start building with
Fly today!

---

*For detailed technical documentation, architecture notes, and contribution guidelines, see
the [repository documentation](/docs).*
