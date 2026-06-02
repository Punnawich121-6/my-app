import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_settings.dart';
import 'firebase_options.dart';
import 'screen/auth/login_screen.dart';
import 'services/order_notification_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    final host = kIsWeb ? 'localhost' : '10.0.2.2';
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  }

  // Suppress image loading errors (broken URLs, 404s) from crashing the app on web
  FlutterError.onError = (FlutterErrorDetails details) {
    final lib = details.library ?? '';
    if (lib.contains('image') || lib.contains('painting')) return;
    FlutterError.presentError(details);
  };

  OrderNotificationService.instance.navigatorKey = _navigatorKey;
  runApp(const CustomerApp());
}

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key});
  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Delivery',
      navigatorKey: _navigatorKey,
      themeMode: AppSettings.instance.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      builder: (context, child) {
        return Container(
          color: AppSettings.instance.isDark
              ? const Color(0xFF0D0D0D)
              : const Color(0xFFD0D0D0),
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

// ─── Themes ───────────────────────────────────────────────────────────────────

abstract class AppTheme {
  static ThemeData get light => _build(false);
  static ThemeData get dark  => _build(true);

  static ThemeData _build(bool dark) {
    final brightness = dark ? Brightness.dark : Brightness.light;
    final bg        = dark ? const Color(0xFF141414) : const Color(0xFFFFF8F5);
    final card      = dark ? const Color(0xFF222222) : Colors.white;
    final fg        = dark ? const Color(0xFFF0F0F0) : const Color(0xFF1E1B18);
    final muted     = dark ? const Color(0xFFCCCCCC) : const Color(0xFF333333);
    final divider   = dark ? const Color(0xFF2E2E2E) : const Color(0xFFF0F0F0);
    final subtleBg  = dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: divider,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CColors.orange,
        brightness: brightness,
        primary: CColors.orange,
        secondary: CColors.orange,
        surface: card,
        onSurface: fg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: fg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.notoSansThai(
          fontSize: 17, fontWeight: FontWeight.w700, color: fg),
      ),
      textTheme: GoogleFonts.notoSansThaiTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).apply(bodyColor: fg, displayColor: fg),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF2A2A2A) : CColors.orangeLight,
        hintStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? CColors.orange : null),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? CColors.orange.withValues(alpha: 0.4)
                : null),
      ),
      extensions: [
        _AppColorExtension(
          bg: bg, card: card, fg: fg,
          muted: muted, divider: divider, subtleBg: subtleBg,
          orangeLight: dark ? const Color(0xFF3A2010) : CColors.orangeLight,
        ),
      ],
    );
  }
}

// ─── Theme extension ──────────────────────────────────────────────────────────

class _AppColorExtension extends ThemeExtension<_AppColorExtension> {
  final Color bg, card, fg, muted, divider, subtleBg, orangeLight;
  const _AppColorExtension({
    required this.bg, required this.card, required this.fg,
    required this.muted, required this.divider, required this.subtleBg,
    required this.orangeLight,
  });
  @override
  _AppColorExtension copyWith({
    Color? bg, Color? card, Color? fg, Color? muted,
    Color? divider, Color? subtleBg, Color? orangeLight,
  }) => _AppColorExtension(
    bg: bg ?? this.bg, card: card ?? this.card, fg: fg ?? this.fg,
    muted: muted ?? this.muted, divider: divider ?? this.divider,
    subtleBg: subtleBg ?? this.subtleBg, orangeLight: orangeLight ?? this.orangeLight,
  );
  @override
  _AppColorExtension lerp(_AppColorExtension? other, double t) => this;
}

// ─── BuildContext helpers ─────────────────────────────────────────────────────

extension AppThemeX on BuildContext {
  _AppColorExtension get _ext =>
      Theme.of(this).extension<_AppColorExtension>()!;

  bool   get isDark      => Theme.of(this).brightness == Brightness.dark;
  Color  get bg          => _ext.bg;
  Color  get card        => _ext.card;
  Color  get fg          => _ext.fg;
  Color  get muted       => _ext.muted;
  Color  get divider     => _ext.divider;
  Color  get subtleBg    => _ext.subtleBg;
  Color  get orangeLight => _ext.orangeLight;
}

// ─── Color palette ────────────────────────────────────────────────────────────

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
