import 'package:flutter/material.dart';
import '../main.dart';
import '../services/customer_service.dart';
import 'store_screen.dart';

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
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: CColors.bg,
        elevation: 0,
        title: const Text('ร้านที่ชอบ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: CColors.text)),
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
          : _favStores.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 80, height: 80, decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
                        child: const Icon(Icons.favorite_border_rounded, color: CColors.orange, size: 40)),
                    const SizedBox(height: 16),
                    const Text('ยังไม่มีร้านที่ชอบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CColors.text)),
                    const SizedBox(height: 8),
                    const Text('กดหัวใจ ❤️ ที่หน้าร้านเพื่อบันทึก', style: TextStyle(color: CColors.muted, fontSize: 13)),
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
                        onTap: isOpen ? () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => StoreScreen(store: store, customerId: widget.customerId, customerName: widget.customerName, customerPhone: widget.customerPhone),
                        )).then((_) => _load()) : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))]),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                              child: SizedBox(
                                width: 100, height: 90,
                                child: store['image_url'] != null
                                    ? Image.network(store['image_url'], fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(color: CColors.orangeLight, child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 32)))
                                    : Container(color: CColors.orangeLight, child: const Icon(Icons.restaurant_rounded, color: CColors.orange, size: 32)),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(store['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: CColors.text)),
                                  Text(store['type'] ?? '', style: const TextStyle(fontSize: 12, color: CColors.muted)),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const Icon(Icons.star_rounded, size: 13, color: CColors.orange),
                                    const SizedBox(width: 3),
                                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: CColors.text, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isOpen ? CColors.greenLight : const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(isOpen ? 'เปิด' : 'ปิด', style: TextStyle(fontSize: 11, color: isOpen ? CColors.green : CColors.muted, fontWeight: FontWeight.w600)),
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
