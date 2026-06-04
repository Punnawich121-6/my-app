import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img_lib;
import '../../app_settings.dart';
import '../../config.dart';
import '../../main.dart';
import '../../services/rider_service.dart';
import '../auth/login_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String riderId;
  final String riderName;
  const ProfileScreen({super.key, required this.riderId, required this.riderName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _descCtrl = TextEditingController();
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _reviewData;
  bool _loadingProfile = true;
  bool _saving = false;
  bool _generating = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    RiderSettings.instance.addListener(_onSettings);
    _loadProfile();
  }

  void _onSettings() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    RiderSettings.instance.removeListener(_onSettings);
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final results = await Future.wait([
      RiderService.getProfile(widget.riderId),
      RiderService.getReviews(widget.riderId),
    ]);
    if (!mounted) return;
    final p = results[0] as Map<String, dynamic>?;
    setState(() {
      _profile = p;
      _reviewData = results[1] as Map<String, dynamic>?;
      _descCtrl.text = p?['description'] ?? '';
      _loadingProfile = false;
    });
  }

  Future<void> _saveBio() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    await RiderService.updateProfile(widget.riderId, description: _descCtrl.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
        SizedBox(width: 8),
        Text('บันทึก Bio เรียบร้อย'),
      ]),
      backgroundColor: RiderColors.blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  String _b64(Uint8List bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final buf = StringBuffer();
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i], b1 = i+1 < bytes.length ? bytes[i+1] : 0, b2 = i+2 < bytes.length ? bytes[i+2] : 0;
      buf.write(chars[(b0 >> 2) & 63]);
      buf.write(chars[((b0 & 3) << 4) | ((b1 >> 4) & 15)]);
      buf.write(i+1 < bytes.length ? chars[((b1 & 15) << 2) | ((b2 >> 6) & 3)] : '=');
      buf.write(i+2 < bytes.length ? chars[b2 & 63] : '=');
    }
    return buf.toString();
  }

  Future<void> _generateBio() async {
    setState(() => _generating = true);
    final runs = _profile?['runsCompleted']?.toString() ?? '0';
    final bio = await RiderService.generateRiderBio(riderName: widget.riderName, runsCompleted: runs);
    if (!mounted) return;
    if (bio != null) setState(() => _descCtrl.text = bio);
    setState(() => _generating = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (picked == null || !mounted) return;

    Uint8List originalBytes = Uint8List(0);
    Uint8List? aiCroppedBytes;

    setState(() => _uploadingPhoto = true);
    try {
      originalBytes = await picked.readAsBytes();
      final ext = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      final dataUri = 'data:image/$ext;base64,${_b64(originalBytes)}';
      final cropData = await RiderService.autoCropImage(dataUri);
      if (cropData != null) {
        final srcImg = img_lib.decodeImage(originalBytes);
        if (srcImg != null) {
          final cx = ((cropData['x'] as num? ?? 0).toDouble() * srcImg.width).round().clamp(0, srcImg.width - 1);
          final cy = ((cropData['y'] as num? ?? 0).toDouble() * srcImg.height).round().clamp(0, srcImg.height - 1);
          final cw = ((cropData['w'] as num? ?? 1).toDouble() * srcImg.width).round().clamp(1, srcImg.width - cx);
          final ch = ((cropData['h'] as num? ?? 1).toDouble() * srcImg.height).round().clamp(1, srcImg.height - cy);
          final cropped = img_lib.copyCrop(srcImg, x: cx, y: cy, width: cw, height: ch);
          aiCroppedBytes = Uint8List.fromList(img_lib.encodeJpg(cropped, quality: 85));
        }
      }
    } catch (_) {}
    if (!mounted) { setState(() => _uploadingPhoto = false); return; }
    setState(() => _uploadingPhoto = false);

    final result = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RiderCropChoiceSheet(aiCroppedBytes: aiCroppedBytes, originalBytes: originalBytes),
    );
    if (result == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await RiderService.uploadProfilePhoto(widget.riderId, result, 'profile.jpg');
      if (!mounted) return;
      if (url != null) {
        setState(() => _profile = {...?_profile, 'profile_photo': url});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('อัปโหลดรูปโปรไฟล์เรียบร้อย'),
          ]),
          backgroundColor: RiderColors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('อัปโหลดไม่สำเร็จ กรุณาลองใหม่'),
          backgroundColor: RiderColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {}
    if (mounted) setState(() => _uploadingPhoto = false);
    setState(() => _uploadingPhoto = false);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ออกจากระบบ?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('คุณต้องการออกจากระบบใช่ไหม?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก', style: TextStyle(color: RiderColors.muted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: RiderColors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final runs = _profile?['runsCompleted'] ?? 0;
    final rating = double.tryParse(_profile?['rating']?.toString() ?? '0') ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const SizedBox(height: 8),

        // Avatar + name
        GestureDetector(
          onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
          child: Stack(alignment: Alignment.bottomRight, children: [
            () {
              final photoPath = _profile?['profile_photo']?.toString();
              final photoUrl = (photoPath != null && photoPath.isNotEmpty)
                  ? (photoPath.startsWith('http') ? photoPath : '$kBackendUrl$photoPath')
                  : null;
              return Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: RiderColors.blueLight,
                  shape: BoxShape.circle,
                  image: photoUrl != null
                      ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: _uploadingPhoto
                    ? const CircularProgressIndicator(color: RiderColors.blue, strokeWidth: 2)
                    : (photoUrl == null
                        ? const Icon(Icons.person_rounded, color: RiderColors.blue, size: 48)
                        : null),
              );
            }(),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: RiderColors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Text(widget.riderName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: RiderColors.text)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: RiderColors.blueLight, borderRadius: BorderRadius.circular(20)),
          child: const Text('Rider Partner', style: TextStyle(color: RiderColors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        const SizedBox(height: 20),

        // Stats row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(children: [
            _StatCol(label: 'รอบที่ส่ง', value: '$runs รอบ'),
            _Divider(),
            _StatCol(
              label: 'คะแนน',
              value: rating > 0 ? rating.toStringAsFixed(1) : '-',
              icon: rating > 0 ? Icons.star_rounded : null,
            ),
            _Divider(),
            _StatCol(label: 'สถานะ', value: 'ใช้งาน', valueColor: RiderColors.blue),
          ]),
        ),
        const SizedBox(height: 16),

        // Bio / Description
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Bio ของฉัน', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RiderColors.text)),
              GestureDetector(
                onTap: _generating ? null : _generateBio,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: RiderColors.blueLight, borderRadius: BorderRadius.circular(20)),
                  child: _generating
                      ? const Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: RiderColors.blue, strokeWidth: 1.5)),
                          SizedBox(width: 6),
                          Text('Generating...', style: TextStyle(fontSize: 11, color: RiderColors.blue)),
                        ])
                      : const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.auto_awesome_rounded, color: RiderColors.blue, size: 13),
                          SizedBox(width: 5),
                          Text('AI Generate', style: TextStyle(fontSize: 11, color: RiderColors.blue, fontWeight: FontWeight.w700)),
                        ]),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: RiderColors.text),
              decoration: InputDecoration(
                hintText: 'แนะนำตัวเองสักเล็กน้อย เช่น ส่งเร็ว ตรงเวลา ไว้วางใจได้...',
                hintStyle: const TextStyle(color: RiderColors.muted, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF5F8FF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveBio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: RiderColors.blue,
                  elevation: 0,
                  side: const BorderSide(color: RiderColors.blue, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('บันทึก Bio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Reviews card
        _ReviewsCard(reviewData: _reviewData),
        const SizedBox(height: 16),

        // Info card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            _ProfileTile(icon: Icons.badge_rounded, label: 'Rider ID', value: '#${widget.riderId.substring(0, 8)}'),
          ]),
        ),
        const SizedBox(height: 16),

        // Settings
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            _ActionTile(
              icon: Icons.account_balance_wallet_rounded,
              label: 'วอลเล็ต Pre-Paid',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WalletScreen(riderId: widget.riderId, riderName: widget.riderName)),
              ),
            ),
            const Divider(height: 1, indent: 56, color: Color(0xFFE0E0E0)),
            _ActionTile(icon: Icons.help_outline_rounded, label: 'ความช่วยเหลือ', onTap: () {}),
            const Divider(height: 1, indent: 56, color: Color(0xFFE0E0E0)),
            _ActionTile(icon: Icons.policy_outlined, label: 'นโยบายและเงื่อนไข', onTap: () {}),
          ]),
        ),
        const SizedBox(height: 16),

        // ── การแสดงผล ─────────────────────────────────────────────
        _SettingsCard(children: [
          _SwitchTile(
            icon: Icons.dark_mode_rounded,
            iconBg: const Color(0xFF2D2D44),
            iconColor: const Color(0xFFB39DDB),
            label: 'โหมดมืด',
            labelEn: 'Dark Mode',
            value: RiderSettings.instance.isDark,
            onChanged: (_) => RiderSettings.instance.toggleTheme(),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFE0E0E0)),
          _SwitchTile(
            icon: Icons.language_rounded,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1976D2),
            label: 'English',
            labelEn: 'English',
            value: RiderSettings.instance.isEnglish,
            onChanged: (v) => RiderSettings.instance.setEnglish(v),
          ),
        ]),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity, height: 52,
          child: OutlinedButton.icon(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: RiderColors.red),
              foregroundColor: RiderColors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('ออกจากระบบ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Zest & Savory Rider v1.0.0', style: TextStyle(color: RiderColors.muted, fontSize: 12)),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ─── Reviews Card ─────────────────────────────────────────────────────────────

