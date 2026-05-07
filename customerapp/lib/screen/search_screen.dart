import 'package:flutter/material.dart';
import '../main.dart';
import 'store_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stores;
  final String customerId;
  final String customerName;
  final String customerPhone;
  const SearchScreen({
    super.key,
    required this.stores,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
  });
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  static const _recentKeywords = ['Burger', 'Sandwich', 'Pizza', 'Sushi', 'Coffee'];

  List<Map<String, dynamic>> get _results {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return widget.stores.where((s) =>
      (s['name']?.toString().toLowerCase().contains(q) ?? false) ||
      (s['type']?.toString().toLowerCase().contains(q) ?? false)
    ).toList();
  }

  List<Map<String, dynamic>> get _popular {
    final list = widget.stores.where((s) => s['is_open'] == 1).toList();
    list.sort((a, b) {
      final rA = double.tryParse(a['rating']?.toString() ?? '0') ?? 0;
      final rB = double.tryParse(b['rating']?.toString() ?? '0') ?? 0;
      return rB.compareTo(rA);
    });
    return list;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _goToStore(Map<String, dynamic> store) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => StoreScreen(
        store: store,
        customerId: widget.customerId,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: CColors.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: CColors.text),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Search', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: CColors.text)),
          ),
          Container(
            width: 38, height: 38,
            decoration: const BoxDecoration(color: Color(0xFF1A1A1A), shape: BoxShape.circle),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
          ),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search field ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 14, color: CColors.text),
                decoration: InputDecoration(
                  hintText: 'Search dishes, restaurants',
                  hintStyle: const TextStyle(color: CColors.muted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: CColors.muted, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () { _ctrl.clear(); setState(() => _query = ''); },
                          child: const Icon(Icons.close_rounded, color: CColors.muted, size: 20),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_query.isEmpty) ...[
              // ── Recent Keywords ───────────────────────────────────────
              const Text('Recent Keywords', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CColors.text)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentKeywords.map((kw) => GestureDetector(
                  onTap: () { _ctrl.text = kw; setState(() => _query = kw); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                    ),
                    child: Text(kw, style: const TextStyle(fontSize: 13, color: CColors.text, fontWeight: FontWeight.w500)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 28),

              // ── Suggested Restaurants ─────────────────────────────────
              const Text('Suggested Restaurants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CColors.text)),
              const SizedBox(height: 12),
              ..._popular.take(3).map((s) => _SearchTile(store: s, onTap: () => _goToStore(s))),
              const SizedBox(height: 28),

              // ── Popular Fast Food ─────────────────────────────────────
              const Text('Popular Fast Food', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CColors.text)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _popular.take(4).length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.88,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, i) => _PopularCard(store: _popular[i], onTap: () => _goToStore(_popular[i])),
              ),
            ] else ...[
              // ── Search Results ────────────────────────────────────────
              if (_results.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Column(children: [
                      const Icon(Icons.search_off_rounded, size: 52, color: CColors.muted),
                      const SizedBox(height: 12),
                      Text('ไม่พบ "$_query"', style: const TextStyle(color: CColors.muted, fontSize: 15)),
                    ]),
                  ),
                )
              else ...[
                Text('${_results.length} ผลลัพธ์', style: const TextStyle(fontSize: 13, color: CColors.muted)),
                const SizedBox(height: 12),
                ..._results.map((s) => _SearchTile(store: s, onTap: () => _goToStore(s))),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Search Tile ──────────────────────────────────────────────────────────────

class _SearchTile extends StatelessWidget {
  final Map<String, dynamic> store;
  final VoidCallback onTap;
  const _SearchTile({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(store['rating']?.toString() ?? '0') ?? 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: store['image_url'] != null
                ? Image.network(
                    store['image_url'],
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 56, height: 56,
                      color: CColors.orangeLight,
                      child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 24),
                    ),
                  )
                : Container(
                    width: 56, height: 56,
                    color: CColors.orangeLight,
                    child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 24),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(store['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: CColors.text)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, size: 13, color: CColors.orange),
                const SizedBox(width: 3),
                Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: CColors.text, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: CColors.muted, size: 20),
        ]),
      ),
    );
  }
}

// ─── Popular Card (circular image) ───────────────────────────────────────────

class _PopularCard extends StatelessWidget {
  final Map<String, dynamic> store;
  final VoidCallback onTap;
  const _PopularCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 16),
          ClipOval(
            child: store['image_url'] != null
                ? Image.network(
                    store['image_url'],
                    width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 80, height: 80,
                      color: CColors.orangeLight,
                      child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 32),
                    ),
                  )
                : Container(
                    width: 80, height: 80,
                    color: CColors.orangeLight,
                    child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 32),
                  ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
            child: Column(children: [
              Text(
                store['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: CColors.text),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                store['type'] ?? '',
                style: const TextStyle(fontSize: 11, color: CColors.muted),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
