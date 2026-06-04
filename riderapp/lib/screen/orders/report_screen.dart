import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_settings.dart';
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

  List<Map<String, dynamic>> get _reasons => [
    {'key': 'customer_not_answering', 'label': rt('ลูกค้าไม่รับสาย/ไม่รับของ', 'Customer not answering'), 'icon': Icons.phone_missed_rounded},
    {'key': 'wrong_address',          'label': rt('ที่อยู่ผิด/หาไม่เจอ', 'Wrong address'),              'icon': Icons.location_off_rounded},
    {'key': 'unfair_rating',          'label': rt('โดนรีวิวไม่เป็นธรรม', 'Unfair review'),              'icon': Icons.star_border_rounded},
    {'key': 'customer_refused',       'label': rt('ลูกค้าปฏิเสธรับออเดอร์', 'Customer refused order'),  'icon': Icons.cancel_rounded},
    {'key': 'dangerous_area',         'label': rt('พื้นที่ไม่ปลอดภัย', 'Unsafe area'),                  'icon': Icons.warning_rounded},
    {'key': 'other',                  'label': rt('ปัญหาอื่นๆ', 'Other issues'),                         'icon': Icons.help_outline_rounded},
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
        SnackBar(content: Text(rt('กรุณาเลือกประเภทปัญหาก่อน', 'Please select a problem type'))),
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
        SnackBar(content: Text(rt('ส่งคำร้องไม่สำเร็จ กรุณาลองใหม่', 'Failed to submit, please try again'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.rBg,
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
          Text(rt('แจ้งปัญหา', 'Report Issue'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('${rt('ออเดอร์', 'Order')} ${widget.orderNumber}',
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
          Text(rt('ส่งคำร้องสำเร็จ!', 'Report Submitted!'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.rFg)),
          const SizedBox(height: 10),
          Text(
            rt('AI กำลังวิเคราะห์หลักฐาน\nจะได้รับการแจ้งผลภายใน 30 วินาที',
               'AI is analyzing evidence\nResult will be notified within 30 seconds'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.rMuted, height: 1.5),
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
              child: Text(rt('กลับหน้าออเดอร์', 'Back to Order'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.smart_toy_rounded, color: RiderColors.blue, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                rt('AI จะวิเคราะห์คำร้องของคุณและแจ้งผลภายใน 30 วินาที — confidence ≥80% AI แก้เอง ต่ำกว่านั้น admin ตรวจสอบ',
                   'AI will analyze your report within 30 seconds — confidence ≥80% auto-resolved, else admin reviews'),
                style: const TextStyle(fontSize: 12, color: RiderColors.blue, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        Text(rt('ประเภทปัญหา *', 'Problem Type *'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.rFg, letterSpacing: 0.2)),
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
                  color: sel ? RiderColors.blue : context.rCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? RiderColors.blue : context.rDiv,
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
                        color: sel ? Colors.white : context.rFg,
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

        Text(rt('อธิบายเพิ่มเติม (ไม่บังคับ)', 'Additional details (optional)'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.rFg, letterSpacing: 0.2)),
        const SizedBox(height: 10),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          maxLength: 300,
          style: TextStyle(fontSize: 14, color: context.rFg),
          decoration: InputDecoration(
            hintText: rt('เช่น โทรหาลูกค้า 3 ครั้งแต่ไม่รับ...', 'e.g. called customer 3 times, no answer...'),
            hintStyle: TextStyle(fontSize: 13, color: context.rMuted),
            filled: true,
            fillColor: context.rCard,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.rDiv),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.rDiv),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: RiderColors.blue, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Row(children: [
          Text(rt('แนบรูปหลักฐาน', 'Attach Evidence'),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.rFg, letterSpacing: 0.2)),
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
                  color: context.rCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.rDiv),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_a_photo_rounded, color: RiderColors.blue, size: 26),
                  const SizedBox(height: 4),
                  Text(rt('เพิ่มรูป', 'Add Photo'), style: TextStyle(fontSize: 12, color: context.rMuted, fontWeight: FontWeight.w600)),
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
              _submitting ? rt('กำลังส่งคำร้อง...', 'Submitting...') : rt('ส่งคำร้องแจ้งปัญหา', 'Submit Report'),
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