class _ReviewsCard extends StatefulWidget {
  final Map<String, dynamic>? reviewData;
  const _ReviewsCard({required this.reviewData});
  @override
  State<_ReviewsCard> createState() => _ReviewsCardState();
}

class _ReviewsCardState extends State<_ReviewsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.reviewData;
    final reviews = (data?['reviews'] as List?) ?? [];
    final avg = double.tryParse(data?['average']?.toString() ?? '0') ?? 0.0;
    final total = data?['total'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: RiderColors.blueLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.star_rounded, color: RiderColors.blue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('รีวิวที่ได้รับ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RiderColors.text)),
              Text('$total รีวิว · คะแนนเฉลี่ย ${avg > 0 ? avg.toStringAsFixed(1) : "-"}',
                  style: const TextStyle(fontSize: 12, color: RiderColors.muted)),
            ])),
            if (avg > 0) ...[
              Row(children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 2),
                Text(avg.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RiderColors.text)),
              ]),
              const SizedBox(width: 8),
            ],
            Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: RiderColors.muted),
          ]),
        ),

        if (_expanded) ...[
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('ยังไม่มีรีวิว', style: TextStyle(color: RiderColors.muted, fontSize: 13)),
              ),
            )
          else
            ...reviews.take(10).map((r) => _RiderReviewTile(review: r)),
        ],
      ]),
    );
  }
}

