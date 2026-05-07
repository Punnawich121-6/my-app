import 'package:flutter/material.dart';
import '../main.dart';
import '../services/customer_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;
  const EditProfileScreen({super.key, required this.customerId, required this.customerName, required this.customerPhone});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customerName);
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _error = 'กรุณากรอกชื่อ'); return; }
    setState(() { _saving = true; _error = null; });
    final ok = await CustomerService.updateProfile(widget.customerId, name);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, name);
    } else {
      setState(() { _saving = false; _error = 'เกิดข้อผิดพลาด กรุณาลองใหม่'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: CColors.bg,
        elevation: 0,
        title: const Text('แก้ไขโปรไฟล์', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: CColors.text)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: CColors.text),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),
          // Avatar
          Stack(
            children: [
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: CColors.orange, size: 52),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Name field
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ชื่อ-นามสกุล', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 15, color: CColors.text),
              decoration: InputDecoration(
                hintText: 'กรอกชื่อของคุณ',
                hintStyle: const TextStyle(color: CColors.muted),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CColors.orange, width: 1.5)),
                errorText: _error,
                prefixIcon: const Icon(Icons.person_outline_rounded, color: CColors.muted),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Phone (read-only)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('เบอร์โทร', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CColors.text)),
            const SizedBox(height: 8),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: widget.customerPhone),
              style: const TextStyle(fontSize: 15, color: CColors.muted),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.phone_outlined, color: CColors.muted),
                suffixIcon: const Icon(Icons.lock_outline_rounded, color: CColors.muted, size: 18),
              ),
            ),
            const SizedBox(height: 4),
            const Text('เบอร์โทรไม่สามารถเปลี่ยนได้', style: TextStyle(fontSize: 11, color: CColors.muted)),
          ]),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: CColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('บันทึก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
