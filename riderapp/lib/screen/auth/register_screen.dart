import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/rider_service.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String phone;
  const RegisterScreen({super.key, required this.phone});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อ-นามสกุล')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await RiderService.register(phone: widget.phone, name: name);
      if (!mounted) return;
      if (result != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(riderId: result['user_id'], riderName: name),
          ),
          (r) => false,
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครไม่สำเร็จ กรุณาลองใหม่')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่')),
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
              child: const Icon(Icons.delivery_dining, color: RiderColors.blue, size: 28),
            ),
            const SizedBox(height: 20),
            const Text('สมัครเป็นไรเดอร์', style: RiderTextStyles.brand),
            const SizedBox(height: 8),
            Text(
              'เบอร์โทร: ${widget.phone}',
              style: RiderTextStyles.subtitle,
            ),
            const SizedBox(height: 32),
            const Text('ชื่อ-นามสกุล', style: RiderTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 15, color: RiderColors.text),
              decoration: InputDecoration(
                hintText: 'ชื่อจริง นามสกุล',
                hintStyle: const TextStyle(color: RiderColors.muted),
                filled: true,
                fillColor: RiderColors.blueLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: RiderColors.blue, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RiderColors.blueLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: RiderColors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'บัญชีของคุณจะถูกตรวจสอบโดยทีมงานก่อนเริ่มรับงาน',
                      style: TextStyle(fontSize: 13, color: RiderColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RiderColors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('สมัครสมาชิก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
