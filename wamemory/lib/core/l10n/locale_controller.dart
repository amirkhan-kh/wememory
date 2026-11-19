import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// EN / RU app locale (Settings switch).
class LocaleController extends ChangeNotifier {
  LocaleController({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _key = 'app_locale';

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;
  Locale locale = const Locale('en');

  Future<void> init() async {
    _prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    final code = _prefs!.getString(_key) ?? 'en';
    locale = Locale(code == 'ru' ? 'ru' : 'en');
    notifyListeners();
  }

  Future<void> setLocale(Locale next) async {
    final code = next.languageCode == 'ru' ? 'ru' : 'en';
    locale = Locale(code);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(_key, code);
    notifyListeners();
  }

  bool get isRu => locale.languageCode == 'ru';
}
