import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../app_settings.dart';
import '../../l10n.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../merchant/home/merchant_main_screen.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

// OAuth clients from google-services.json / GoogleService-Info.plist (project-digit-3cea5)
const _googleWebClientId = '157517455877-j8j6h1163170jnl8m5rr98ktnn4ha6e0.apps.googleusercontent.com';
const _googleIosClientId = '157517455877-6t8vl8hhaj1uhntt7nll2opme3epj03j.apps.googleusercontent.com';

Future<void>? _googleInit;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  PhoneAuthCredential? _autoCredential;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onSettings);
  }

  void _onSettings() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _phoneController.dispose();
    super.dispose();
  }

  void _requestOtp() {
    if (_loading) return;
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('กรุณากรอกเบอร์โทรให้ถูกต้อง', 'Please enter a valid phone number')),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    _sendAndNavigate(phone);
  }

  Future<void> _sendAndNavigate(String phone) async {
    setState(() => _loading = true);

    if (kIsWeb) {
      setState(() => _loading = false);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OtpScreen(phone: phone, verificationId: 'web-bypass'),
      ));
      return;
    }

    final suffix = phone.startsWith('0') ? phone.substring(1) : phone;
    final thaiPhone = '+66$suffix';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: thaiPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        _autoCredential = credential;
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? t('ส่ง OTP ไม่สำเร็จ กรุณาลองใหม่', 'Failed to send OTP, please try again'))),
        );
      },
      codeSent: (String verificationId, int? _) {
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OtpScreen(phone: phone, verificationId: verificationId, autoCode: _autoCredential?.smsCode),
        ));
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _signOutGoogle() async {
    try {
      if (!kIsWeb) await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  Future<void> _signInWithGoogle() async {
    if (_loading || _googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      String? idToken;
      if (kIsWeb) {
        final cred = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
        idToken = (cred.credential as OAuthCredential?)?.idToken;
      } else {
        _googleInit ??= GoogleSignIn.instance.initialize(
          clientId: defaultTargetPlatform == TargetPlatform.iOS ? _googleIosClientId : null,
          serverClientId: _googleWebClientId,
        );
        await _googleInit;
        final account = await GoogleSignIn.instance.authenticate();
        idToken = account.authentication.idToken;
        if (idToken != null) {
          await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
        }
      }
      if (idToken == null) {
        throw Exception(t('ไม่ได้รับ token จาก Google', 'No token received from Google'));
      }

      final result = await ApiService.googleLogin(idToken);
      if (!mounted) return;
      final store = result['store'] as Map<String, dynamic>?;

      if (store == null) {
        await _signOutGoogle();
        if (!mounted) return;
        _showError(t(
          'ไม่พบร้านค้าที่ใช้อีเมล ${result['email']} กรุณาเข้าสู่ระบบด้วยเบอร์โทร หรือสมัครโดยใช้อีเมลนี้',
          'No store uses ${result['email']}. Sign in with your phone, or register with this email.',
        ));
        return;
      }

      final status = (store['status'] as String? ?? '').toLowerCase();
      if (status != 'active') {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => RegisterScreen(phone: store['phone']?.toString() ?? ''),
        ));
        return;
      }
      ApiService.storeId   = store['id'].toString();
      ApiService.storeName = store['name']?.toString() ?? 'ร้านค้า';
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MerchantMainScreen()),
        (route) => false,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      if (mounted) _showError(e.description ?? t('เข้าสู่ระบบด้วย Google ไม่สำเร็จ', 'Google sign-in failed'));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') return;
      if (mounted) _showError(e.message ?? t('เข้าสู่ระบบด้วย Google ไม่สำเร็จ', 'Google sign-in failed'));
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.orange,
      body: Stack(
        children: [
          // Orange background with pattern
          Positioned.fill(child: _OrangeBg()),
          // Bottom white sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: _FormSheet(
                phoneController: _phoneController,
                onRequestOtp: _requestOtp,
                onGoogleSignIn: _signInWithGoogle,
                loading: _loading,
                googleLoading: _googleLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrangeBg extends StatelessWidget {
  Widget _buildImage({double? height}) => Image.asset(
    'assets/images/food.jpg',
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    alignment: Alignment.center,
    errorBuilder: (ctx, err, st) => Image.network(
      'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=900&h=1200&fit=crop&q=80',
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (ctx2, err2, st2) => Container(color: AppColors.orange),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenH < 680;
    final logoSize = isSmall ? 64.0 : 80.0;
    final iconSize = isSmall ? 34.0 : 42.0;
    final titleSize = isSmall ? 20.0 : 24.0;
    final topPad = isSmall ? 10.0 : 20.0;
    final midPad = isSmall ? 10.0 : 14.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Orange fill for area below image
        Container(color: AppColors.orange),
        // Image constrained to 55% height — shows ~2× more horizontal content vs full-screen cover
        Positioned(
          top: 0, left: 0, right: 0,
          child: _buildImage(height: screenH * 0.55),
        ),
        // Gradient: darkens top (readability) → fades to orange below image
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.60),
                Colors.black.withValues(alpha: 0.50),
                Colors.black.withValues(alpha: 0.25),
                AppColors.orange.withValues(alpha: 0.92),
                AppColors.orange,
              ],
              stops: const [0.0, 0.25, 0.48, 0.68, 0.80],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: topPad),
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(Icons.storefront_rounded, size: iconSize, color: AppColors.orange),
              ),
              SizedBox(height: midPad),
              Text(
                'Merchant Partner',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                  shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 12)],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('จัดการร้านค้าของคุณได้ทุกที่', 'Manage your store anywhere'),
                style: TextStyle(
                  fontSize: isSmall ? 12.0 : 13.0,
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w400,
                  shadows: const [Shadow(color: Color(0x88000000), blurRadius: 8)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormSheet extends StatelessWidget {
  final TextEditingController phoneController;
  final VoidCallback onRequestOtp;
  final VoidCallback onGoogleSignIn;
  final bool loading;
  final bool googleLoading;
  const _FormSheet({
    required this.phoneController,
    required this.onRequestOtp,
    required this.onGoogleSignIn,
    this.loading = false,
    this.googleLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenH < 680;
    final hPad = isSmall ? 20.0 : 28.0;
    final vPad = isSmall ? 22.0 : 32.0;
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.only(
        left: hPad, right: hPad,
        top: vPad, bottom: MediaQuery.of(context).viewInsets.bottom + vPad,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          SizedBox(height: isSmall ? 16 : 28),
          Text(
            t('เข้าสู่ระบบ', 'Sign In'),
            style: TextStyle(fontSize: isSmall ? 20.0 : 24.0, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 6),
          Text(
            t('กรอกเบอร์โทรศัพท์เพื่อรับ OTP', 'Enter your phone number to receive OTP'),
            style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
          ),
          SizedBox(height: isSmall ? 16 : 28),
          // Phone field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFE8E8E8))),
                  ),
                  child: const Text(
                    '🇹🇭 +66',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      hintText: '08x-xxx-xxxx',
                      hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmall ? 16 : 24),
          // OTP Button
          SizedBox(
            width: double.infinity,
            height: isSmall ? 48 : 52,
            child: ElevatedButton(
              onPressed: (loading || googleLoading) ? null : onRequestOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                disabledBackgroundColor: AppColors.orangeMid,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      t('รับ OTP', 'Get OTP'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    ),
            ),
          ),
          SizedBox(height: isSmall ? 12 : 16),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE8E8E8))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(t('หรือ', 'or'), style: const TextStyle(fontSize: 13, color: Color(0xFFBDBDBD))),
              ),
              const Expanded(child: Divider(color: Color(0xFFE8E8E8))),
            ],
          ),
          SizedBox(height: isSmall ? 12 : 16),
          // Google Button
          SizedBox(
            width: double.infinity,
            height: isSmall ? 48 : 52,
            child: OutlinedButton(
              onPressed: (loading || googleLoading) ? null : onGoogleSignIn,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A1A1A),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: googleLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
                        const SizedBox(width: 10),
                        Text(
                          t('เข้าสู่ระบบด้วย Google', 'Continue with Google'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () {
                if (phoneController.text.length < 9) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('กรุณากรอกเบอร์โทรก่อน', 'Please enter a phone number first')),
                      backgroundColor: AppColors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  return;
                }
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RegisterScreen(phone: phoneController.text),
                ));
              },
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                  children: [
                    TextSpan(text: t('ยังไม่มีบัญชี? ', "Don't have an account? ")),
                    TextSpan(
                      text: t('สมัครสมาชิก', 'Register'),
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
