import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/customer_service.dart';
import '../home_screen.dart';
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

  @override
  void dispose() { _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _requestOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกเบอร์โทรให้ถูกต้อง')));
      return;
    }
    setState(() => _loading = true);
    final fullPhone = '+66${phone.startsWith('0') ? phone.substring(1) : phone}';
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
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ส่ง OTP ไม่สำเร็จ: ${e.message}')));
      },
      codeSent: (verificationId, _) {
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OtpScreen(phone: phone, verificationId: verificationId),
        ));
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _navigateAfterLogin(String phone) async {
    final user = await CustomerService.getByPhone(phone);
    if (!mounted) return;
    if (user == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RegisterScreen(phone: phone)));
    } else {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => HomeScreen(customerId: (user['id'] as num).toInt(), customerName: user['name'] ?? '', customerPhone: phone)),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(24)),
                  child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 44),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Zest & Savory', style: CTextStyles.brand),
              const SizedBox(height: 6),
              const Text('สั่งอาหารอร่อย ส่งถึงบ้าน', style: CTextStyles.subtitle),
              const SizedBox(height: 36),
              const Text('เบอร์โทรศัพท์', style: CTextStyles.label),
              const SizedBox(height: 8),
              _PhoneField(controller: _phoneCtrl),
              const SizedBox(height: 28),
              _PrimaryButton(label: 'รับ OTP', isLoading: _loading, onTap: _requestOtp),
              const SizedBox(height: 24),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: CTextStyles.muted,
                    children: [
                      const TextSpan(text: 'ยังไม่มีบัญชี? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            if (_phoneCtrl.text.length < 9) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกเบอร์โทรให้ถูกต้อง')));
                              return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen(phone: _phoneCtrl.text)));
                          },
                          child: const Text('สมัครสมาชิก', style: TextStyle(color: CColors.orange, fontWeight: FontWeight.w600, fontSize: 14)),
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

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: const TextStyle(fontSize: 15, color: CColors.text),
      decoration: InputDecoration(
        hintText: '08x-xxx-xxxx',
        hintStyle: const TextStyle(color: CColors.muted),
        filled: true,
        fillColor: CColors.orangeLight,
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          margin: const EdgeInsets.only(right: 8),
          decoration: const BoxDecoration(border: Border(right: BorderSide(color: CColors.orangeMid, width: 1))),
          child: const Text('+66', style: TextStyle(fontSize: 14, color: CColors.muted)),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.transparent)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CColors.orange, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.isLoading, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(backgroundColor: CColors.orange, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
