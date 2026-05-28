import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../services/customer_service.dart';

class DisputeScreen extends StatefulWidget {
  final String orderId;
  final String customerId;
  final String orderNumber;

  const DisputeScreen({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.orderNumber,
  });

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  String? _selectedReason;
  final _descCtrl = TextEditingController();
  final List<File> _photos = [];
  bool _submitting = false;
  bool _done = false;

  static const _reasons = [
    {'key': 'not_received',  'label': 'ไม่ได้รับอาหาร',        'icon': Icons.do_not_disturb_on_rounded},
    {'key': 'wrong_item',    'label': 'ได้รับอาหารผิดรายการ',  'icon': Icons.swap_horiz_rounded},
    {'key': 'late_delivery', 'label': 'อาหารส่งช้ามาก',         'icon': Icons.timer_off_rounded},
    {'key': 'quality_issue', 'label': 'คุณภาพอาหารไม่ตรงมาตรฐาน', 'icon': Icons.sentiment_dissatisfied_rounded},
    {'key': 'overcharged',   'label': 'ถูกเรียกเก็บเงินผิด',   'icon': Icons.payments_rounded},
    {'key': 'other',         'label': 'ปัญหาอื่นๆ',             'icon': Icons.help_rounded},
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 3) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _photos.add(File(picked.path)));
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกประเภทปัญหาก่อน')),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await CustomerService.submitDispute(
      orderId:    widget.orderId,
      customerId: widget.customerId,
      reasonType: _selectedReason!,
      description: _descCtrl.text.trim(),
      photos:     _photos,
    );
    if (!mounted) return;
    setState(() { _submitting = false; _done = ok; });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งคำร้องไม่สำเร็จ กรุณาลองใหม่')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: CColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: Colors.black12,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('แจ้งปัญหา', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CColors.text)),
          Text('ออเดอร์ ${widget.orderNumber}', style: const TextStyle(fontSize: 11, color: CColors.muted, fontWeight: FontWeight.w500)),
        ]),
      ),
      body: _done ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF43A047), size: 44),
          ),
          const SizedBox(height: 20),
          const Text('ส่งคำร้องสำเร็จ!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: CColors.text)),
          const SizedBox(height: 10),
          const Text(
            'AI กำลังวิเคราะห์หลักฐานของคุณ\nจะได้รับการแจ้งผลภายใน 30 วินาที',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: CColors.muted, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: CColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('กลับหน้าออเดอร์', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CColors.orangeLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CColors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.smart_toy_rounded, color: CColors.orange, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'AI จะวิเคราะห์คำร้องอัตโนมัติและแจ้งผลภายใน 30 วินาที — confidence สูง AI แก้ให้เลย, ต่ำกว่านั้น admin ตรวจสอบเพิ่มเติม',
                style: TextStyle(fontSize: 12, color: CColors.orange, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Reason selector
        const Text('ประเภทปัญหา *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CColors.text, letterSpacing: 0.2)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: _reasons.map((r) {
            final key   = r['key'] as String;
            final label = r['label'] as String;
            final icon  = r['icon'] as IconData;
            final sel   = _selectedReason == key;
            return GestureDetector(
              onTap: () => setState(() => _selectedReason = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? CColors.orange : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? CColors.orange : const Color(0xFFEEEEEE),
                    width: sel ? 2 : 1,
                  ),
                  boxShadow: sel
                      ? [BoxShadow(color: CColors.orange.withValues(alpha: 0.25), blurRadius: 8)]
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                ),
                child: Row(children: [
                  Icon(icon, size: 18, color: sel ? Colors.white : CColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : CColors.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Description
        const Text('อธิบายเพิ่มเติม (ไม่บังคับ)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CColors.text, letterSpacing: 0.2)),
        const SizedBox(height: 10),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          maxLength: 300,
          style: const TextStyle(fontSize: 14, color: CColors.text),
          decoration: InputDecoration(
            hintText: 'เช่น ไรเดอร์โทรหาแล้วไม่รับสาย อาหารมาไม่ครบ...',
            hintStyle: const TextStyle(fontSize: 13, color: CColors.muted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CColors.orange, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Photo evidence
        Row(children: [
          const Text('แนบรูปหลักฐาน',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CColors.text, letterSpacing: 0.2)),
          const SizedBox(width: 6),
          Text('(${_photos.length}/3)',
              style: const TextStyle(fontSize: 12, color: CColors.muted)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          // Add photo button
          if (_photos.length < 3)
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE), style: BorderStyle.solid),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.add_a_photo_rounded, color: CColors.orange, size: 26),
                  SizedBox(height: 4),
                  Text('เพิ่มรูป', style: TextStyle(fontSize: 12, color: CColors.muted, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          if (_photos.isNotEmpty) const SizedBox(width: 10),
          // Photo thumbnails
          ..._photos.asMap().entries.map((e) {
            final i = e.key;
            final file = e.value;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(file, width: 76, height: 76, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _photos.removeAt(i)),
                    child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
                    ),
                  ),
                ),
              ]),
            );
          }),
        ]),
        const SizedBox(height: 32),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _submitting ? 'กำลังส่งคำร้อง...' : 'ส่งคำร้องแจ้งปัญหา',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: CColors.orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: CColors.orange.withValues(alpha: 0.6),
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
