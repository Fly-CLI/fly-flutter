# Installation

Fly CLI is distributed as a Dart package and can be installed using `dart pub global activate`.

## Prerequisites

Before installing Fly CLI, ensure you have the following installed:

- **Dart SDK** (3.0.0 or later)
- **Flutter SDK** (3.10.0 or later)

### Check Your Installation

```bash
# Check Dart version
dart --version

# Check Flutter version
flutter --version
```

If you don't have Dart or Flutter installed, follow the [official installation guides](https://dart.dev/get-dart) and [Flutter installation guide](https://docs.flutter.dev/get-started/install).

## Installation Methods

### Method 1: Global Activation (Recommended)

```bash
# Install Fly CLI globally
dart pub global activate fly_cli

# Verify installation
fly --version
```

### Method 2: From Source

If you want to install from the latest source code:

```bash
# Clone the repository
git clone https://github.com/fly-cli/fly.git
cd fly

# Install dependencies
dart pub get

# Build and install
dart pub global activate --source path .
```

### Method 3: Development Installation

For contributors and developers:

```bash
# Clone the repository
git clone https://github.com/fly-cli/fly.git
cd fly

# Install dependencies
melos bootstrap

# Run from source
dart run packages/fly_cli/bin/fly.dart --version
```

## Verify Installation

After installation, verify that Fly CLI is working correctly:

```bash
# Check version
fly --version

# Run diagnostics
fly doctor

# Test project creation (dry run)
fly create test_project --template=minimal --plan
```

## Shell Completion

Fly CLI supports shell completion for better developer experience.

### Bash

```bash
# Add to your ~/.bashrc or ~/.bash_profile
source <(fly completion bash)

# Or manually add the completion script
echo 'source <(fly completion bash)' >> ~/.bashrc
```

### Zsh

```bash
# Add to your ~/.zshrc
source <(fly completion zsh)

# Or manually add the completion script
echo 'source <(fly completion zsh)' >> ~/.zshrc
```

### Fish

```bash
# Add to your ~/.config/fish/config.fish
fly completion fish | source

# Or manually add the completion script
fly completion fish > ~/.config/fish/completions/fly.fish
```

## Troubleshooting

### Command Not Found

If you get a "command not found" error:

```bash
# Check if pub global bin is in your PATH
echo $PATH | grep -q "$HOME/.pub-cache/bin"

# If not, add it to your shell profile
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.bashrc
# or ~/.zshrc for zsh users
```

### Permission Issues

If you encounter permission issues:

```bash
# Check pub cache permissions
ls -la ~/.pub-cache/bin/

# Fix permissions if needed
chmod +x ~/.pub-cache/bin/fly
```

### Flutter Not Found

If Fly CLI can't find Flutter:

```bash
# Check Flutter installation
which flutter

# Add Flutter to PATH if needed
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.bashrc
```

### Doctor Command Issues

Run the doctor command to diagnose common issues:

```bash
fly doctor
```

This will check:
- Dart SDK installation
- Flutter SDK installation
- PATH configuration
- Template availability
- Network connectivity

## Uninstallation

To uninstall Fly CLI:

```bash
# Remove global package
dart pub global deactivate fly_cli

# Remove from PATH (if manually added)
# Edit your shell profile and remove the PATH export
```

## Next Steps

Now that Fly CLI is installed, you can:

1. **[Create your first project](/guide/quickstart)** - Learn the basics
2. **[Explore templates](/guide/templates)** - Choose the right template for your project
3. **[Set up AI integration](/ai-integration/overview)** - Integrate with AI coding assistants
4. **[Learn the commands](/guide/commands)** - Master all Fly CLI commands

## Getting Help

If you encounter any issues:

- **GitHub Issues**: [Report bugs or request features](https://github.com/fly-cli/fly/issues)
- **Discord**: Join our [Discord community](https://discord.gg/fly-cli)
- **Documentation**: Browse the [complete documentation](/)
- **Examples**: Check out [example projects](/examples/minimal-example)
