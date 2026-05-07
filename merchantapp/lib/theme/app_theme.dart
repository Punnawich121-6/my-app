import 'package:flutter/material.dart';

// ─── Colors ─────────────────────────────────────────────────────────────────

abstract class AppColors {
  static const orange      = Color(0xFFF5A623);
  static const orangeLight = Color(0xFFFFF8E1);
  static const orangeMid   = Color(0xFFFFE082);
  static const bg          = Color(0xFFFFFFFF);
  static const text        = Color(0xFF1A1A1A);
  static const muted       = Color(0xFF9E9E9E);
  static const green       = Color(0xFF43A047);
  static const greenLight  = Color(0xFFE8F5E9);
  static const red         = Color(0xFFE53935);
  static const redLight    = Color(0xFFFFEBEE);
}

// ─── Text Styles ─────────────────────────────────────────────────────────────

abstract class AppTextStyles {
  static const brand = TextStyle(
    fontFamily: 'PlayfairDisplay', // add to pubspec.yaml
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.orange,
    height: 1.1,
  );

  static const subtitle = TextStyle(
    fontSize: 15,
    color: AppColors.muted,
    height: 1.55,
  );

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const muted = TextStyle(
    fontSize: 14,
    color: AppColors.muted,
  );
}