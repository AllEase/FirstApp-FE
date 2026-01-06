import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString(
      'assets/languages/${locale.languageCode}.json',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return true;
  }

  String translate(String key, {Map<String, String>? arguments}) {
    String value = _localizedStrings[key] ?? key;
    if (arguments != null) {
      arguments.forEach((placeholder, replacement) {
        value = value.replaceAll('{$placeholder}', replacement);
      });
    }
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load(); // Load the JSON here
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  String loc(String key, {Map<String, String>? args}) =>
      AppLocalizations.of(this)?.translate(key, arguments: args) ?? key;
}
