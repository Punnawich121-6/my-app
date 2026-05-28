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
        title: Text(S.reviewsTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.fg)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: CColors.orange))
          : _reviews.isEmpty
              ? _Empty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (context, i) => _ReviewCard(review: _reviews[i]),
                ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.rate_review_rounded, size: 64, color: context.muted.withValues(alpha: 0.5)),
      const SizedBox(height: 16),
      Text(S.noReviews, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.muted)),
      const SizedBox(height: 8),
      Text(S.noReviewsSub, style: TextStyle(fontSize: 13, color: context.muted)),
    ]),
  );
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final isStore = review['type'] == 'store';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final name = review['target_name'] as String? ?? (isStore ? 'ร้านอาหาร' : 'Rider');
    final createdAt = review['created_at'];
    String dateStr = '';
    try {
      dateStr = DateFormat('d MMM yyyy').format(DateTime.parse(createdAt.toString()));
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isStore ? const Color(0xFFFFEDE5) : const Color(0xFFE8F5FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isStore ? Icons.storefront_rounded : Icons.delivery_dining_rounded,
              color: isStore ? CColors.orange : const Color(0xFF2196F3),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.fg),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(isStore ? S.storeLabel : S.riderLabel, style: TextStyle(fontSize: 12, color: context.muted)),
          ])),
          Text(dateStr, style: TextStyle(fontSize: 12, color: context.muted)),
        ]),
        const SizedBox(height: 10),
        Row(children: List.generate(5, (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: i < rating ? const Color(0xFFFFC107) : context.muted,
          size: 18,
        ))),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(comment, style: TextStyle(fontSize: 14, color: context.fg, height: 1.4)),
        ],
        _ReviewImages(raw: review['images']),
      ]),
    );
  }
}

class _ReviewImages extends StatelessWidget {
  final dynamic raw;
  const _ReviewImages({this.raw});

  List<String> get urls {
    if (raw == null) return [];
    if (raw is List) return List<String>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try { return List<String>.from(jsonDecode(raw)); } catch (_) {}
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final list = urls;
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 84,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _showFullImage(context, list, i),
            child: Container(
              width: 80, height: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  list[i],
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image_rounded, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, List<String> urls, int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          PageView.builder(
            controller: PageController(initialPage: index),
            itemCount: urls.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Image.network(urls[i], fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 8, right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ]),
      ),
    );
  }
}
