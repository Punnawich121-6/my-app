import 'package:flutter/material.dart';

extension Responsive on BuildContext {
  static const double _base = 390.0; // iPhone 12 Pro base width

  double get _screenW => MediaQuery.sizeOf(this).width;

  // Size scale: clamp between 360 (S8+) and 430 (14 Pro Max)
  double get _s => (_screenW / _base).clamp(0.82, 1.22);

  // Font scale: dampened slightly so text doesn't grow too fast
  double get _fs => (_screenW / _base).clamp(0.85, 1.18);

  /// Scale a widget dimension (padding, icon size, border radius, etc.)
  double wp(double size) => size * _s;

  /// Scale a font size
  double sp(double size) => size * _fs;
}
