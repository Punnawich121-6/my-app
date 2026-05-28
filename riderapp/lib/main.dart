import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screen/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
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
        textTheme: GoogleFonts.notoSansThaiTextTheme(ThemeData().textTheme),
        scaffoldBackgroundColor: RiderColors.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: RiderColors.blue),
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

// ─── Colors ───────────────────────────────────────────────────────────────────

abstract class RiderColors {
  static const blue      = Color(0xFFFF6B35);
  static const blueLight = Color(0xFFFFEDE7);
  static const blueMid   = Color(0xFFFFB59D);
  static const bg        = Color(0xFFFFFFFF);
  static const text      = Color(0xFF1A1A1A);
  static const muted     = Color(0xFF333333);
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
