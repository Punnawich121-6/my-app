import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  ThemeMode _themeMode = ThemeMode.light;
  bool _isEnglish = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isEnglish => _isEnglish;

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setEnglish(bool v) {
    if (_isEnglish == v) return;
    _isEnglish = v;
    notifyListeners();
  }
}
