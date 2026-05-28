import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../services/customer_service.dart';
import '../store/store_screen.dart';

class RandomFoodScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;
  const RandomFoodScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<RandomFoodScreen> createState() => _RandomFoodScreenState();
}

class _RandomFoodScreenState extends State<RandomFoodScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _item;
  Map<String, dynamic>? _store;
  bool _loading = true;
  String? _error;
  final _prefCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _fetch();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _prefCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({String? preference, String? excludeStoreId, String? excludeItemId, String? sameStoreId}) async {
    setState(() { _loading = true; _error = null; });
    _animCtrl.reset();

    final result = await CustomerService.suggestFood(
      preference: preference,
      excludeStoreId: excludeStoreId,
      excludeItemId: excludeItemId,
      sameStoreId: sameStoreId,
    );

    if (!mounted) return;
    if (result == null || result['error'] != null) {
      setState(() { _loading = false; _error = result?['error'] ?? 'เกิดข้อผิดพลาด'; });
      return;
    }

    setState(() {
      _item = Map<String, dynamic>.from(result['item']);
      _store = Map<String, dynamic>.from(result['store']);
      _loading = false;
    });
    _animCtrl.forward();
  }

  void _changeMenu() => _fetch(
    preference: _prefCtrl.text.trim().isEmpty ? null : _prefCtrl.text.trim(),
    sameStoreId: _store?['id']?.toString(),
    excludeItemId: _item?['id']?.toString(),
  );

  void _changeStore() => _fetch(
    preference: _item?['name']?.toString(),
    excludeStoreId: _store?['id']?.toString(),
  );

  void _searchByPreference() {
    final pref = _prefCtrl.text.trim();
    if (pref.isEmpty) return;
    FocusScope.of(context).unfocus();
    _fetch(preference: pref);
  }

  void _goToStore() {
    if (_store == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => StoreScreen(
        store: _store!,
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
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: CColors.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ไม่รู้จะกินอะไร?', style: TextStyle(color: CColors.text, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Preference input
        _buildSearchBar(),

        // Content
        Expanded(
          child: _loading
              ? _buildLoading()
              : _error != null
                  ? _buildError()
                  : _buildCard(),
        ),

        // Bottom actions
        if (!_loading && _error == null && _item != null)
          _buildBottomActions(),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _prefCtrl,
              style: const TextStyle(fontSize: 14, color: CColors.text),
              onSubmitted: (_) => _searchByPreference(),
              decoration: const InputDecoration(
                hintText: 'อยากกินอะไร? เช่น ข้าว, ไม่เผ็ด, อาหารทะเล...',
                hintStyle: TextStyle(color: CColors.muted, fontSize: 13),
                border: InputBorder.none,
                icon: Icon(Icons.auto_awesome_rounded, color: CColors.orange, size: 18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _searchByPreference,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: CColors.orange, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: CColors.orange.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Center(child: CircularProgressIndicator(color: CColors.orange, strokeWidth: 3)),
        ),
        const SizedBox(height: 20),
        const Text('AI กำลังหาเมนูให้...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CColors.text)),
        const SizedBox(height: 6),
        const Text('รอสักครู่นะ', style: TextStyle(fontSize: 13, color: CColors.muted)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.sentiment_dissatisfied_rounded, color: CColors.muted, size: 56),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: CColors.muted, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _fetch(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(color: CColors.orange, borderRadius: BorderRadius.circular(12)),
              child: const Text('ลองใหม่', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCard() {
    final fmt = NumberFormat('#,##0');
    final price = double.tryParse(_item!['price']?.toString() ?? '0') ?? 0;
    final rating = double.tryParse(_store!['rating']?.toString() ?? '0') ?? 0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // AI suggestion label
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: CColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome_rounded, color: CColors.orange, size: 14),
                SizedBox(width: 6),
                Text('AI แนะนำเมนูนี้ให้คุณ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CColors.orange)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),

          // Food card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Food image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _item!['image_url'] != null
                      ? Image.network(_item!['image_url'], fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _foodPlaceholder())
                      : _foodPlaceholder(),
                ),
              ),

              // Food info
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_item!['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: CColors.text)),
                  if ((_item!['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(_item!['description'], style: const TextStyle(fontSize: 13, color: CColors.muted, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 14),
                  Row(children: [
                    Text('฿${fmt.format(price)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: CColors.orange)),
                    const Spacer(),
                  ]),
                ]),
              ),

              // Store row
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: CColors.bg, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _store!['image_url'] != null
                        ? Image.network(_store!['image_url'], width: 44, height: 44, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _storePlaceholder())
                        : _storePlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_store!['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CColors.text)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 13, color: CColors.orange),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: CColors.muted)),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_rounded, size: 13, color: CColors.muted),
                      const SizedBox(width: 3),
                      Expanded(child: Text(_store!['type'] ?? '', style: const TextStyle(fontSize: 12, color: CColors.muted), overflow: TextOverflow.ellipsis)),
                    ]),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: CColors.muted, size: 20),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Re-roll buttons
          Row(children: [
            Expanded(
              child: _RerollBtn(
                icon: Icons.restaurant_menu_rounded,
                label: 'เปลี่ยนเมนู',
                onTap: _changeMenu,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RerollBtn(
                icon: Icons.store_rounded,
                label: 'เปลี่ยนร้าน',
                onTap: _changeStore,
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: GestureDetector(
        onTap: _goToStore,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: CColors.orange,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: CColors.orange.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('ดูเมนูและสั่งอาหาร', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ]),
        ),
      ),
    );
  }

  Widget _foodPlaceholder() => Container(
    color: CColors.orangeLight,
    child: const Center(child: Icon(Icons.fastfood_rounded, color: CColors.orange, size: 56)),
  );

  Widget _storePlaceholder() => Container(
    width: 44, height: 44,
    color: CColors.orangeLight,
    child: const Icon(Icons.store_rounded, color: CColors.orange, size: 22),
  );
}

class _RerollBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RerollBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: CColors.orange, size: 17),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.text)),
      ]),
    ),
  );
}
