# Offline Mode Guide

## Overview

Fly CLI supports offline development for situations with limited or no internet connectivity.

## Preparing for Offline Use

### 1. Download Templates in Advance

```bash
# Download all official templates
fly template fetch minimal
fly template fetch riverpod

# Verify cache
fly template cache list
```

### 2. Bundle Dependencies

```bash
# Pre-download Flutter SDK and dependencies
flutter precache --universal
```

## Using Offline Mode

### Creating Projects Offline

```bash
# Use --offline flag to prevent network requests
fly create my_app --template=riverpod --offline

# Fly CLI will:
# ✓ Use cached templates
# ✓ Skip update checks
# ✓ Use bundled dependencies where possible
```

### Offline Commands

```bash
# List available cached templates
fly template cache list

# Check cache status
fly template cache info

# Add components (uses cached templates)
fly add screen login --offline
```

## Troubleshooting

### Template Not Found

**Error:** Template "X" not found in cache (offline mode)

**Solution:** Download template first with: `fly template fetch X`

### Dependency Issues

**Error:** Failed to resolve dependencies

**Solution:** Use `flutter pub get` in online mode first, then work offline

## Cache Management

### Cache Commands

```bash
# List all cached templates
fly template cache list

# Clear all cached templates
fly template cache clear

# Show cache information
fly template cache info

# Pre-download a specific template
fly template fetch <template_name>
```

### Cache Location

The cache is stored in platform-specific directories:

- **Windows:** `%USERPROFILE%\AppData\Local\fly_cli\cache`
- **macOS:** `~/Library/Application Support/fly_cli/cache`
- **Linux:** `~/.config/fly_cli/cache`

### Cache Expiration

Templates are cached for 7 days by default. After this period, Fly CLI will attempt to download fresh versions when online.

## Best Practices for Offline Development

1. **Download templates in advance** before going offline
2. **Run `flutter pub get`** while online to cache all dependencies
3. **Use the `--offline` flag** to ensure no network requests are made
4. **Periodically refresh cache** when back online to get updates
5. **Keep Flutter SDK updated** for best offline experience
