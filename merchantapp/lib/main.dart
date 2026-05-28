import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_settings.dart';
import 'firebase_options.dart';
import 'screen/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () { if (mounted) setState(() {}); };
    AppSettings.instance.addListener(_listener);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_listener);
    super.dispose();
  }

  static ThemeData _buildTheme(bool dark) {
    final bg   = dark ? const Color(0xFF141414) : Colors.white;
    final card = dark ? const Color(0xFF222222) : Colors.white;
    final fg   = dark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    return ThemeData(
      textTheme: GoogleFonts.notoSansThaiTextTheme(
        ThemeData(brightness: dark ? Brightness.dark : Brightness.light).textTheme,
      ),
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: dark ? const Color(0xFF141414) : const Color(0xFFF4F4F4),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        primary: AppColors.orange,
        secondary: AppColors.orange,
        brightness: dark ? Brightness.dark : Brightness.light,
        surface: card,
        onSurface: fg,
      ),
      cardColor: card,
      appBarTheme: AppBarTheme(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.orange),
      extensions: [MerchantTheme(bg: bg, card: card, fg: fg)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings.instance.isDark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zest & Savory Merchant',
      themeMode: AppSettings.instance.themeMode,
      theme: _buildTheme(false),
      darkTheme: _buildTheme(true),
      builder: (context, child) {
        return Container(
          color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFD0D0D0),
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

class MerchantTheme extends ThemeExtension<MerchantTheme> {
  final Color bg, card, fg;
  const MerchantTheme({required this.bg, required this.card, required this.fg});

  @override
  MerchantTheme copyWith({Color? bg, Color? card, Color? fg}) =>
      MerchantTheme(bg: bg ?? this.bg, card: card ?? this.card, fg: fg ?? this.fg);

  @override
  MerchantTheme lerp(MerchantTheme? other, double t) {
    if (other == null) return this;
    return MerchantTheme(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
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
  static const muted       = Color(0xFF333333);
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