class _RiderReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;
  const _RiderReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] as int? ?? 0;
    final name = review['customer_name']?.toString() ?? 'ลูกค้า';
    final comment = review['comment']?.toString() ?? '';
    DateTime? date;
    try { date = DateTime.parse(review['created_at'].toString()); } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RiderColors.blueLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: RiderColors.blue.withValues(alpha: 0.2),
            child: Text(name[0], style: const TextStyle(color: RiderColors.blue, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RiderColors.text)),
            if (date != null)
              Text('${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(fontSize: 11, color: RiderColors.muted)),
          ])),
          Row(children: List.generate(5, (i) => Icon(
            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: i < rating ? Colors.amber : RiderColors.muted, size: 13,
          ))),
        ]),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(fontSize: 13, color: RiderColors.text)),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatCol extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final IconData? icon;
  const _StatCol({required this.label, required this.value, this.valueColor, this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      if (icon != null)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.amber, size: 14),
          const SizedBox(width: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor ?? RiderColors.text)),
        ])
      else
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor ?? RiderColors.text)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: RiderColors.muted)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: const Color(0xFFD0D0D0));
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _ProfileTile({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: RiderColors.blueLight, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: RiderColors.blue, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: RiderColors.text))),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? RiderColors.muted)),
    ]),
  );
}

