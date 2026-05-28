import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    _loadProfile();
  }

  @override
  void dispose() {
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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 512);
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    final url = await RiderService.uploadProfilePhoto(widget.riderId, File(picked.path));
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
                  ? '$kBackendUrl$photoPath'
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
