# fly_foundation

Meta-package that re-exports all Fly foundation packages for convenience.

## Overview

Instead of importing multiple foundation packages individually:

```dart
import 'package:fly_logger/fly_logger.dart';
import 'package:fly_errors/fly_errors.dart';
import 'package:fly_operations/fly_operations.dart';
// ... etc
```

You can import everything from a single package:

```dart
import 'package:fly_foundation/fly_foundation.dart';
```

## Included Packages

This meta-package re-exports:

- `fly_logger` - Structured logging infrastructure
- `fly_localization` - Localization interface abstraction
- `fly_di` - Dependency injection container abstraction
- `fly_connectivity` - Network connectivity checking
- `fly_errors` - Error handling and formatting
- `fly_events` - Event system with plugins
- `fly_navigation` - Navigation service abstraction
- `fly_operations` - Async operation handling
- `fly_mvvm` - MVVM base classes
- `fly_feedback` - User feedback system (used by foundation components)

## Usage

Add to your `pubspec.yaml`:

```yaml
dependencies:
  fly_foundation:
    path: ../../packages/fly_foundation
```

Then import:

```dart
import 'package:fly_foundation/fly_foundation.dart';
```

## Individual Package Imports

If you prefer to import packages individually for better tree-shaking or explicit dependencies, you can still use the individual packages directly:

```dart
import 'package:fly_logger/fly_logger.dart';
import 'package:fly_errors/fly_errors.dart';
```

## Note

This is a convenience package. For production applications, consider importing individual packages to:
- Better understand dependencies
- Enable better tree-shaking
- Have more explicit control over versions

