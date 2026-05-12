import 'package:flutter/material.dart';
import 'screen/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zest & Savory',
      theme: ThemeData(
        scaffoldBackgroundColor: CColors.bg,
        fontFamily: 'sans-serif',
        colorScheme: ColorScheme.fromSeed(
          seedColor: CColors.orange,
          primary: CColors.orange,
          surface: CColors.bg,
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

// Web-matching color palette (from globals.css)
abstract class CColors {
  static const orange      = Color(0xFFFF6B35);
  static const orangeLight = Color(0xFFFBF2ED);
  static const orangeMid   = Color(0xFFE1BFB5);
  static const bg          = Color(0xFFFFF8F5);
  static const text        = Color(0xFF1E1B18);
  static const muted       = Color(0xFF8D7168);
  static const green       = Color(0xFF00677E);
  static const greenLight  = Color(0xFFB5EBFF);
  static const red         = Color(0xFFBA1A1A);
  static const redLight    = Color(0xFFFFDAD6);
}

abstract class CTextStyles {
  static const brand    = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: CColors.orange, height: 1.1);
  static const subtitle = TextStyle(fontSize: 15, color: CColors.muted, height: 1.55);
  static const label    = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CColors.text);
  static const muted    = TextStyle(fontSize: 14, color: CColors.muted);
}
