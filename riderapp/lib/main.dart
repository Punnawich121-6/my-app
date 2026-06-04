import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_settings.dart';
import 'firebase_options.dart';
import 'screen/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await RiderSettings.instance.load();
  if (kDebugMode) {
    final host = kIsWeb ? 'localhost' : '10.0.2.2';
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  }
  runApp(const RiderApp());
}

class RiderApp extends StatefulWidget {
  const RiderApp({super.key});
  @override
  State<RiderApp> createState() => _RiderAppState();
}

class _RiderAppState extends State<RiderApp> {
  @override
  void initState() {
    super.initState();
    RiderSettings.instance.addListener(_onSettings);
  }

  @override
  void dispose() {
    RiderSettings.instance.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() { if (mounted) setState(() {}); }

  ThemeData _buildTheme(bool dark) {
    final base = dark ? ThemeData.dark() : ThemeData.light();
    final bg   = dark ? const Color(0xFF0D0D0D) : RiderColors.bg;
    final card = dark ? const Color(0xFF1C1C1C) : Colors.white;
    final fg   = dark ? const Color(0xFFF0F0F0) : RiderColors.text;
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      cardColor: card,
      textTheme: GoogleFonts.notoSansThaiTextTheme(base.textTheme).apply(bodyColor: fg, displayColor: fg),
      colorScheme: ColorScheme.fromSeed(
        seedColor: RiderColors.blue,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: RiderColors.blue,
        surface: card,
        onSurface: fg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: fg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: dark ? const Color(0xFF2D2D2D) : const Color(0xFFEEEEEE),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = RiderSettings.instance.isDark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zest & Savory Rider',
      themeMode: RiderSettings.instance.themeMode,
      theme: _buildTheme(false),
      darkTheme: _buildTheme(true),
      builder: (context, child) {
        return Container(
          color: dark ? const Color(0xFF000000) : const Color(0xFFD0D0D0),
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
