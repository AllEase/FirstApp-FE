import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); 

  Locale get locale => _locale;
  final List<Locale> _supportedLocales = const [
    Locale('en'),
    Locale('hi'),
    Locale('te'),
  ];

  void setLocale(Locale newLocale) {
    if (!_supportedLocales.contains(newLocale)) return;
    
    _locale = newLocale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('te');
    notifyListeners();
  }
}