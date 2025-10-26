# Fly CLI Documentation Website

This directory contains the documentation website for Fly CLI, built with VitePress for fast, modern documentation.

## Structure

```
docs/
├── .vitepress/
│   ├── config.ts          # VitePress configuration
│   ├── theme/             # Custom theme components
│   └── public/            # Static assets
├── guide/
│   ├── getting-started.md # Installation and quickstart
│   ├── installation.md    # Detailed installation guide
│   ├── quickstart.md      # Quick start tutorial
│   ├── templates.md       # Template comparison and usage
│   └── commands.md        # All CLI commands reference
├── ai-integration/
│   ├── overview.md        # AI integration overview
│   ├── json-schemas.md    # JSON output schemas
│   ├── manifest-format.md # fly_project.yaml format
│   ├── examples.md        # AI integration examples
│   └── agents.md          # AI agent integration scripts
├── migration/
│   ├── very-good-cli.md   # Migration from Very Good CLI
│   ├── stacked-cli.md      # Migration from Stacked CLI
│   └── vanilla-flutter.md  # Migration from vanilla Flutter
├── api/
│   ├── fly-core.md        # fly_core package API
│   ├── fly-networking.md  # fly_networking package API
│   └── fly-state.md       # fly_state package API
├── examples/
│   ├── minimal-example.md # Minimal template example
│   └── riverpod-example.md # Riverpod template example
└── index.md               # Homepage
```

## Development

### Prerequisites

- Node.js 18+
- npm or yarn

### Setup

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Configuration

The VitePress configuration is in `.vitepress/config.ts`. Key features:

- **Multi-language support** ready (currently English only)
- **Search integration** with Algolia DocSearch
- **GitHub integration** for edit links and last updated
- **Custom theme** with Fly CLI branding
- **Responsive design** for mobile and desktop

### Content Guidelines

- Use **clear, concise language**
- Include **code examples** for every feature
- Provide **step-by-step tutorials**
- Add **troubleshooting sections**
- Include **AI integration examples**

### Deployment

The documentation is automatically deployed to GitHub Pages on every push to the `main` branch.

## Features

### AI-Native Documentation

- **JSON schema documentation** with interactive examples
- **AI agent integration guides** with real scripts
- **Manifest format specifications** with validation
- **Command introspection** examples

### Developer Experience

- **Fast search** with instant results
- **Dark/light mode** support
- **Mobile-responsive** design
- **Copy-to-clipboard** for code blocks
- **Interactive examples** where possible

### Community Features

- **Edit on GitHub** links
- **Last updated** timestamps
- **Version switching** (when multiple versions exist)
- **Feedback collection** forms