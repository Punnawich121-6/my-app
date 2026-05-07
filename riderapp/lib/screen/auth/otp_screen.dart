import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../services/rider_service.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  final ConfirmationResult? confirmationResult;
  const OtpScreen({super.key, required this.phone, required this.verificationId, this.confirmationResult});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  late String _verificationId;
  int _secondsLeft = 120;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startTimer();
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
    setState(() => _secondsLeft = 120);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
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
    setState(() {});
    if (_otp.length == 6) _verify();
  }

  Future<void> _verify() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);
    try {
      if (widget.confirmationResult != null) {
        await widget.confirmationResult!.confirm(_otp);
      } else {
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: _otp,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (!mounted) return;

      final rider = await RiderService.getByPhone(widget.phone);
      if (!mounted) return;
      if (rider == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RegisterScreen(phone: widget.phone)),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(riderId: rider['id'], riderName: rider['name'])),
          (r) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          e.code == 'invalid-verification-code' ? 'รหัส OTP ไม่ถูกต้อง' : 'เกิดข้อผิดพลาด: ${e.message}',
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: RiderColors.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: RiderColors.blueLight, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.phone_android_outlined, color: RiderColors.blue, size: 28),
            ),
            const SizedBox(height: 20),
            const Text('ยืนยัน OTP', style: RiderTextStyles.brand),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: RiderTextStyles.subtitle,
                children: [
                  const TextSpan(text: 'ส่งรหัส 6 หลักไปยัง\n'),
                  TextSpan(
                    text: '+66 ${widget.phone}',
                    style: const TextStyle(color: RiderColors.text, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _OtpBox(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                onChanged: (v) => _onDigitChanged(i, v),
              )),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: RiderColors.blueLight, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: RiderColors.blue, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('รหัสหมดอายุใน', style: TextStyle(fontSize: 12, color: RiderColors.muted)),
                      Text(_timerDisplay, style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: RiderColors.blue,
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: (_otp.length == 6 && !_isVerifying) ? _verify : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RiderColors.blue,
                  disabledBackgroundColor: RiderColors.blueMid,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isVerifying
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ยืนยัน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('เปลี่ยนเบอร์โทรศัพท์',
                    style: TextStyle(fontSize: 14, color: RiderColors.blue)),
              ),
            ),
          ],
        ),
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
        controller: controller,
        focusNode: focusNode,
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: RiderColors.text),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: controller.text.isNotEmpty ? RiderColors.blueLight : RiderColors.bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: RiderColors.blueMid)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: controller.text.isNotEmpty ? RiderColors.blue : RiderColors.blueMid)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: RiderColors.blue, width: 2)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
