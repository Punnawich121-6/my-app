import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../services/customer_service.dart';

class ReviewScreen extends StatefulWidget {
  final String orderId;
  final String customerId;
  final String customerName;
  final String storeId;
  final String storeName;
  final String? riderId;

  const ReviewScreen({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.storeId,
    required this.storeName,
    this.riderId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _storeRating = 0;
  int _riderRating = 0;
  final _storeCommentCtrl = TextEditingController();
  final _riderCommentCtrl = TextEditingController();
  List<XFile> _storeImages = [];
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _storeCommentCtrl.dispose();
    _riderCommentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80, limit: 5);
    if (picked.isNotEmpty) {
      setState(() {
        _storeImages = [..._storeImages, ...picked];
        if (_storeImages.length > 5) _storeImages = _storeImages.sublist(0, 5);
      });
    }
  }

  Future<void> _submit() async {
    if (_storeRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กรุณาให้คะแนนร้านอาหาร'),
        backgroundColor: CColors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _submitting = true);

    final futures = <Future<bool>>[];

    futures.add(CustomerService.submitStoreReview(
      orderId: widget.orderId,
      customerId: widget.customerId,
      customerName: widget.customerName,
      storeId: widget.storeId,
      rating: _storeRating,
      comment: _storeCommentCtrl.text.trim(),
      images: _storeImages,
    ));

    if (widget.riderId != null && widget.riderId!.isNotEmpty && _riderRating > 0) {
      futures.add(CustomerService.submitRiderReview(
        orderId: widget.orderId,
        customerId: widget.customerId,
        customerName: widget.customerName,
        riderId: widget.riderId!,
        rating: _riderRating,
        comment: _riderCommentCtrl.text.trim(),
      ));
    }

    bool ok = false;
    try {
      final results = await Future.wait(futures);
      ok = results.every((r) => r == true);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;

    if (!ok) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ส่งรีวิวไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
        backgroundColor: CColors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() { _submitting = false; _submitted = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: CColors.text),
          onPressed: () => Navigator.pop(context, _submitted),
        ),
        title: const Text('รีวิวออเดอร์',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: CColors.text)),
        centerTitle: true,
      ),
      body: _submitted ? _SuccessView(onClose: () => Navigator.pop(context, true)) : _form(),
    );
  }

  Widget _form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _RatingCard(
          icon: Icons.store_rounded,
          iconColor: CColors.orange,
          iconBg: CColors.orangeLight,
          title: widget.storeName,
          subtitle: 'ให้คะแนนร้านอาหาร',
          rating: _storeRating,
          onRatingChanged: (r) => setState(() => _storeRating = r),
          commentCtrl: _storeCommentCtrl,
          commentHint: 'รีวิวอาหาร บรรยากาศ หรือบริการ...',
          images: _storeImages,
          onPickImages: _pickImages,
          onRemoveImage: (i) => setState(() => _storeImages.removeAt(i)),
        ),

        if (widget.riderId != null && widget.riderId!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _RatingCard(
            icon: Icons.directions_bike_rounded,
            iconColor: const Color(0xFF1976D2),
            iconBg: const Color(0xFFE3F2FD),
            title: 'ไรเดอร์',
            subtitle: 'ให้คะแนนการจัดส่ง (ไม่บังคับ)',
            rating: _riderRating,
            onRatingChanged: (r) => setState(() => _riderRating = r),
            commentCtrl: _riderCommentCtrl,
            commentHint: 'ส่งเร็ว ตรงเวลา เป็นมิตร...',
          ),
        ],

        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: CColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _submitting
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('ส่งรีวิว',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ─── Rating Card ──────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final TextEditingController commentCtrl;
  final String commentHint;
  final List<XFile>? images;
  final VoidCallback? onPickImages;
  final ValueChanged<int>? onRemoveImage;

  const _RatingCard({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.title, required this.subtitle,
    required this.rating, required this.onRatingChanged,
    required this.commentCtrl, required this.commentHint,
    this.images, this.onPickImages, this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CColors.text),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: CColors.muted)),
          ])),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
          final filled = i < rating;
          return GestureDetector(
            onTap: () => onRatingChanged(i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: filled ? const Color(0xFFFFB300) : CColors.muted,
                size: 40,
              ),
            ),
          );
        })),
        if (rating > 0) ...[
          const SizedBox(height: 4),
          Center(child: Text(
            ['', 'แย่มาก', 'พอใช้', 'ดี', 'ดีมาก', 'ยอดเยี่ยม'][rating],
            style: TextStyle(
              color: rating >= 4 ? CColors.green : rating == 3 ? CColors.orange : CColors.red,
              fontWeight: FontWeight.w600, fontSize: 13,
            ),
          )),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: commentCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 14, color: CColors.text),
          decoration: InputDecoration(
            hintText: commentHint,
            hintStyle: const TextStyle(color: CColors.muted, fontSize: 13),
            filled: true,
            fillColor: CColors.orangeLight,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CColors.orange, width: 1.5)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),

        if (onPickImages != null) ...[
          const SizedBox(height: 12),
          _ImagePickerRow(
            images: images ?? [],
            onPick: onPickImages!,
            onRemove: onRemoveImage!,
          ),
        ],
      ]),
    );
  }
}

// ─── Image Picker Row ─────────────────────────────────────────────────────────

class _ImagePickerRow extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  const _ImagePickerRow({required this.images, required this.onPick, required this.onRemove});

  Widget _buildThumb(XFile f) {
    if (kIsWeb) {
      return Image.network(f.path, fit: BoxFit.cover, width: 80, height: 80);
    }
    return Image.file(io.File(f.path), fit: BoxFit.cover, width: 80, height: 80);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.photo_camera_rounded, size: 16, color: CColors.muted),
        const SizedBox(width: 6),
        Text(
          'เพิ่มรูปภาพ (${images.length}/5)',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.muted),
        ),
      ]),
      const SizedBox(height: 8),
      SizedBox(
        height: 82,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            if (images.length < 5)
              GestureDetector(
                onTap: onPick,
                child: Container(
                  width: 80, height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: CColors.orangeLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CColors.orange.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_rounded, color: CColors.orange, size: 28),
                    SizedBox(height: 2),
                    Text('เพิ่มรูป', style: TextStyle(color: CColors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ...images.asMap().entries.map((e) => Stack(
              children: [
                Container(
                  width: 80, height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildThumb(e.value),
                  ),
                ),
                Positioned(
                  top: 2, right: 10,
                  child: GestureDetector(
                    onTap: () => onRemove(e.key),
                    child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 13),
                    ),
                  ),
                ),
              ],
            )),
          ],
        ),
      ),
    ]);
  }
}

// ─── Success View ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final VoidCallback onClose;
  const _SuccessView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 96, height: 96,
            decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: CColors.orange, size: 52),
          ),
          const SizedBox(height: 20),
          const Text('ขอบคุณสำหรับรีวิว!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: CColors.text)),
          const SizedBox(height: 8),
          const Text('รีวิวของคุณช่วยให้ร้านค้าและไรเดอร์พัฒนาบริการได้ดีขึ้น',
              style: TextStyle(fontSize: 14, color: CColors.muted), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: CColors.orange, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('กลับหน้าหลัก',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
