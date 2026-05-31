import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config.dart';
import '../../main.dart';

class StoreReviewsScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final double rating;

  const StoreReviewsScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.rating,
  });

  @override
  State<StoreReviewsScreen> createState() => _StoreReviewsScreenState();
}

class _StoreReviewsScreenState extends State<StoreReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await apiGet(
        '$kBackendUrl/api/customer/stores/${widget.storeId}/reviews',
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() {
          _reviews = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(dynamic iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso.toString())?.toLocal();
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final avgRating = widget.rating;
    final count = _reviews.length;

    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: CColors.bg,
        elevation: 0,
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('รีวิวร้านอาหาร',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: CColors.text)),
          Text(widget.storeName,
              style: const TextStyle(fontSize: 12, color: CColors.muted, fontWeight: FontWeight.w400)),
        ]),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: CColors.text),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: CColors.orange))
          : RefreshIndicator(
              onRefresh: _load,
              color: CColors.orange,
              child: CustomScrollView(
                slivers: [
                  // Summary card
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(avgRating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: CColors.text, height: 1)),
                          const SizedBox(height: 4),
                          Row(children: List.generate(5, (i) => Icon(
                            i < avgRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                            color: CColors.orange, size: 18,
                          ))),
                          const SizedBox(height: 4),
                          Text('$count รีวิว', style: const TextStyle(fontSize: 13, color: CColors.muted)),
                        ]),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: List.generate(5, (i) {
                              final star = 5 - i;
                              final cnt = _reviews.where((r) {
                                final rv = int.tryParse(r['rating']?.toString() ?? '0') ?? 0;
                                return rv == star;
                              }).length;
                              final ratio = count == 0 ? 0.0 : cnt / count;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(children: [
                                  Text('$star', style: const TextStyle(fontSize: 12, color: CColors.muted, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star_rounded, size: 12, color: CColors.orange),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 6,
                                        backgroundColor: CColors.orangeLight,
                                        valueColor: const AlwaysStoppedAnimation<Color>(CColors.orange),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 20,
                                    child: Text('$cnt',
                                        style: const TextStyle(fontSize: 11, color: CColors.muted),
                                        textAlign: TextAlign.right),
                                  ),
                                ]),
                              );
                            }),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  // Review list
                  if (_reviews.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.rate_review_rounded, size: 56, color: CColors.orange),
                          SizedBox(height: 12),
                          Text('ยังไม่มีรีวิว', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CColors.text)),
                          SizedBox(height: 6),
                          Text('เป็นคนแรกที่รีวิวร้านนี้!', style: TextStyle(color: CColors.muted, fontSize: 13)),
                        ]),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _ReviewCard(review: _reviews[i], formatDate: _formatDate),
                          childCount: _reviews.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final String Function(dynamic) formatDate;
  const _ReviewCard({required this.review, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final rating = int.tryParse(review['rating']?.toString() ?? '0') ?? 0;
    final comment = review['comment'] as String? ?? '';
    final name = review['customer_name'] as String? ?? 'ลูกค้า';
    final date = formatDate(review['created_at']);
    List<String> images = [];
    try {
      final raw = review['images'];
      if (raw != null && raw.toString().isNotEmpty) {
        final decoded = jsonDecode(raw.toString()) as List?;
        images = decoded?.map((e) => e.toString()).toList() ?? [];
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: CColors.orange, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CColors.text)),
            Text(date, style: const TextStyle(fontSize: 11, color: CColors.muted)),
          ])),
          Row(children: List.generate(5, (i) => Icon(
            i < rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: CColors.orange, size: 14,
          ))),
        ]),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(comment, style: const TextStyle(fontSize: 13, color: CColors.text, height: 1.5)),
        ],
        if (images.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _viewImage(context, images[i]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: images[i].startsWith('data:')
                      ? Image.memory(
                          base64Decode(images[i].split(',').last),
                          width: 80, height: 80, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imgError(),
                        )
                      : Image.network(
                          images[i].startsWith('http') ? images[i] : '$kBackendUrl${images[i]}',
                          width: 80, height: 80, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imgError(),
                        ),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _imgError() => Container(
    width: 80, height: 80,
    decoration: const BoxDecoration(color: CColors.orangeLight),
    child: const Icon(Icons.broken_image_rounded, color: CColors.orange, size: 28),
  );

  void _viewImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
          body: Center(
            child: InteractiveViewer(
              child: url.startsWith('data:')
                  ? Image.memory(base64Decode(url.split(',').last), fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_rounded, color: Colors.white60, size: 48))
                  : Image.network(
                      url.startsWith('http') ? url : '$kBackendUrl$url',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_rounded, color: Colors.white60, size: 48),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
