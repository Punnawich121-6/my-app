import 'package:flutter/material.dart';
import 'screen/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zest & Savory',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange,
          primary: AppColors.orange,
          secondary: AppColors.orange,
          brightness: Brightness.light,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.orange,
        ),
      ),
      builder: (context, child) {
        return Container(
          color: const Color(0xFFD0D0D0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: child!,
            ),
          ),
        );
      },
      home: const LoginScreen(),
    );
  }
}

// ─── Colors ──────────────────────────────────────────────────────────────────

abstract class AppColors {
  static const orange      = Color(0xFFFF6B35);
  static const orangeLight = Color(0xFFFFEDE7);
  static const orangeMid   = Color(0xFFFFB59D);
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
