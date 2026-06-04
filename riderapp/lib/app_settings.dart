import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiderSettings extends ChangeNotifier {
  RiderSettings._();
  static final RiderSettings instance = RiderSettings._();

  ThemeMode _themeMode = ThemeMode.light;
  bool _isEnglish = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isEnglish => _isEnglish;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = (prefs.getBool('rider_dark') ?? false) ? ThemeMode.dark : ThemeMode.light;
    _isEnglish = prefs.getBool('rider_english') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rider_dark', isDark);
  }

  Future<void> setEnglish(bool v) async {
    if (_isEnglish == v) return;
    _isEnglish = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rider_english', v);
  }
}

/// Returns [th] in Thai mode, [en] in English mode.
String rt(String th, String en) => RiderSettings.instance.isEnglish ? en : th;
