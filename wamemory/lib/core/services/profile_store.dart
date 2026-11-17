import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local "me" profile (WA-like header). Not Meta WhatsApp account data.
class ProfileStore extends ChangeNotifier {
  ProfileStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _keyName = 'profile_display_name';
  static const _keyAbout = 'profile_about';
  static const _keyColor = 'profile_avatar_color';
  static const _keyPhone = 'profile_phone';
  static const _keyPhoto = 'profile_photo_path';
  static const _keySetup = 'profile_setup_complete';

  static const defaultName = 'You';
  static const defaultAbout = 'Hey there! I am using WAMemory.';
  static const defaultColor = '#00A884';

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  String displayName = defaultName;
  String about = defaultAbout;
  String avatarColor = defaultColor;
  String phone = '';
  String? photoPath;
  bool setupComplete = false;

  Future<void> init() async {
    _prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    displayName = _prefs!.getString(_keyName) ?? defaultName;
    about = _prefs!.getString(_keyAbout) ?? defaultAbout;
    avatarColor = _prefs!.getString(_keyColor) ?? defaultColor;
    phone = _prefs!.getString(_keyPhone) ?? '';
    photoPath = _prefs!.getString(_keyPhoto);
    if (photoPath != null && photoPath!.isEmpty) photoPath = null;
    setupComplete = _prefs!.getBool(_keySetup) ?? false;
    notifyListeners();
  }

  Future<void> update({
    String? displayName,
    String? about,
    String? avatarColor,
    String? phone,
    String? photoPath,
    bool clearPhoto = false,
    bool? setupComplete,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    if (displayName != null) {
      final trimmed = displayName.trim();
      this.displayName = trimmed.isEmpty ? defaultName : trimmed;
      await prefs.setString(_keyName, this.displayName);
    }
    if (about != null) {
      final trimmed = about.trim();
      this.about = trimmed.isEmpty ? defaultAbout : trimmed;
      await prefs.setString(_keyAbout, this.about);
    }
    if (avatarColor != null && avatarColor.isNotEmpty) {
      this.avatarColor = avatarColor;
      await prefs.setString(_keyColor, this.avatarColor);
    }
    if (phone != null) {
      this.phone = phone.replaceAll(RegExp(r'[^\d]'), '');
      await prefs.setString(_keyPhone, this.phone);
    }
    if (clearPhoto) {
      this.photoPath = null;
      await prefs.remove(_keyPhoto);
    } else if (photoPath != null) {
      this.photoPath = photoPath.isEmpty ? null : photoPath;
      if (this.photoPath == null) {
        await prefs.remove(_keyPhoto);
      } else {
        await prefs.setString(_keyPhoto, this.photoPath!);
      }
    }
    if (setupComplete != null) {
      this.setupComplete = setupComplete;
      await prefs.setBool(_keySetup, setupComplete);
    }
    notifyListeners();
  }

  Future<void> markSetupComplete() => update(setupComplete: true);
}
