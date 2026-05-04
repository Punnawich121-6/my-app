import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screen/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RiderApp());
}

class RiderApp extends StatelessWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zest & Savory Rider',
      theme: ThemeData(
        scaffoldBackgroundColor: RiderColors.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: RiderColors.blue),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}

// ─── Colors ───────────────────────────────────────────────────────────────────

abstract class RiderColors {
  static const blue      = Color(0xFFF5A623);   // warm amber orange
  static const blueLight = Color(0xFFFFF8E1);   // very light amber
  static const blueMid   = Color(0xFFFFE082);   // mid amber
  static const bg        = Color(0xFFFFFFFF);
  static const text      = Color(0xFF1A1A1A);
  static const muted     = Color(0xFF9E9E9E);
  static const green     = Color(0xFF43A047);
  static const greenLight= Color(0xFFE8F5E9);
  static const red       = Color(0xFFE53935);
  static const redLight  = Color(0xFFFFEBEE);
}

// ─── Text Styles ──────────────────────────────────────────────────────────────

abstract class RiderTextStyles {
  static const brand = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: RiderColors.blue,
    height: 1.1,
  );

  static const subtitle = TextStyle(
    fontSize: 15,
    color: RiderColors.muted,
    height: 1.55,
  );

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: RiderColors.text,
  );

  static const muted = TextStyle(
    fontSize: 14,
    color: RiderColors.muted,
  );
}
