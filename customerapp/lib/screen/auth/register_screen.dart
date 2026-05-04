import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/customer_service.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String phone;
  const RegisterScreen({super.key, required this.phone});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อ-นามสกุล')));
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await CustomerService.register(phone: widget.phone, name: name);
      if (!mounted) return;
      if (result != null) {
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => HomeScreen(customerId: (result['user_id'] as num).toInt(), customerName: name, customerPhone: widget.phone)),
          (r) => false,
        );
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สมัครไม่สำเร็จ กรุณาลองใหม่')));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: CColors.text)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.person_add_rounded, color: CColors.orange, size: 28),
            ),
            const SizedBox(height: 20),
            const Text('สมัครสมาชิก', style: CTextStyles.brand),
            const SizedBox(height: 8),
            Text('เบอร์โทร: ${widget.phone}', style: CTextStyles.subtitle),
            const SizedBox(height: 32),
            const Text('ชื่อ-นามสกุล', style: CTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 15, color: CColors.text),
              decoration: InputDecoration(
                hintText: 'ชื่อจริง นามสกุล',
                hintStyle: const TextStyle(color: CColors.muted),
                filled: true, fillColor: CColors.orangeLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CColors.orange, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: CColors.orange, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('เริ่มสั่งอาหาร', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
