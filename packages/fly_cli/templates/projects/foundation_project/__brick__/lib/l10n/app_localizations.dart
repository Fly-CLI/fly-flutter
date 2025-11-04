import 'package:flutter/material.dart';

/// Simple app localizations for foundation project
/// In production, this would use proper Flutter localization
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context) ??
        AppLocalizations(const Locale('en'));
  }

  // General messages
  String get actionRetry => 'Retry';
  String get actionCancel => 'Cancel';
  String get actionOk => 'OK';
  String get actionSave => 'Save';
  String get actionSubmit => 'Submit';
  String get errorOccurred => 'An error occurred. Please try again.';
}

/// Localizations delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

