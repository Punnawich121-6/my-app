import 'package:flutter/material.dart';
import '../../main.dart';
import '../../l10n/strings.dart';
import '../../services/customer_service.dart';
import '../store/store_screen.dart';

// In-memory favorites store (session-only)
class FavoritesManager {
  static final Set<String> _ids = {};
  static bool isFav(String id) => _ids.contains(id);
  static void toggle(String id) => _ids.contains(id) ? _ids.remove(id) : _ids.add(id);
  static List<String> get ids => _ids.toList();
}

class FavoritesScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;
  const FavoritesScreen({super.key, required this.customerId, required this.customerName, required this.customerPhone});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favStores = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await CustomerService.getStores();
    if (!mounted) return;
    setState(() {
      _favStores = all.where((s) => FavoritesManager.isFav(s['id'].toString())).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(S.favourites, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.fg)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: context.subtleBg, shape: BoxShape.circle),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: context.fg),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: CColors.orange))
          : _favStores.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 80, height: 80,
                        decoration: BoxDecoration(color: context.orangeLight, shape: BoxShape.circle),
                        child: const Icon(Icons.favorite_border_rounded, color: CColors.orange, size: 40)),
                    const SizedBox(height: 16),
                    Text(S.noFavourites, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.fg)),
                    const SizedBox(height: 8),
                    Text(S.noFavSub, style: TextStyle(color: context.muted, fontSize: 13)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: CColors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favStores.length,
                    itemBuilder: (_, i) {
                      final store = _favStores[i];
                      final isOpen = store['is_open'] == 1;
                      final rating = double.tryParse(store['rating']?.toString() ?? '0') ?? 0;
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => StoreScreen(store: store, customerId: widget.customerId, customerName: widget.customerName, customerPhone: widget.customerPhone),
                        )).then((_) => _load()),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: context.card,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))],
                          ),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                              child: SizedBox(
                                width: 100, height: 90,
                                child: store['image_url'] != null
                                    ? Image.network(store['image_url'], fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(color: context.orangeLight, child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 32)))
                                    : Container(color: context.orangeLight, child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 32)),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(store['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.fg)),
                                  Text(store['type'] ?? '', style: TextStyle(fontSize: 12, color: context.muted)),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const Icon(Icons.star_rounded, size: 13, color: CColors.orange),
                                    const SizedBox(width: 3),
                                    Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: context.fg, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isOpen ? CColors.greenLight : context.subtleBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(isOpen ? 'เปิด' : S.closed,
                                          style: TextStyle(fontSize: 11, color: isOpen ? CColors.green : context.muted, fontWeight: FontWeight.w600)),
                                    ),
                                  ]),
                                ]),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                FavoritesManager.toggle(store['id'].toString());
                                setState(() => _favStores.remove(store));
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(14),
                                child: Icon(Icons.favorite_rounded, color: CColors.red, size: 22),
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
