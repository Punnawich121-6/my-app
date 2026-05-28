import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../services/rider_service.dart';

class RiderReportScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final String riderId;

  const RiderReportScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.riderId,
  });

  @override
  State<RiderReportScreen> createState() => _RiderReportScreenState();
}

class _RiderReportScreenState extends State<RiderReportScreen> {
  String? _selectedReason;
  final _descCtrl = TextEditingController();
  final List<File> _photos = [];
  bool _submitting = false;
  bool _done = false;

  static const _reasons = [
    {'key': 'customer_not_answering', 'label': 'ลูกค้าไม่รับสาย/ไม่รับของ', 'icon': Icons.phone_missed_rounded},
    {'key': 'wrong_address',          'label': 'ที่อยู่ผิด/หาไม่เจอ',        'icon': Icons.location_off_rounded},
    {'key': 'unfair_rating',          'label': 'โดนรีวิวไม่เป็นธรรม',         'icon': Icons.star_border_rounded},
    {'key': 'customer_refused',       'label': 'ลูกค้าปฏิเสธรับออเดอร์',     'icon': Icons.cancel_rounded},
    {'key': 'dangerous_area',         'label': 'พื้นที่ไม่ปลอดภัย',           'icon': Icons.warning_rounded},
    {'key': 'other',                  'label': 'ปัญหาอื่นๆ',                   'icon': Icons.help_outline_rounded},
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 3) return;
    final picked = await ImagePicker().pickImage(
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
    final ok = await RiderService.submitRiderReport(
      orderId:     widget.orderId,
      riderId:     widget.riderId,
      reasonType:  _selectedReason!,
      description: _descCtrl.text.trim(),
      photos:      _photos,
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
      backgroundColor: RiderColors.bg,
      appBar: AppBar(
        backgroundColor: RiderColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B35),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('แจ้งปัญหา', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('ออเดอร์ ${widget.orderNumber}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white)),
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
            decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: RiderColors.blue, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('ส่งคำร้องสำเร็จ!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: RiderColors.text)),
          const SizedBox(height: 10),
          const Text(
            'AI กำลังวิเคราะห์หลักฐาน\nจะได้รับการแจ้งผลภายใน 30 วินาที',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: RiderColors.muted, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderColors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('กลับหน้าออเดอร์',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: RiderColors.blueLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RiderColors.blue.withValues(alpha: 0.3)),
          ),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.smart_toy_rounded, color: RiderColors.blue, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI จะวิเคราะห์คำร้องของคุณและแจ้งผลภายใน 30 วินาที — confidence ≥80% AI แก้เอง ต่ำกว่านั้น admin ตรวจสอบ',
                style: TextStyle(fontSize: 12, color: RiderColors.blue, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        const Text('ประเภทปัญหา *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RiderColors.text, letterSpacing: 0.2)),
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
                  color: sel ? RiderColors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? RiderColors.blue : const Color(0xFFEEEEEE),
                    width: sel ? 2 : 1,
                  ),
                  boxShadow: sel
                      ? [BoxShadow(color: RiderColors.blue.withValues(alpha: 0.25), blurRadius: 8)]
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                ),
                child: Row(children: [
                  Icon(icon, size: 18, color: sel ? Colors.white : RiderColors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : RiderColors.text,
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

        const Text('อธิบายเพิ่มเติม (ไม่บังคับ)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RiderColors.text, letterSpacing: 0.2)),
        const SizedBox(height: 10),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          maxLength: 300,
          style: const TextStyle(fontSize: 14, color: RiderColors.text),
          decoration: InputDecoration(
            hintText: 'เช่น โทรหาลูกค้า 3 ครั้งแต่ไม่รับ รอ 10 นาทีแล้วส่งคืนร้าน...',
            hintStyle: const TextStyle(fontSize: 13, color: RiderColors.muted),
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
              borderSide: const BorderSide(color: RiderColors.blue, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Row(children: [
          const Text('แนบรูปหลักฐาน',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RiderColors.text, letterSpacing: 0.2)),
          const SizedBox(width: 6),
          Text('(${_photos.length}/3)',
              style: const TextStyle(fontSize: 12, color: RiderColors.muted)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          if (_photos.length < 3)
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_a_photo_rounded, color: RiderColors.blue, size: 26),
                  SizedBox(height: 4),
                  Text('เพิ่มรูป', style: TextStyle(fontSize: 12, color: RiderColors.muted, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          if (_photos.isNotEmpty) const SizedBox(width: 10),
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
                      child: const Icon(Icons.close, color: Colors.white, size: 13),
                    ),
                  ),
                ),
              ]),
            );
          }),
        ]),
        const SizedBox(height: 32),

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
              backgroundColor: RiderColors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: RiderColors.blueMid,
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
