import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../main.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  PhoneAuthCredential? _autoCredential;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _requestOtp() {
    if (_loading) return;
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('กรุณากรอกเบอร์โทรให้ถูกต้อง'),
          backgroundColor: CColors.orange,
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

    final thaiPhone = '+66' + (phone.startsWith('0') ? phone.substring(1) : phone);

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
          SnackBar(content: Text(e.message ?? 'ส่ง OTP ไม่สำเร็จ กรุณาลองใหม่')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.orange,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(child: _CustomerBg()),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _FormSheet(
              phoneController: _phoneCtrl,
              onRequestOtp: _requestOtp,
              loading: _loading,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerBg extends StatelessWidget {
  // รูปอาหารน่ากิน สื่อถึงแอปสั่งอาหาร
  static const _bgImage =
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=900&h=1200&fit=crop&q=80';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _bgImage,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, _, _) => Container(color: CColors.orange),
        ),
        Container(color: Colors.black.withValues(alpha: 0.25)),
        SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.restaurant_rounded, size: 46, color: CColors.orange),
              ),
              const SizedBox(height: 20),
              const Text(
                'Food Delivery',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                  shadows: [Shadow(color: Color(0x88000000), blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'สั่งอาหารอร่อย ส่งถึงบ้าน',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w400,
                  shadows: const [Shadow(color: Color(0x77000000), blurRadius: 8)],
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
  final bool loading;
  const _FormSheet({required this.phoneController, required this.onRequestOtp, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 28, right: 28,
          top: 32,
          bottom: safeBottom + 32,
        ),
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
            const SizedBox(height: 28),
            const Text(
              'เข้าสู่ระบบ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'กรอกเบอร์โทรศัพท์เพื่อรับ OTP',
              style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 28),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : onRequestOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CColors.orange,
                  disabledBackgroundColor: CColors.orangeMid,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'รับ OTP',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
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
                        content: const Text('กรุณากรอกเบอร์โทรก่อน'),
                        backgroundColor: CColors.orange,
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
                  text: const TextSpan(
                    style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                    children: [
                      TextSpan(text: 'ยังไม่มีบัญชี? '),
                      TextSpan(
                        text: 'สมัครสมาชิก',
                        style: TextStyle(
                          color: CColors.orange,
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
