import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  ThemeMode _themeMode = ThemeMode.light;
  bool _isEnglish = false;
  String _defaultPaymentMethod = 'Cash';

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isEnglish => _isEnglish;
  String get defaultPaymentMethod => _defaultPaymentMethod;

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setEnglish(bool v) {
    if (_isEnglish == v) return;
    _isEnglish = v;
    notifyListeners();
  }

  void setDefaultPaymentMethod(String method) {
    if (_defaultPaymentMethod == method) return;
    _defaultPaymentMethod = method;
    notifyListeners();
  }
}
