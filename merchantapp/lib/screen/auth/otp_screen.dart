import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../main.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../merchant/home/merchant_main_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  final String? autoCode;
  const OtpScreen({super.key, required this.phone, required this.verificationId, this.autoCode});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsLeft = 120;
  Timer? _timer;
  bool _isVerifying = false;
  late String _verificationId;
  String? _suggestedCode;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startTimer();
    if (widget.autoCode != null && widget.autoCode!.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _suggestedCode = widget.autoCode);
      });
    } else if (kDebugMode) {
      Future.delayed(const Duration(milliseconds: 800), _fetchEmulatorCode);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (mounted) setState(() => _secondsLeft = 120);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_secondsLeft == 0) { t.cancel(); } else { setState(() => _secondsLeft--); }
    });
  }

  String get _timerDisplay {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
    if (!mounted) return;
    setState(() {});
    if (_otp.length == 6) _verify();
  }

  Future<void> _animatedFill(String code) async {
    setState(() => _suggestedCode = null);
    for (int i = 0; i < 6; i++) {
      if (!mounted) return;
      _controllers[i].text = code[i];
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 80));
    }
    if (mounted) _verify();
  }

  Future<void> _fetchEmulatorCode() async {
    try {
      final emulatorHost = kIsWeb ? 'localhost' : '10.0.2.2';
      final res = await http.get(Uri.parse(
        'http://$emulatorHost:9099/emulator/v1/projects/project-digit-3cea5/verificationCodes',
      ));
      if (res.statusCode != 200 || !mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final codes = data['verificationCodes'] as List?;
      if (codes == null || codes.isEmpty) return;
      final suffix = widget.phone.startsWith('0') ? widget.phone.substring(1) : widget.phone;
      final thaiPhone = '+66$suffix';
      final match = codes.lastWhere(
        (c) => c['phoneNumber'] == thaiPhone,
        orElse: () => null,
      );
      final code = match?['code'] as String?;
      if (code != null && code.length == 6 && mounted) {
        setState(() => _suggestedCode = code);
      }
    } catch (_) {}
  }

  Future<void> _resendOtp() async {
    _startTimer();
    setState(() => _suggestedCode = null);
    final suffix = widget.phone.startsWith('0') ? widget.phone.substring(1) : widget.phone;
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+66$suffix',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        if (credential.smsCode != null && mounted) {
          setState(() => _suggestedCode = credential.smsCode);
        }
      },
      verificationFailed: (_) {},
      codeSent: (String verificationId, int? _) {
        if (mounted) {
          setState(() => _verificationId = verificationId);
          if (kDebugMode) {
            Future.delayed(const Duration(milliseconds: 800), _fetchEmulatorCode);
          }
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verify() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
      final msg = e.code == 'session-expired'
          ? 'รหัส OTP หมดอายุแล้ว กรุณาขอใหม่'
          : 'รหัส OTP ไม่ถูกต้อง กรุณาลองใหม่';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่')),
      );
      return;
    }

    final store = await ApiService.getStoreByPhone(widget.phone);
    if (!mounted) return;

    if (store == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RegisterScreen(phone: widget.phone)),
      );
      return;
    }

    final status = (store['status'] as String? ?? '').toLowerCase();
    if (status != 'active') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RegisterScreen(phone: widget.phone)),
      );
      return;
    }
    ApiService.storeId   = store['id'].toString();
    ApiService.storeName = store['name']?.toString() ?? 'ร้านค้า';
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MerchantMainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.phone_android_outlined, color: AppColors.orange, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('ยืนยัน OTP', style: AppTextStyles.brand),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(style: AppTextStyles.subtitle, children: [
                      const TextSpan(text: 'ส่งรหัส 6 หลักไปยัง\n'),
                      TextSpan(text: '+66 ${widget.phone}', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 15)),
                    ]),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) => _OtpBox(
                      controller: _controllers[i], focusNode: _focusNodes[i],
                      onChanged: (v) => _onDigitChanged(i, v),
                    )),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.timer_outlined, color: AppColors.orange, size: 20),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('รหัสหมดอายุใน', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        Text(_timerDisplay, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.orange)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      onPressed: (_otp.length == 6 && !_isVerifying) ? _verify : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        disabledBackgroundColor: AppColors.orangeMid,
                        foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isVerifying
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('ยืนยัน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _secondsLeft == 0 ? _resendOtp : null,
                          child: Text('ไม่ได้รับรหัส? ส่งใหม่',
                            style: TextStyle(fontSize: 14, color: _secondsLeft == 0 ? AppColors.orange : AppColors.muted, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => Navigator.pushAndRemoveUntil(context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
                          child: const Text('เปลี่ยนเบอร์โทรศัพท์', style: TextStyle(fontSize: 14, color: AppColors.orange)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_suggestedCode != null)
            GestureDetector(
              onTap: () => _animatedFill(_suggestedCode!),
              child: Container(
                color: const Color(0xFFF2F2F2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.sms_outlined, size: 16, color: Color(0xFF888888)),
                    const SizedBox(width: 8),
                    const Text('จาก Firebase Emulator', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(20)),
                      child: Text(_suggestedCode!,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 3)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _OtpBox({required this.controller, required this.focusNode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46, height: 56,
      child: TextField(
        controller: controller, focusNode: focusNode,
        maxLength: 1, keyboardType: TextInputType.number, textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
        decoration: InputDecoration(
          counterText: '', filled: true,
          fillColor: controller.text.isNotEmpty ? AppColors.orangeLight : AppColors.bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orangeMid)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: controller.text.isNotEmpty ? AppColors.orange : AppColors.orangeMid)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.orange, width: 2)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
