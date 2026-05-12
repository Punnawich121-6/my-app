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
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _requestOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('กรุณากรอกเบอร์โทรให้ถูกต้อง'),
          backgroundColor: RiderColors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => OtpScreen(phone: phone),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderColors.blue,
      body: Stack(
        children: [
          Positioned.fill(child: _RiderBg()),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: _FormSheet(
                phoneController: _phoneController,
                onRequestOtp: _requestOtp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderBg extends StatelessWidget {
  static const _bgImage =
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900&h=1200&fit=crop&q=80';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _bgImage,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => Container(color: RiderColors.blue),
        ),
        Container(color: Colors.black.withValues(alpha: 0.30)),
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
                child: const Icon(Icons.delivery_dining, size: 46, color: RiderColors.blue),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rider Partner',
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
                'รับงานส่งอาหารได้ทุกที่',
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
  const _FormSheet({required this.phoneController, required this.onRequestOtp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.only(
        left: 28, right: 28,
        top: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
              onPressed: onRequestOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderColors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
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
                      backgroundColor: RiderColors.blue,
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
                      text: 'สมัครเป็นไรเดอร์',
                      style: TextStyle(
                        color: RiderColors.blue,
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
    );
  }
}
