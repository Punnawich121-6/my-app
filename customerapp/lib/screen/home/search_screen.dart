import 'package:flutter/material.dart';
import '../../config.dart';
import '../../main.dart';
import '../../l10n/strings.dart';
import '../store/store_screen.dart';

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
  String? _selectedType;

  List<String> get _types {
    final seen = <String>{};
    return widget.stores
        .map((s) => s['type']?.toString() ?? '')
        .where((t) => t.isNotEmpty && seen.add(t))
        .toList();
  }

  List<Map<String, dynamic>> get _results {
    var list = widget.stores.where((s) {
      if (_selectedType != null && s['type']?.toString() != _selectedType) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        return (s['name']?.toString().toLowerCase().contains(q) ?? false) ||
               (s['type']?.toString().toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
    return list;
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

  bool get _isFiltering => _query.isNotEmpty || _selectedType != null;

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
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: context.subtleBg, shape: BoxShape.circle),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: context.fg),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(S.searchHint.split(',').first.trim(),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.fg)),
          ),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search field ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: context.subtleBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 14, color: context.fg),
                decoration: InputDecoration(
                  hintText: S.searchHint,
                  hintStyle: TextStyle(color: context.muted, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: context.muted, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () { _ctrl.clear(); setState(() => _query = ''); },
                          child: Icon(Icons.close_rounded, color: context.muted, size: 20),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Category chips ────────────────────────────────────────
            if (_types.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _types.map((type) {
                    final selected = _selectedType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = selected ? null : type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? CColors.orange : context.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? CColors.orange : context.divider,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : context.fg,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Content ───────────────────────────────────────────────
            if (!_isFiltering) ...[
              // Suggested
              Text('Suggested Restaurants',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.fg)),
              const SizedBox(height: 12),
              ..._popular.take(3).map((s) => _SearchTile(store: s, onTap: () => _goToStore(s))),
              const SizedBox(height: 24),

              // Popular grid
              Text('Popular Fast Food',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.fg)),
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
              // Results
              if (_results.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Column(children: [
                      Icon(Icons.search_off_rounded, size: 52, color: context.muted),
                      const SizedBox(height: 12),
                      Text(
                        _query.isNotEmpty ? 'ไม่พบ "$_query"' : 'ไม่พบร้านในหมวด "$_selectedType"',
                        style: TextStyle(color: context.muted, fontSize: 15),
                      ),
                    ]),
                  ),
                )
              else ...[
                Text('${_results.length} ${S.stores}',
                    style: TextStyle(fontSize: 13, color: context.muted)),
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
          color: context.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: store['image_url'] != null
                ? Image.network(
                    store['image_url'].toString().startsWith('http')
                        ? store['image_url']
                        : '$kBackendUrl${store['image_url']}',
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 56, height: 56,
                      color: context.orangeLight,
                      child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 24),
                    ),
                  )
                : Container(
                    width: 56, height: 56,
                    color: context.orangeLight,
                    child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 24),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(store['name'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.fg)),
              const SizedBox(height: 2),
              Text(store['type'] ?? '',
                  style: TextStyle(fontSize: 12, color: context.muted)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, size: 13, color: CColors.orange),
                const SizedBox(width: 3),
                Text(rating.toStringAsFixed(1),
                    style: TextStyle(fontSize: 12, color: context.fg, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: context.muted, size: 20),
        ]),
      ),
    );
  }
}

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
          color: context.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 16),
          ClipOval(
            child: store['image_url'] != null
                ? Image.network(
                    store['image_url'].toString().startsWith('http')
                        ? store['image_url']
                        : '$kBackendUrl${store['image_url']}',
                    width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 80, height: 80,
                      color: context.orangeLight,
                      child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 32),
                    ),
                  )
                : Container(
                    width: 80, height: 80,
                    color: context.orangeLight,
                    child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 32),
                  ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
            child: Column(children: [
              Text(
                store['name'] ?? '',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.fg),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                store['type'] ?? '',
                style: TextStyle(fontSize: 11, color: context.muted),
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
