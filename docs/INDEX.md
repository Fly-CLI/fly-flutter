---
layout: home

hero:
  name: "Fly CLI"
  text: "The first AI-native Flutter CLI tool"
  tagline: "Develop at the speed of thought with AI-powered project generation"
  image:
    src: /hero-image.png
    alt: Fly CLI Logo
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/fly-cli/fly

features:
  - icon: 🤖
    title: AI-Native Architecture
    details: Built from the ground up for AI coding assistants. Every command outputs machine-readable JSON, making it perfect for Cursor, Copilot, and ChatGPT integration.
  
  - icon: 🏗️
    title: Multi-Architecture Support
    details: Choose from minimal or Riverpod templates. Generate production-ready Flutter apps with best practices built-in, from simple MVVM to complex state management.
  
  - icon: ⚡
    title: Lightning Fast
    details: Create a complete Flutter project in under 30 seconds. Optimized for speed with intelligent caching and parallel processing.
  
  - icon: 🔧
    title: Developer Experience
    details: Interactive wizards, shell completion, progress indicators, and comprehensive error messages with actionable suggestions.
  
  - icon: 📦
    title: Foundation Packages
    details: Built-in packages for networking, state management, and core abstractions. No need to reinvent the wheel - focus on your app logic.
  
  - icon: 🌐
    title: Cross-Platform
    details: Works seamlessly on Windows, macOS, and Linux. Generate projects that run on iOS, Android, Web, macOS, Windows, and Linux.

---

## Why Fly CLI?

### 🚀 **Built for the AI Era**

Fly CLI is the first Flutter CLI tool designed specifically for AI coding assistants. Every command outputs structured JSON, making it easy for AI tools to understand and integrate with your development workflow.

### 🎯 **Production-Ready Templates**

Start with battle-tested templates that follow Flutter best practices:

- **Minimal**: Clean, simple structure for learning and prototyping
- **Riverpod**: Production-ready with state management, routing, and networking

### 🔄 **Seamless Integration**

Works perfectly with your favorite tools:

- **AI Assistants**: Cursor, GitHub Copilot, ChatGPT Code Interpreter
- **IDEs**: VS Code, Android Studio, IntelliJ IDEA
- **CI/CD**: GitHub Actions, GitLab CI, Jenkins

## Quick Start

```bash
# Install Fly CLI
dart pub global activate fly_cli

# Create a new project
fly create my_app --template=riverpod

# Add a new screen
fly add screen home --feature=auth

# Export project context for AI
fly context export
```

## What's Next?

- **[Installation Guide](/guide/installation)** - Get Fly CLI up and running
- **[AI Integration](/ai-integration/overview)** - Learn how to integrate with AI tools
- **[Templates](/guide/templates)** - Explore available project templates
- **[Migration Guides](/migration/very-good-cli)** - Migrate from other CLI tools