// ─── Crop Choice Sheet ────────────────────────────────────────────────────────

class _RiderCropChoiceSheet extends StatefulWidget {
  final Uint8List? aiCroppedBytes;
  final Uint8List originalBytes;
  const _RiderCropChoiceSheet({this.aiCroppedBytes, required this.originalBytes});
  @override
  State<_RiderCropChoiceSheet> createState() => _RiderCropChoiceSheetState();
}

class _RiderCropChoiceSheetState extends State<_RiderCropChoiceSheet> {
  Future<void> _openManualCrop() async {
    if (widget.originalBytes.isEmpty) return;
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => _RiderManualCropScreen(imageBytes: widget.originalBytes)),
    );
    if (result != null && mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final previewBytes = widget.aiCroppedBytes ?? (widget.originalBytes.isNotEmpty ? widget.originalBytes : null);
    final hasAI = widget.aiCroppedBytes != null;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.auto_awesome_rounded, color: RiderColors.blue, size: 18),
          const SizedBox(width: 8),
          Text(hasAI ? 'AI ตัดรูปให้อัตโนมัติแล้ว' : 'เลือกการตัดรูป',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RiderColors.text)),
        ]),
        const SizedBox(height: 4),
        Text(hasAI ? 'ต้องการใช้ผลลัพธ์นี้ หรือต้องการ Crop เองแทน?' : 'AI วิเคราะห์ไม่สำเร็จ — กรุณา Crop เองหรือใช้รูปเต็ม',
            style: const TextStyle(fontSize: 13, color: RiderColors.muted)),
        const SizedBox(height: 14),
        if (previewBytes != null)
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(previewBytes, height: 200, width: double.infinity, fit: BoxFit.cover)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _openManualCrop,
              icon: const Icon(Icons.crop, size: 16),
              label: const Text('Crop เอง'),
              style: OutlinedButton.styleFrom(
                foregroundColor: RiderColors.blue,
                side: const BorderSide(color: RiderColors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: previewBytes != null ? () => Navigator.pop(context, previewBytes) : null,
              icon: const Icon(Icons.check, size: 16, color: Colors.white),
              label: Text(hasAI ? 'ใช้รูปนี้' : 'ใช้รูปเต็ม', style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderColors.blue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ]),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ]),
    );
  }
}

// ─── Manual Crop Screen ───────────────────────────────────────────────────────

class _RiderManualCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const _RiderManualCropScreen({required this.imageBytes});
  @override
  State<_RiderManualCropScreen> createState() => _RiderManualCropScreenState();
}

class _RiderManualCropScreenState extends State<_RiderManualCropScreen> {
  double _l = 0.05, _t = 0.05, _r = 0.95, _b = 0.95;
  img_lib.Image? _srcImg;

  @override
  void initState() {
    super.initState();
    _srcImg = img_lib.decodeImage(widget.imageBytes);
  }

  void _updateL(double dx, double bw) => setState(() => _l = (_l + dx / bw).clamp(0.0, _r - 0.05));
  void _updateT(double dy, double bh) => setState(() => _t = (_t + dy / bh).clamp(0.0, _b - 0.05));
  void _updateR(double dx, double bw) => setState(() => _r = (_r + dx / bw).clamp(_l + 0.05, 1.0));
  void _updateB(double dy, double bh) => setState(() => _b = (_b + dy / bh).clamp(_t + 0.05, 1.0));

  Rect _imageBounds(Size size) {
    if (_srcImg == null) return Rect.fromLTWH(0, 0, size.width, size.height);
    final imgA = _srcImg!.width / _srcImg!.height;
    final cA = size.width / size.height;
    double w, h;
    if (imgA > cA) { w = size.width; h = size.width / imgA; }
    else            { h = size.height; w = size.height * imgA; }
    return Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
  }

