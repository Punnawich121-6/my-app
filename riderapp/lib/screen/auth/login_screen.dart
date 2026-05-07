import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/rider_service.dart';
import '../home_screen.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกเบอร์โทรให้ถูกต้อง')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final fullPhone = '+66${phone.startsWith('0') ? phone.substring(1) : phone}';

    if (kIsWeb) {
      try {
        final confirmation = await FirebaseAuth.instance.signInWithPhoneNumber(fullPhone);
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OtpScreen(phone: phone, verificationId: '', confirmationResult: confirmation),
        ));
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ส่ง OTP ไม่สำเร็จ: $e')));
      }
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (!mounted) return;
        _navigateAfterLogin(phone);
      },
      verificationFailed: (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่ง OTP ไม่สำเร็จ: ${e.message}')),
        );
      },
      codeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(phone: phone, verificationId: verificationId),
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _navigateAfterLogin(String phone) async {
    final rider = await RiderService.getByPhone(phone);
    if (!mounted) return;
    if (rider == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RegisterScreen(phone: phone)),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(riderId: rider['id'], riderName: rider['name'])),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: RiderColors.blueLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.delivery_dining, color: RiderColors.blue, size: 44),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Rider Partner', style: RiderTextStyles.brand),
              const SizedBox(height: 6),
              const Text(
                'เข้าสู่ระบบสำหรับไรเดอร์\nZest & Savory',
                style: RiderTextStyles.subtitle,
              ),
              const SizedBox(height: 36),
              const Text('เบอร์โทรศัพท์', style: RiderTextStyles.label),
              const SizedBox(height: 8),
              _PhoneField(controller: _phoneController),
              const SizedBox(height: 28),
              _PrimaryButton(label: 'รับ OTP', isLoading: _isLoading, onTap: _requestOtp),
              const SizedBox(height: 24),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: RiderTextStyles.muted,
                    children: [
                      const TextSpan(text: 'ยังไม่มีบัญชี? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            if (_phoneController.text.length < 9) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('กรุณากรอกเบอร์โทรให้ถูกต้อง')),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RegisterScreen(phone: _phoneController.text),
                              ),
                            );
                          },
                          child: const Text(
                            'สมัครเป็นไรเดอร์',
                            style: TextStyle(
                              color: RiderColors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Phone Field ──────────────────────────────────────────────────────────────

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: const TextStyle(fontSize: 15, color: RiderColors.text),
      decoration: InputDecoration(
        hintText: '08x-xxx-xxxx',
        hintStyle: const TextStyle(color: RiderColors.muted),
        filled: true,
        fillColor: RiderColors.blueLight,
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          margin: const EdgeInsets.only(right: 8),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: RiderColors.blueMid, width: 1)),
          ),
          child: const Text('+66', style: TextStyle(fontSize: 14, color: RiderColors.muted)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: RiderColors.blue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: RiderColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
