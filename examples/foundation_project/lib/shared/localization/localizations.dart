import 'package:flutter/material.dart';
import 'package:foundation_project/foundation/foundation.dart';
import 'package:foundation_project/foundation/di/global_container.dart';
import 'package:foundation_project/core/providers/logger_provider.dart';
import 'package:foundation_project/l10n/app_localizations.dart';
import 'package:foundation_project/l10n/app_localizations_en.dart';
import 'package:foundation_project/foundation/navigation/app.dart';

/// Get localizations from the current app context
///
/// This function safely retrieves localizations from the current context.
/// It will throw a meaningful error if the context is not available.
AppLocalizations get localizations {
  try {
    final context = App.navigatorKey.currentContext;
    final defaultLocalizations = AppLocalizationsEn();
    if (context == null) return defaultLocalizations;

    return AppLocalizations.of(context);
  } catch (e) {
    GlobalContainer.instance
        .read(loggerProvider('localizations'))
        .error('Error getting localizations: $e');
    return AppLocalizationsEn();
  }
}

/// Get localizations from a specific context
///
/// Use this when you have access to a BuildContext
AppLocalizations getLocalizations(BuildContext context) {
  return AppLocalizations.of(context);
}
