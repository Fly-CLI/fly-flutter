import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_localization/fly_localization.dart';
import 'package:foundation_project/shared/localization/foundation_localization_provider_impl.dart';
import 'package:foundation_project/shared/localization/localizations.dart';

/// Provider for FoundationLocalizationProvider
///
/// Returns a FoundationLocalizationProvider implementation that wraps
/// the application's AppLocalizations. Returns null if context is not
/// available (e.g., during initialization).
///
/// Usage:
/// ```dart
/// final provider = ref.read(foundationLocalizationProvider);
/// if (provider != null) {
///   // Use provider
/// }
/// ```
final foundationLocalizationProvider =
    Provider<FoundationLocalizationProvider?>((ref) {
  try {
    final appLocalizations = localizations;
    return FoundationLocalizationProviderImpl(appLocalizations);
  } catch (e) {
    // Context might not be available during initialization
    // Return null - foundation components will use fallback messages
    return null;
  }
});

