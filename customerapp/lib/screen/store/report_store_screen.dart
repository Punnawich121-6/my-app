import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import '../../config.dart';
import '../../main.dart';

class ReportStoreScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final String customerId;
  final String customerName;

  const ReportStoreScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<ReportStoreScreen> createState() => _ReportStoreScreenState();
}

class _ReportStoreScreenState extends State<ReportStoreScreen> {
  String? _selectedReason;
  final _descCtrl = TextEditingController();
  List<XFile> _photos = [];
  bool _submitting = false;
  bool _done = false;

  static const _reasons = [
    {'key': 'food_quality',    'label': 'คุณภาพอาหารไม่ได้มาตรฐาน', 'icon': Icons.restaurant_rounded},
    {'key': 'wrong_info',     'label': 'ข้อมูลร้านไม่ถูกต้อง',       'icon': Icons.info_outline_rounded},
    {'key': 'fake_reviews',   'label': 'รีวิวเป็นเท็จ',               'icon': Icons.rate_review_rounded},
    {'key': 'overcharged',    'label': 'คิดราคาเกิน',                 'icon': Icons.payments_rounded},
    {'key': 'rude_service',   'label': 'บริการไม่สุภาพ',              'icon': Icons.sentiment_dissatisfied_rounded},
    {'key': 'other',          'label': 'ปัญหาอื่นๆ',                  'icon': Icons.help_outline_rounded},
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
    setState(() => _photos.add(picked));
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกประเภทปัญหาก่อน'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      final uri = Uri.parse('$kBackendUrl/api/disputes/store-report');

      if (_photos.isEmpty) {
        final res = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'customerId':   widget.customerId,
            'customerName': widget.customerName,
            'storeId':      widget.storeId,
            'storeName':    widget.storeName,
            'reasonType':   _selectedReason,
            'description':  _descCtrl.text.trim(),
          }),
        ).timeout(const Duration(seconds: 20));

        if (mounted) setState(() { _submitting = false; _done = res.statusCode == 201; });
      } else {
        final req = http.MultipartRequest('POST', uri)
          ..fields['customerId']   = widget.customerId
          ..fields['customerName'] = widget.customerName
          ..fields['storeId']      = widget.storeId
          ..fields['storeName']    = widget.storeName
          ..fields['reasonType']   = _selectedReason!
          ..fields['description']  = _descCtrl.text.trim();

        for (final photo in _photos) {
          final bytes = await photo.readAsBytes();
          final name  = photo.name.isNotEmpty ? photo.name : 'photo.jpg';
          final mime  = photo.mimeType ?? _guessMime(name);
          req.files.add(http.MultipartFile.fromBytes(
            'evidence', bytes, filename: name, contentType: MediaType.parse(mime)));
        }

        final streamed = await req.send().timeout(const Duration(seconds: 30));
        if (mounted) setState(() { _submitting = false; _done = streamed.statusCode == 201; });
      }

      if (mounted && !_done) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งรายงานไม่สำเร็จ กรุณาลองใหม่'),
            backgroundColor: CColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่'),
            backgroundColor: CColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.card,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('รายงานปัญหา',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.fg)),
          Text(widget.storeName,
              style: TextStyle(fontSize: 11, color: context.muted, fontWeight: FontWeight.w400)),
        ]),
        centerTitle: true,
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
          Text('ส่งรายงานสำเร็จ!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.fg)),
          const SizedBox(height: 10),
          Text('ขอบคุณที่แจ้งปัญหา\nทีมงาน admin จะตรวจสอบและดำเนินการโดยเร็ว',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.muted, height: 1.5)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: CColors.orange, foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('กลับหน้าร้าน',
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

        // Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.orangeLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CColors.orange.withValues(alpha: 0.3)),
          ),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.flag_rounded, color: CColors.orange, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'รายงานปัญหาจะถูกส่งตรงถึง admin เพื่อตรวจสอบ ขอบคุณที่ช่วยรักษาคุณภาพของแอป',
                style: TextStyle(fontSize: 12, color: CColors.orange, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Reason
        Text('ประเภทปัญหา *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.fg, letterSpacing: 0.2)),
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
                  color: sel ? CColors.orange : context.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? CColors.orange : context.divider,
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
                        fontSize: 11.5, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : context.fg,
                      ),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Description
        Text('อธิบายเพิ่มเติม (ไม่บังคับ)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.fg, letterSpacing: 0.2)),
        const SizedBox(height: 10),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          maxLength: 300,
          style: TextStyle(fontSize: 14, color: context.fg),
          decoration: InputDecoration(
            hintText: 'อธิบายปัญหาที่พบ...',
            hintStyle: TextStyle(fontSize: 13, color: context.muted),
            filled: true,
            fillColor: context.card,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CColors.orange, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Photos
        Row(children: [
          Text('แนบรูปหลักฐาน',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.fg, letterSpacing: 0.2)),
          const SizedBox(width: 6),
          Text('(${_photos.length}/3)',
              style: TextStyle(fontSize: 12, color: context.muted)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          if (_photos.length < 3)
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  color: context.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.divider),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_a_photo_rounded, color: CColors.orange, size: 26),
                  const SizedBox(height: 4),
                  Text('เพิ่มรูป',
                      style: TextStyle(fontSize: 12, color: context.muted, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          if (_photos.isNotEmpty) const SizedBox(width: 10),
          ..._photos.asMap().entries.map((e) {
            final i    = e.key;
            final file = e.value;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: kIsWeb
                      ? Image.network(file.path, width: 76, height: 76, fit: BoxFit.cover)
                      : Image.file(io.File(file.path), width: 76, height: 76, fit: BoxFit.cover),
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
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.flag_rounded, size: 18),
            label: Text(
              _submitting ? 'กำลังส่ง...' : 'ส่งรายงาน',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: CColors.orange, foregroundColor: Colors.white,
              disabledBackgroundColor: CColors.orange.withValues(alpha: 0.6),
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

String _guessMime(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':  return 'image/png';
    case 'gif':  return 'image/gif';
    case 'webp': return 'image/webp';
    default:     return 'image/jpeg';
  }
}
