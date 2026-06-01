import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../l10n/strings.dart';
import '../../services/customer_service.dart';

class UserReviewsScreen extends StatefulWidget {
  final String customerId;
  const UserReviewsScreen({super.key, required this.customerId});
  @override
  State<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends State<UserReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await CustomerService.getMyReviews(widget.customerId);
    if (mounted) setState(() { _reviews = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(S.reviewsTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.fg)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: CColors.orange))
          : _reviews.isEmpty
              ? _Empty()
              : RefreshIndicator(
                  color: CColors.orange,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _reviews.length,
                    itemBuilder: (context, i) => _ReviewCard(
                      review: _reviews[i],
                      onTap: () => _openDetail(context, _reviews[i]),
                    ),
                  ),
                ),
    );
  }

  void _openDetail(BuildContext context, Map<String, dynamic> review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewDetailSheet(review: review),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.rate_review_rounded, size: 64, color: context.muted.withValues(alpha: 0.4)),
      const SizedBox(height: 16),
      Text(S.noReviews,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.muted)),
      const SizedBox(height: 8),
      Text(S.noReviewsSub, style: TextStyle(fontSize: 13, color: context.muted)),
    ]),
  );
}

// ─── Review card (list item) ──────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onTap;
  const _ReviewCard({required this.review, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isStore  = review['type'] == 'store';
    final rating   = (review['rating'] as num?)?.toInt() ?? 0;
    final comment  = review['comment'] as String? ?? '';
    final name     = review['target_name'] as String? ?? (isStore ? 'ร้านอาหาร' : 'Rider');
    final dateStr  = _formatDate(review['created_at']);
    final imgUrls  = _parseImages(review['images']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              // Icon
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isStore ? const Color(0xFFFFEDE5) : const Color(0xFFE8F5FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isStore ? Icons.storefront_rounded : Icons.delivery_dining_rounded,
                  color: isStore ? CColors.orange : const Color(0xFF2196F3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Name + type
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.fg),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(isStore ? S.storeLabel : S.riderLabel,
                    style: TextStyle(fontSize: 12, color: context.muted)),
              ])),
              // Date + chevron
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(dateStr, style: TextStyle(fontSize: 12, color: context.muted)),
                const SizedBox(height: 2),
                Icon(Icons.chevron_right_rounded, size: 18, color: context.muted),
              ]),
            ]),
          ),
          // Stars
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: Row(children: List.generate(5, (i) => Icon(
              i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < rating ? const Color(0xFFFFC107) : context.muted,
              size: 16,
            ))),
          ),
          // Comment preview (2 lines max)
          if (comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(
                comment,
                style: TextStyle(fontSize: 13.5, color: context.fg, height: 1.45),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Image strip (thumbnails)
          if (imgUrls.isNotEmpty) _ThumbnailStrip(urls: imgUrls),
          const SizedBox(height: 14),
        ]),
      ),
    );
  }
}

// ─── Review detail bottom sheet ───────────────────────────────────────────────

class _ReviewDetailSheet extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewDetailSheet({required this.review});

  @override
  Widget build(BuildContext context) {
    final isStore = review['type'] == 'store';
    final rating  = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final name    = review['target_name'] as String? ?? (isStore ? 'ร้านอาหาร' : 'Rider');
    final dateStr = _formatDate(review['created_at']);
    final imgUrls = _parseImages(review['images']);
    final accent  = isStore ? CColors.orange : const Color(0xFF2196F3);
    final iconBg  = isStore ? const Color(0xFFFFEDE5) : const Color(0xFFE8F5FF);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // Header
                Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                    child: Icon(
                      isStore ? Icons.storefront_rounded : Icons.delivery_dining_rounded,
                      color: accent, size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.fg)),
                    Text(isStore ? 'รีวิวร้านอาหาร' : 'รีวิวไรเดอร์',
                        style: TextStyle(fontSize: 13, color: context.muted)),
                  ])),
                  Text(dateStr, style: TextStyle(fontSize: 12, color: context.muted)),
                ]),

                const SizedBox(height: 20),

                // Big star rating
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.subtleBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Icon(
                            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: i < rating ? const Color(0xFFFFC107) : context.muted,
                            size: 36,
                          ),
                        ))),
                    const SizedBox(height: 6),
                    Text(
                      _ratingLabel(rating),
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: rating >= 4
                            ? const Color(0xFF16A34A)
                            : rating == 3
                                ? CColors.orange
                                : CColors.red,
                      ),
                    ),
                  ]),
                ),

                // Comment
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('ความคิดเห็น',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: context.muted)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.subtleBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      comment,
                      style: TextStyle(fontSize: 14.5, color: context.fg, height: 1.55),
                    ),
                  ),
                ],

                // Images
                if (imgUrls.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('รูปภาพประกอบ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: context.muted)),
                  const SizedBox(height: 10),
                  _ImageGrid(urls: imgUrls),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  String _ratingLabel(int r) {
    const labels = ['', 'แย่มาก', 'พอใช้', 'ดี', 'ดีมาก', 'ยอดเยี่ยม'];
    return r >= 1 && r <= 5 ? labels[r] : '';
  }
}

// ─── Thumbnail strip (card preview) ──────────────────────────────────────────

class _ThumbnailStrip extends StatelessWidget {
  final List<String> urls;
  const _ThumbnailStrip({required this.urls});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: SizedBox(
        height: 72,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: urls.length > 4 ? 4 : urls.length,
          itemBuilder: (_, i) {
            final isLast = i == 3 && urls.length > 4;
            return Stack(children: [
              Container(
                width: 68, height: 68,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(urls[i], fit: BoxFit.cover,
                      errorBuilder: (_, __, err) =>
                          const Icon(Icons.broken_image_rounded, color: Colors.grey)),
                ),
              ),
              if (isLast)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('+${urls.length - 3}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}

// ─── Image grid (detail view) ─────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  final List<String> urls;
  const _ImageGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: urls.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _showFullImage(context, urls, i),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            urls[i], fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(
                        color: CColors.orange, strokeWidth: 2)),
                  ),
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, List<String> urls, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          PageView.builder(
            controller: PageController(initialPage: index),
            itemCount: urls.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Image.network(urls[i], fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 48, right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatDate(dynamic raw) {
  try {
    return DateFormat('d MMM yyyy').format(DateTime.parse(raw.toString()));
  } catch (_) {
    return '';
  }
}

List<String> _parseImages(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) return List<String>.from(raw);
  if (raw is String && raw.isNotEmpty) {
    try { return List<String>.from(jsonDecode(raw)); } catch (_) {}
  }
  return [];
}
