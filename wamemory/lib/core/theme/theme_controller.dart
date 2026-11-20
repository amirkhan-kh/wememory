import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// Persists WhatsApp-like Appearance: system / light / dark.
class ThemeController extends ChangeNotifier {
  ThemeController({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _key = 'theme_mode';

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;
  ThemeMode mode = ThemeMode.system;

  Future<void> init() async {
    _prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key) ?? 'system';
    mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _syncColors();
    notifyListeners();
  }

  Future<void> setMode(ThemeMode next) async {
    mode = next;
    final label = switch (next) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs?.setString(_key, label);
    _syncColors();
    notifyListeners();
  }

  void syncFromPlatform(Brightness platform) {
    if (mode == ThemeMode.system) {
      AppColors.apply(platform);
      notifyListeners();
    }
  }

  void _syncColors() {
    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final b = switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platform,
    };
    AppColors.apply(b);
  }

  Brightness resolve(Brightness platform) {
    return switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platform,
    };
  }
}