  void _applyCrop() {
    if (_srcImg == null) { Navigator.pop(context); return; }
    final x = (_l * _srcImg!.width).round().clamp(0, _srcImg!.width - 1);
    final y = (_t * _srcImg!.height).round().clamp(0, _srcImg!.height - 1);
    final w = ((_r - _l) * _srcImg!.width).round().clamp(1, _srcImg!.width - x);
    final h = ((_b - _t) * _srcImg!.height).round().clamp(1, _srcImg!.height - y);
    final cropped = img_lib.copyCrop(_srcImg!, x: x, y: y, width: w, height: h);
    final bytes = Uint8List.fromList(img_lib.encodeJpg(cropped, quality: 85));
    if (mounted) Navigator.pop(context, bytes);
  }

  Widget _handle(Offset pos, void Function(DragUpdateDetails, double, double) onDrag, Rect bounds) {
    const r = 22.0;
    return Positioned(
      left: pos.dx - r, top: pos.dy - r, width: r * 2, height: r * 2,
      child: GestureDetector(
        onPanUpdate: (d) => onDrag(d, bounds.width, bounds.height),
        child: Container(decoration: const BoxDecoration(color: RiderColors.blue, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black, foregroundColor: Colors.white,
        title: const Text('Crop รูปโปรไฟล์', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [TextButton(onPressed: _applyCrop, child: const Text('ยืนยัน', style: TextStyle(color: RiderColors.blue, fontWeight: FontWeight.w700, fontSize: 15)))],
      ),
      body: LayoutBuilder(builder: (ctx, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final bounds = _imageBounds(size);
        final tl = Offset(bounds.left + _l * bounds.width, bounds.top + _t * bounds.height);
        final br = Offset(bounds.left + _r * bounds.width, bounds.top + _b * bounds.height);
        final tr = Offset(br.dx, tl.dy);
        final bl = Offset(tl.dx, br.dy);
        return Stack(children: [
          Positioned.fill(child: Image.memory(widget.imageBytes, fit: BoxFit.contain)),
          Positioned.fill(child: CustomPaint(painter: _RiderCropPainter(Rect.fromPoints(tl, br)))),
          _handle(tl, (d, bw, bh) { _updateL(d.delta.dx, bw); _updateT(d.delta.dy, bh); }, bounds),
          _handle(tr, (d, bw, bh) { _updateR(d.delta.dx, bw); _updateT(d.delta.dy, bh); }, bounds),
          _handle(bl, (d, bw, bh) { _updateL(d.delta.dx, bw); _updateB(d.delta.dy, bh); }, bounds),
          _handle(br, (d, bw, bh) { _updateR(d.delta.dx, bw); _updateB(d.delta.dy, bh); }, bounds),
          Positioned(bottom: 20, left: 0, right: 0,
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: const Text('ลากมุมสีส้มเพื่อปรับขนาด', style: TextStyle(color: Colors.white, fontSize: 12)),
            ))),
        ]);
      }),
    );
  }
}

class _RiderCropPainter extends CustomPainter {
  final Rect cropRect;
  const _RiderCropPainter(this.cropRect);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black54);
    canvas.drawRect(cropRect, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final grid = Paint()..color = Colors.white38..strokeWidth = 0.7;
    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(Offset(cropRect.left + cropRect.width/3*i, cropRect.top), Offset(cropRect.left + cropRect.width/3*i, cropRect.bottom), grid);
      canvas.drawLine(Offset(cropRect.left, cropRect.top + cropRect.height/3*i), Offset(cropRect.right, cropRect.top + cropRect.height/3*i), grid);
    }
  }
  @override
  bool shouldRepaint(_RiderCropPainter old) => old.cropRect != cropRect;
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    final isDark = RiderSettings.instance.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, labelEn;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.labelEn, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final isDark = RiderSettings.instance.isDark;
    final fg = isDark ? const Color(0xFFF0F0F0) : RiderColors.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text(RiderSettings.instance.isEnglish ? labelEn : label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg))),
        Switch(value: value, onChanged: onChanged, activeThumbColor: RiderColors.blue, activeTrackColor: RiderColors.blueMid),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: RiderColors.blueLight, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: RiderColors.blue, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: RiderColors.text))),
        const Icon(Icons.chevron_right_rounded, color: RiderColors.muted),
      ]),
    ),
  );
}
