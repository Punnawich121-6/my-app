import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screen/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: CColors.orange),
      ),
      home: const LoginScreen(),
    );
  }
}

abstract class CColors {
  static const orange      = Color(0xFFF5A623);   // warm amber orange
  static const orangeLight = Color(0xFFFFF8E1);   // very light amber
  static const orangeMid   = Color(0xFFFFE082);   // mid amber
  static const bg          = Color(0xFFFFFFFF);   // white
  static const text        = Color(0xFF1A1A1A);   // near black
  static const muted       = Color(0xFF9E9E9E);   // grey
  static const green       = Color(0xFF43A047);
  static const greenLight  = Color(0xFFE8F5E9);
  static const red         = Color(0xFFE53935);
  static const redLight    = Color(0xFFFFEBEE);
}

abstract class CTextStyles {
  static const brand    = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: CColors.orange, height: 1.1);
  static const subtitle = TextStyle(fontSize: 15, color: CColors.muted, height: 1.55);
  static const label    = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CColors.text);
  static const muted    = TextStyle(fontSize: 14, color: CColors.muted);
}
