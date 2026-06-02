import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  ThemeMode _themeMode = ThemeMode.light;
  bool _isEnglish = false;
  String _defaultPaymentMethod = 'Cash';
  bool _pushNotif = true;
  bool _orderUpdates = true;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isEnglish => _isEnglish;
  String get defaultPaymentMethod => _defaultPaymentMethod;
  bool get pushNotif => _pushNotif;
  bool get orderUpdates => _orderUpdates;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = (prefs.getBool('darkMode') ?? false) ? ThemeMode.dark : ThemeMode.light;
    _isEnglish = prefs.getBool('isEnglish') ?? false;
    _defaultPaymentMethod = prefs.getString('paymentMethod') ?? 'Cash';
    _pushNotif = prefs.getBool('pushNotif') ?? true;
    _orderUpdates = prefs.getBool('orderUpdates') ?? true;
  }

  void toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDark);
    notifyListeners();
  }

  void setEnglish(bool v) async {
    if (_isEnglish == v) return;
    _isEnglish = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnglish', v);
    notifyListeners();
  }

  void setDefaultPaymentMethod(String method) async {
    if (_defaultPaymentMethod == method) return;
    _defaultPaymentMethod = method;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paymentMethod', method);
    notifyListeners();
  }

  void setPushNotif(bool v) async {
    if (_pushNotif == v) return;
    _pushNotif = v;
    if (!v) _orderUpdates = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotif', _pushNotif);
    await prefs.setBool('orderUpdates', _orderUpdates);
    notifyListeners();
  }

  void setOrderUpdates(bool v) async {
    if (_orderUpdates == v) return;
    _orderUpdates = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('orderUpdates', v);
    notifyListeners();
  }
}
