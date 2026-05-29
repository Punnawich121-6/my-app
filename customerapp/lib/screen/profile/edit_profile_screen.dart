import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../services/customer_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? profileImage;
  const EditProfileScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.profileImage,
  });
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  String? _error;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customerName);
    _base64Image = widget.profileImage;
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: CColors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: CColors.muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          _SourceTile(icon: Icons.photo_library_rounded, label: 'เลือกจากคลังรูป', onTap: () { Navigator.pop(context); _doPickImage(ImageSource.gallery); }),
          const SizedBox(height: 10),
          _SourceTile(icon: Icons.camera_alt_rounded, label: 'ถ่ายรูป', onTap: () { Navigator.pop(context); _doPickImage(ImageSource.camera); }),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  Future<void> _doPickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 600);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    final mime = file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    setState(() => _base64Image = 'data:$mime;base64,${base64Encode(bytes)}');
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _error = 'กรุณากรอกชื่อ'); return; }
    setState(() { _saving = true; _error = null; });
    final ok = await CustomerService.updateProfile(
      widget.customerId, name, profileImage: _base64Image,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, {'name': name, 'profileImage': _base64Image});
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
          GestureDetector(
            onTap: _pickImage,
            child: Stack(children: [
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: CColors.orangeLight),
                clipBehavior: Clip.antiAlias,
                child: _base64Image != null && _base64Image!.startsWith('data:')
                    ? Image.memory(base64Decode(_base64Image!.split(',').last), fit: BoxFit.cover)
                    : const Icon(Icons.person_rounded, color: CColors.orange, size: 52),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          const Text('แตะเพื่อเปลี่ยนรูป', style: TextStyle(fontSize: 12, color: CColors.muted)),
          const SizedBox(height: 24),

          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ชื่อ-นามสกุล', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 15, color: CColors.text),
              decoration: InputDecoration(
                hintText: 'กรอกชื่อของคุณ',
                hintStyle: const TextStyle(color: CColors.muted),
                filled: true, fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CColors.orange, width: 1.5)),
                errorText: _error,
                prefixIcon: const Icon(Icons.person_rounded, color: CColors.muted),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('เบอร์โทร', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CColors.text)),
            const SizedBox(height: 8),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: widget.customerPhone),
              style: const TextStyle(fontSize: 15, color: CColors.muted),
              decoration: InputDecoration(
                filled: true, fillColor: const Color(0xFFF0F0F0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.phone_rounded, color: CColors.muted),
                suffixIcon: const Icon(Icons.lock_rounded, color: CColors.muted, size: 18),
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
                backgroundColor: CColors.orange, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: CColors.orange, size: 22),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CColors.text)),
        ]),
      ),
    );
  }
}
