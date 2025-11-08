# fly_localization

Abstract localization interface for foundation components.

## Features

- Abstract interface for localization strings
- Default English implementation
- Foundation component integration

## Usage

```dart
import 'package:fly_localization/fly_localization.dart';

// Use default implementation
final provider = DefaultFoundationLocalizationProvider();

// Or implement your own
class AppLocalizationProvider implements FoundationLocalizationProvider {
  final AppLocalizations _localizations;

  AppLocalizationProvider(this._localizations);

  @override
  String get networkErrorConnectionRecovery =>
      _localizations.networkErrorConnectionRecovery;

  // ... implement all other getters
}

// Use as fallback
final provider = appLocalizationProvider ?? DefaultFoundationLocalizationProvider();
```

