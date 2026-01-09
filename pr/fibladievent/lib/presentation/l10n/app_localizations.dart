// lib/l10n/app_localizations.dart
import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ar.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale) {
    _localizedStrings = _getLocalizedStrings(locale.languageCode);
  }

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Map<String, String> _getLocalizedStrings(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return AppLocalizationsFr.values;
      case 'ar':
        return AppLocalizationsAr.values;
      default:
        return AppLocalizationsEn.values;
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Helper getter
  String get appName => translate('app_name');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Extension for easy access
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }
  
  AppLocalizations? get loc => AppLocalizations.of(this);
}