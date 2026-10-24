import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Small settings only. The habit rows live in SQLite, not here.
class SettingsStore extends ChangeNotifier {
  SettingsStore._();

  static final SettingsStore instance = SettingsStore._();

  static const _nameKey = 'display_name';
  static const _darkKey = 'dark_mode';

  String displayName = '';
  bool darkMode = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    displayName = prefs.getString(_nameKey) ?? '';
    darkMode = prefs.getBool(_darkKey) ?? false;
    notifyListeners();
  }

  Future<void> setDisplayName(String value) async {
    displayName = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, displayName);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    // Update the switch right away. The save after this is just the phone storage.
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, value);
  }
}
