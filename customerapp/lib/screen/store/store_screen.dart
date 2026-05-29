import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../utils/responsive.dart';
import '../../cart_manager.dart';
import '../../services/customer_service.dart';
import '../location/location_picker_screen.dart';
import '../order/payment_screen.dart';
import '../profile/favorites_screen.dart';
import '../chat/review_screen.dart';

class StoreScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  final String customerId;
  final String customerName;
  final String customerPhone;
  const StoreScreen({super.key, required this.store, required this.customerId, required this.customerName, required this.customerPhone});
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _promos = [];
  Map<int, int> _cart = {};
  bool _loading = true;
  int _selectedCat = -1;
  Timer? _refreshTimer;
  final _cartBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      CustomerService.getMenu(widget.store['id']),
      CustomerService.getActivePromos(widget.store['id']),
    ]);
    if (!mounted) return;
    final data = results[0] as Map<String, dynamic>?;
    final promos = results[1] as List<Map<String, dynamic>>;
    if (data == null) return;

    final newCategories = List<Map<String, dynamic>>.from(data['categories'] ?? []);
    final newItems     = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final newStoreId   = widget.store['id']?.toString() ?? '';
    final cart         = CartManager.instance;

    // Check if there's an existing cart from a DIFFERENT store
    final hasConflict = !cart.isEmpty && cart.storeId != null && cart.storeId != newStoreId;
    final conflictName = cart.storeName ?? 'ร้านอื่น';

    // Restore cart items if user is re-visiting the same store
    final restoredCart = (!cart.isEmpty && cart.storeId == newStoreId) ? cart.items : <int, int>{};

    setState(() {
      _categories = newCategories;
      _items      = newItems;
      _promos     = promos;
      _cart       = restoredCart;
      _loading    = false;
    });

    if (!hasConflict) {
      cart.syncMenu(widget.store, newItems, promos);
      return;
    }

    // Show dialog AFTER the frame so the screen is visible
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('เปลี่ยนร้านอาหาร?',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Text(
            'มีสินค้าจากร้าน "$conflictName" อยู่ในตะกร้า\n'
            'ต้องการล้างตะกร้าเพื่อสั่งจากร้านนี้แทนไหม?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ย้อนกลับ', style: TextStyle(color: CColors.muted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: CColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('เปลี่ยนร้าน'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirm != true) {
        Navigator.pop(context);
        return;
      }
      cart.clear();
      cart.syncMenu(widget.store, newItems, promos);
      setState(() => _cart = {});
    });
  }

  Future<void> _silentRefresh() async {
    final data = await CustomerService.getMenu(widget.store['id']);
    if (!mounted || data == null) return;
    final newItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
    setState(() { _items = newItems; });
    if (CartManager.instance.storeId == widget.store['id']?.toString()) {
      CartManager.instance.syncMenu(widget.store, newItems, _promos);
    }
  }

  void _setCartQty(int id, int qty) {
    setState(() {
      if (qty <= 0) { _cart.remove(id); } else { _cart[id] = qty; }
    });
    CartManager.instance.setItem(id, qty);
  }

  void _addWithAnimation(int id, BuildContext btnCtx) {
    _setCartQty(id, (_cart[id] ?? 0) + 1);

    final cartCtx = _cartBtnKey.currentContext;
    if (cartCtx == null || !btnCtx.mounted) return;

    final btnBox  = btnCtx.findRenderObject() as RenderBox?;
    final cartBox = cartCtx.findRenderObject() as RenderBox?;
    if (btnBox == null || cartBox == null) return;

    final from = btnBox.localToGlobal(btnBox.size.center(Offset.zero));
    final to   = cartBox.localToGlobal(cartBox.size.center(Offset.zero));

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _CartFlyDot(
      from: from, to: to,
      onDone: () => entry.remove(),
    ));
    overlay.insert(entry);
  }

  List<Map<String, dynamic>> get _filteredItems => _selectedCat == -1
      ? _items.where((i) => i['is_available'] == 1).toList()
      : _items.where((i) => i['category_id'] == _selectedCat && i['is_available'] == 1).toList();

  int get _cartTotal => _cart.entries.fold(0, (sum, e) {
    final item = _items.firstWhere((i) => i['id'] == e.key, orElse: () => {});
    if (item.isEmpty) return sum;
    return sum + (double.tryParse(item['price'].toString()) ?? 0).round() * e.value;
  });

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  void _showStoreMenu() {
    final storeId = widget.store['id']?.toString() ?? '';
    final isFav = FavoritesManager.isFav(storeId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          _SheetOption(
            icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            iconColor: isFav ? Colors.red : CColors.orange,
            label: isFav ? 'ลบออกจากร้านโปรด' : 'เพิ่มเป็นร้านโปรด',
            onTap: () {
              FavoritesManager.toggle(storeId);
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(FavoritesManager.isFav(storeId) ? 'เพิ่มร้านโปรดแล้ว' : 'ลบออกจากร้านโปรดแล้ว'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _SheetOption(
            icon: Icons.share_rounded,
            iconColor: CColors.orange,
            label: 'แชร์ร้านนี้',
            onTap: () {
              final name    = widget.store['name'] ?? '';
              final address = widget.store['address'] ?? '';
              Clipboard.setData(ClipboardData(text: '$name\n$address'));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('คัดลอกข้อมูลร้านแล้ว'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _SheetOption(
            icon: Icons.rate_review_rounded,
            iconColor: CColors.orange,
            label: 'รีวิวร้านนี้',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ReviewScreen(
                  orderId: '',
                  customerId: widget.customerId,
                  customerName: widget.customerName,
                  storeId: widget.store['id']?.toString() ?? '',
                  storeName: widget.store['name']?.toString() ?? '',
                ),
              ));
            },
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _SheetOption(
            icon: Icons.flag_rounded,
            iconColor: CColors.orange,
            label: 'รายงานปัญหา',
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('รายงานปัญหา', style: TextStyle(fontWeight: FontWeight.w700)),
                  content: const Text('ขอบคุณที่แจ้งปัญหา\nทีมงานจะตรวจสอบและดำเนินการโดยเร็ว'),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CColors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('ตกลง'),
                    ),
                  ],
                ),
              );
            },
          ),
        ]),
      ),
    );
  }

  void _showNutrition(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NutritionSheet(
        item: item,
        storeName: widget.store['name'] ?? '',
        onAddToCart: () {
          _setCartQty(item['id'], (_cart[item['id']] ?? 0) + 1);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openCart() {
    final cartItems = _cart.entries.map((e) {
      final item = _items.firstWhere((i) => i['id'] == e.key);
      return {...item, 'qty': e.value};
    }).toList();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartSheet(
        items: cartItems,
        store: widget.store,
        customerId: widget.customerId,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        promos: _promos,
        onUpdate: (id, qty) => _setCartQty(id, qty),
        onOrderPlaced: () {
          setState(() => _cart.clear());
          CartManager.instance.clear();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final rating = double.tryParse(widget.store['rating']?.toString() ?? '0') ?? 0;
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: CColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(16)),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: context.wp(38), height: context.wp(38),
                decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                child: Icon(Icons.chevron_left_rounded, color: CColors.text, size: context.wp(22)),
              ),
            ),
            const Spacer(),
            Text(widget.store['name'] ?? 'Restaurant',
                style: TextStyle(fontSize: context.sp(17), fontWeight: FontWeight.w700, color: CColors.text)),
            const Spacer(),
            GestureDetector(
              onTap: _showStoreMenu,
              child: Container(
                width: context.wp(38), height: context.wp(38),
                decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                child: Icon(Icons.more_horiz_rounded, color: CColors.text, size: context.wp(20)),
              ),
            ),
          ]),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: CColors.orange))
          : Stack(children: [
              CustomScrollView(
                slivers: [
                  // Hero image
                  SliverToBoxAdapter(
                    child: Stack(children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(context.wp(16), context.wp(8), context.wp(16), 0),
                        height: context.wp(160),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: widget.store['image_url'] != null
                              ? Image.network(widget.store['image_url'], fit: BoxFit.cover, width: double.infinity,
                                  errorBuilder: (_, e, s) => Container(color: CColors.orangeLight,
                                    child: const Center(child: Icon(Icons.restaurant_rounded, color: CColors.orange, size: 56))))
                              : Container(color: CColors.orangeLight,
                                  child: const Center(child: Icon(Icons.restaurant_rounded, color: CColors.orange, size: 56))),
                        ),
                      ),
                    ]),
                  ),

                  // Store info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(context.wp(16), context.wp(12), context.wp(16), 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text(widget.store['name'] ?? '',
                              style: TextStyle(fontSize: context.sp(18), fontWeight: FontWeight.w800, color: CColors.text)),
                          ),
                        ]),
                        SizedBox(height: context.wp(6)),
                        Row(children: [
                          Icon(Icons.star_rounded, color: CColors.orange, size: context.wp(15)),
                          SizedBox(width: context.wp(3)),
                          Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: context.sp(13), fontWeight: FontWeight.w600, color: CColors.text)),
                          SizedBox(width: context.wp(12)),
                          Icon(Icons.delivery_dining_rounded, color: CColors.orange, size: context.wp(15)),
                          SizedBox(width: context.wp(3)),
                          Text('ส่งฟรี', style: TextStyle(fontSize: context.sp(13), color: CColors.muted)),
                          SizedBox(width: context.wp(12)),
                          Icon(Icons.access_time_rounded, color: CColors.orange, size: context.wp(15)),
                          SizedBox(width: context.wp(3)),
                          Text('30 นาที', style: TextStyle(fontSize: context.sp(13), color: CColors.muted)),
                          SizedBox(width: context.wp(12)),
                          Expanded(
                            child: Text(widget.store['address'] ?? '',
                              style: TextStyle(fontSize: context.sp(12), color: CColors.muted),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        SizedBox(height: context.wp(10)),
                      ]),
                    ),
                  ),

                  // Active promos banner
                  if (_promos.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Column(
                          children: _promos.map((p) => _PromoBanner(promo: p)).toList(),
                        ),
                      ),
                    ),

                  // Category chips sticky
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CatHeaderDelegate(
                      categories: _categories,
                      selected: _selectedCat,
                      onSelect: (id) => setState(() => _selectedCat = id),
                    ),
                  ),

                  // Section title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(context.wp(16), context.wp(8), context.wp(16), context.wp(6)),
                      child: Text(
                        _selectedCat == -1
                            ? 'เมนูทั้งหมด (${_filteredItems.length})'
                            : '${_categories.firstWhere((c) => c['id'] == _selectedCat, orElse: () => {'name': ''})['name']} (${_filteredItems.length})',
                        style: TextStyle(fontSize: context.sp(16), fontWeight: FontWeight.w800, color: CColors.text),
                      ),
                    ),
                  ),

                  // Food grid
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(context.wp(16), 0, context.wp(16), context.wp(110)),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 0.72,
                        crossAxisSpacing: context.wp(12), mainAxisSpacing: context.wp(12),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _MenuGridCard(
                          item: _filteredItems[i],
                          storeName: widget.store['name'] ?? '',
                          qty: _cart[_filteredItems[i]['id']] ?? 0,
                          onAdd: (btnCtx) {
                            _addWithAnimation(_filteredItems[i]['id'], btnCtx);
                          },
                          onRemove: () {
                            final id = _filteredItems[i]['id'];
                            _setCartQty(id, (_cart[id] ?? 1) - 1);
                          },
                          onNutritionTap: () => _showNutrition(_filteredItems[i]),
                          fmt: fmt,
                        ),
                        childCount: _filteredItems.length,
                      ),
                    ),
                  ),
                ],
              ),

              // Floating cart button
              if (_cartCount > 0)
                Positioned(
                  bottom: context.wp(24), left: context.wp(20), right: context.wp(20),
                  child: GestureDetector(
                    onTap: _openCart,
                    child: Container(
                      key: _cartBtnKey,
                      padding: EdgeInsets.symmetric(horizontal: context.wp(20), vertical: context.wp(16)),
                      decoration: BoxDecoration(
                        color: CColors.orange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: CColors.orange.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Row(children: [
                        Container(
                          width: context.wp(28), height: context.wp(28),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text('$_cartCount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: context.sp(13)))),
                        ),
                        SizedBox(width: context.wp(12)),
                        Expanded(child: Text('ดูตะกร้า', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: context.sp(16)))),
                        Text('฿${fmt.format(_cartTotal)}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: context.sp(16))),
                      ]),
                    ),
                  ),
                ),
            ]),
    );
  }
}

class _PromoBanner extends StatefulWidget {
  final Map<String, dynamic> promo;
  const _PromoBanner({required this.promo});

  @override
  State<_PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) _calc(); });
  }

  void _calc() {
    final endsAt = DateTime.tryParse(widget.promo['ends_at']?.toString() ?? '');
    final diff = endsAt != null ? endsAt.difference(DateTime.now()) : Duration.zero;
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String get _discLabel {
    final type  = widget.promo['discount_type'] as String? ?? '';
    final value = double.tryParse(widget.promo['discount_value']?.toString() ?? '0') ?? 0;
    if (type == 'percentage') return 'ลด ${value.toStringAsFixed(0)}%';
    if (type == 'fixed')      return 'ลด ฿${value.toStringAsFixed(0)}';
    return 'ส่งฟรี';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.promo['title'] as String? ?? 'โปรโมชั่นพิเศษ';
    final desc  = widget.promo['description'] as String? ?? '';
    final m = _remaining.inMinutes.toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFFF8C00).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        const Icon(Icons.local_offer_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20)),
                child: Text(_discLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ]),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.timer_rounded, color: Colors.white, size: 13),
              const SizedBox(width: 4),
              Text('หมดเวลาใน $m:$s', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _CatHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<Map<String, dynamic>> categories;
  final int selected;
  final ValueChanged<int> onSelect;
  const _CatHeaderDelegate({required this.categories, required this.selected, required this.onSelect});

  @override double get minExtent => 56;
  @override double get maxExtent => 56;
  @override bool shouldRebuild(_) => true;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: CColors.bg,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _CatChip(label: 'ทั้งหมด', selected: selected == -1, onTap: () => onSelect(-1)),
          ...categories.map((c) => _CatChip(label: c['name'], selected: selected == c['id'], onTap: () => onSelect(c['id']))),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? CColors.orange : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: selected ? CColors.orange : const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF424242),
        )),
      ),
    );
  }
}

class _MenuGridCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String storeName;
  final int qty;
  final Function(BuildContext) onAdd;
  final VoidCallback onRemove;
  final VoidCallback onNutritionTap;
  final NumberFormat fmt;
  const _MenuGridCard({required this.item, required this.storeName, required this.qty, required this.onAdd, required this.onRemove, required this.onNutritionTap, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(item['price'].toString()) ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(fit: StackFit.expand, children: [
              item['image_url'] != null
                  ? Image.network(item['image_url'], fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(color: CColors.orangeLight,
                        child: const Center(child: Icon(Icons.fastfood_rounded, color: CColors.orange, size: 36))))
                  : Container(color: CColors.orangeLight,
                      child: const Center(child: Icon(Icons.fastfood_rounded, color: CColors.orange, size: 36))),
              Positioned(
                top: 8, left: 8,
                child: GestureDetector(
                  onTap: onNutritionTap,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: CColors.orange, size: 15),
                  ),
                ),
              ),
              if (qty > 0)
                Positioned(top: 8, right: 8,
                  child: Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
                    child: Center(child: Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                  )),
            ]),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.wp(10), context.wp(8), context.wp(10), context.wp(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['name'] ?? '',
                  style: TextStyle(fontSize: context.sp(13), fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(storeName,
                  style: TextStyle(fontSize: context.sp(11), color: CColors.muted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
              Row(children: [
                Text('฿${fmt.format(price)}',
                  style: TextStyle(fontSize: context.sp(14), fontWeight: FontWeight.w800, color: const Color(0xFF1A1A1A))),
                const Spacer(),
                if (qty == 0)
                  Builder(builder: (btnCtx) => GestureDetector(
                    onTap: () => onAdd(btnCtx),
                    child: Container(width: context.wp(30), height: context.wp(30),
                      decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
                      child: Icon(Icons.add_rounded, color: Colors.white, size: context.wp(18))),
                  ))
                else
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    GestureDetector(onTap: onRemove, child: Container(width: context.wp(26), height: context.wp(26), decoration: BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle), child: Icon(Icons.remove_rounded, color: CColors.orange, size: context.wp(14)))),
                    SizedBox(width: context.wp(22), child: Center(child: Text('$qty', style: TextStyle(fontSize: context.sp(13), fontWeight: FontWeight.w700)))),
                    Builder(builder: (btnCtx) => GestureDetector(onTap: () => onAdd(btnCtx), child: Container(width: context.wp(26), height: context.wp(26), decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle), child: Icon(Icons.add_rounded, color: Colors.white, size: context.wp(14))))),
                  ]),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _CartSheet extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> store;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<Map<String, dynamic>> promos;
  final Function(int id, int qty) onUpdate;
  final VoidCallback onOrderPlaced;
  const _CartSheet({required this.items, required this.store, required this.customerId, required this.customerName, required this.customerPhone, this.promos = const [], required this.onUpdate, required this.onOrderPlaced});
  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  final _noteCtrl = TextEditingController();
  late List<Map<String, dynamic>> _items;
  double? _deliveryLat;
  double? _deliveryLng;
  String? _deliveryAddress;
  bool _locationError = false;
  bool _splitEnabled = false;
  int _splitPeople = 2;

  @override
  void initState() { super.initState(); _items = List.from(widget.items); }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  int get _subtotal => _items.fold(0, (s, i) => s + (double.tryParse(i['price'].toString()) ?? 0).round() * (i['qty'] as int));

  Map<String, dynamic>? get _activePromo => widget.promos.isNotEmpty ? widget.promos.first : null;

  int get _discountAmount {
    final p = _activePromo;
    if (p == null) return 0;
    final type  = p['discount_type'] as String? ?? '';
    final value = double.tryParse(p['discount_value']?.toString() ?? '0') ?? 0;
    if (type == 'percentage')    return (_subtotal * value / 100).round();
    if (type == 'fixed')         return value.round().clamp(0, _subtotal);
    return 0;
  }

  int get _deliveryFee => _activePromo?['discount_type'] == 'free_delivery' ? 0 : 30;

  int get _total => (_subtotal - _discountAmount + _deliveryFee).clamp(0, 999999);
  int get _perPerson => (_total / _splitPeople).ceil();

  String get _discountLabel {
    final p = _activePromo;
    if (p == null) return 'ส่วนลด';
    final type  = p['discount_type'] as String? ?? '';
    final value = double.tryParse(p['discount_value']?.toString() ?? '0') ?? 0;
    if (type == 'percentage') return 'ส่วนลด ${value.toStringAsFixed(0)}%';
    if (type == 'fixed')      return 'ส่วนลด ฿${value.toStringAsFixed(0)}';
    return 'ส่งฟรี';
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: _deliveryLat != null
              ? LatLng(_deliveryLat!, _deliveryLng!)
              : null,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      setState(() {
        _deliveryLat = result['lat'] as double;
        _deliveryLng = result['lng'] as double;
        _deliveryAddress = result['address'] as String;
        _locationError = false;
      });
    }
  }

  void _goToPayment() {
    if (_deliveryLat == null) {
      setState(() => _locationError = true);
      return;
    }
    final orderItems = _items.map((i) => {
      'menu_item_id': i['id'], 'name': i['name'],
      'price': i['price'], 'quantity': i['qty'],
    }).toList();
    final promoId = _activePromo?['id'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: _total,
          customerId: widget.customerId,
          onConfirm: () async {
            final result = await CustomerService.placeOrder(
              customerId: widget.customerId,
              customerName: widget.customerName,
              customerPhone: widget.customerPhone,
              storeId: widget.store['id'],
              items: orderItems,
              address: _deliveryAddress ?? '',
              latitude: _deliveryLat,
              longitude: _deliveryLng,
              note: _noteCtrl.text.trim(),
              promoId: promoId,
            );
            if (result != null && result['success'] == true) {
              return result['order_id'] as String?;
            }
            return null;
          },
          onSuccess: () {
            widget.onOrderPlaced();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    return DraggableScrollableSheet(
      initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: CColors.orangeMid, borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
            Icon(Icons.shopping_basket_rounded, color: CColors.orange),
            SizedBox(width: 8),
            Text('ตะกร้าสินค้า', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CColors.text)),
          ])),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
              ..._items.map((item) => _CartItem(
                item: item, fmt: fmt,
                onAdd: () => setState(() { item['qty']++; widget.onUpdate(item['id'], item['qty']); }),
                onRemove: () => setState(() {
                  if (item['qty'] > 1) { item['qty']--; widget.onUpdate(item['id'], item['qty']); }
                  else { _items.remove(item); widget.onUpdate(item['id'], 0); }
                }),
              )),
              const SizedBox(height: 16),
              const Text('ที่อยู่จัดส่ง', style: CTextStyles.label),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickLocation,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _locationError ? const Color(0xFFFFEEEE) : CColors.orangeLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _locationError
                          ? Colors.red
                          : _deliveryLat != null
                              ? CColors.orange
                              : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: _deliveryLat == null
                      ? Row(children: [
                          const Icon(Icons.add_location_alt_rounded, color: CColors.orange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            _locationError ? 'กรุณาเลือกที่อยู่จัดส่ง' : 'แตะเพื่อปักหมุดที่อยู่จัดส่ง',
                            style: TextStyle(
                              fontSize: 14,
                              color: _locationError ? Colors.red : CColors.muted,
                            ),
                          )),
                        ])
                      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on_rounded, color: CColors.orange, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            _deliveryAddress ?? '',
                            style: const TextStyle(fontSize: 13, color: CColors.text, height: 1.5),
                            maxLines: 3, overflow: TextOverflow.ellipsis,
                          )),
                          const SizedBox(width: 8),
                          const Text('เปลี่ยน', style: TextStyle(fontSize: 12, color: CColors.orange, fontWeight: FontWeight.w600)),
                        ]),
                ),
              ),
              const SizedBox(height: 12),
              const Text('หมายเหตุ (ถ้ามี)', style: CTextStyles.label),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                style: const TextStyle(fontSize: 14, color: CColors.text),
                decoration: InputDecoration(
                  hintText: 'เช่น ไม่เผ็ด, เอาซอสเพิ่ม...',
                  hintStyle: const TextStyle(color: CColors.muted, fontSize: 14),
                  filled: true, fillColor: CColors.orangeLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CColors.orange, width: 1.5)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  _SummaryRow(label: 'ค่าอาหาร', value: '฿${fmt.format(_subtotal)}'),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 6),
                    _SummaryRow(label: _discountLabel, value: '-฿${fmt.format(_discountAmount)}', isDiscount: true),
                  ],
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'ค่าจัดส่ง', value: _deliveryFee == 0 ? 'ฟรี' : '฿$_deliveryFee'),
                  const Divider(height: 16, color: CColors.orangeMid),
                  _SummaryRow(label: 'รวมทั้งหมด', value: '฿${fmt.format(_total)}', bold: true),
                ]),
              ),
              const SizedBox(height: 12),
              // Split bill section
              Container(
                decoration: BoxDecoration(
                  color: CColors.orangeLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      const Icon(Icons.group_rounded, color: CColors.orange, size: 20),
                      const SizedBox(width: 8),
                      const Text('หารกับเพื่อน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CColors.text)),
                      const Spacer(),
                      Switch.adaptive(
                        value: _splitEnabled,
                        onChanged: (v) => setState(() => _splitEnabled = v),
                        activeThumbColor: CColors.orange,
                        activeTrackColor: CColors.orangeLight,
                      ),
                    ]),
                  ),
                  if (_splitEnabled) ...[
                    const Divider(height: 1, color: CColors.orangeMid),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(children: [
                        Row(children: [
                          const Text('จำนวนคน', style: TextStyle(fontSize: 13, color: CColors.muted, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () { if (_splitPeople > 2) setState(() => _splitPeople--); },
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.remove_rounded, color: CColors.orange, size: 16),
                            ),
                          ),
                          SizedBox(width: 40, child: Center(child: Text('$_splitPeople', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CColors.text)))),
                          GestureDetector(
                            onTap: () => setState(() => _splitPeople++),
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: CColors.orange, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Text('ตกคนละ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CColors.text)),
                            const Spacer(),
                            Text('฿${fmt.format(_perPerson)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: CColors.orange)),
                          ]),
                        ),
                      ]),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 20),
            ]),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _items.isEmpty ? null : _goToPayment,
                style: ElevatedButton.styleFrom(backgroundColor: CColors.orange, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text('เลือกการชำระเงิน ฿${fmt.format(_total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CartItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final NumberFormat fmt;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _CartItem({required this.item, required this.fmt, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(item['price'].toString()) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(child: Text(item['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CColors.text))),
        Row(children: [
          GestureDetector(onTap: onRemove, child: Container(width: 28, height: 28, decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove_rounded, color: CColors.orange, size: 16))),
          SizedBox(width: 28, child: Center(child: Text('${item['qty']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)))),
          GestureDetector(onTap: onAdd, child: Container(width: 28, height: 28, decoration: BoxDecoration(color: CColors.orange, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_rounded, color: Colors.white, size: 16))),
        ]),
        const SizedBox(width: 12),
        SizedBox(width: 64, child: Text('฿${fmt.format(price * item['qty'])}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CColors.orange))),
      ]),
    );
  }
}

// ─── Nutrition Sheet ─────────────────────────────────────────────────────────

class _NutritionSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final String storeName;
  final VoidCallback onAddToCart;
  const _NutritionSheet({required this.item, required this.storeName, required this.onAddToCart});
  @override
  State<_NutritionSheet> createState() => _NutritionSheetState();
}

class _NutritionSheetState extends State<_NutritionSheet> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final result = await CustomerService.getNutritionInfo(
      widget.item['name'] ?? '',
      storeName: widget.storeName,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result == null) {
        _error = 'ไม่สามารถโหลดข้อมูลได้ กรุณาลองใหม่';
      } else if (result['error'] != null) {
        _error = result['error'];
      } else {
        _data = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final price = double.tryParse(widget.item['price']?.toString() ?? '0') ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),

        // Food header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(children: [
            if (widget.item['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(widget.item['image_url'], width: 60, height: 60, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(width: 60, height: 60, decoration: const BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: const Icon(Icons.fastfood_rounded, color: CColors.orange, size: 28))),
              )
            else
              Container(width: 60, height: 60,
                decoration: const BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.all(Radius.circular(12))),
                child: const Icon(Icons.fastfood_rounded, color: CColors.orange, size: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.item['name'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: CColors.text)),
              const SizedBox(height: 2),
              Text(widget.storeName, style: const TextStyle(fontSize: 13, color: CColors.muted)),
              const SizedBox(height: 4),
              Text('฿${fmt.format(price)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CColors.orange)),
            ])),
          ]),
        ),

        const Divider(height: 1, color: Color(0xFFE0E0E0)),

        // Content
        Flexible(
          child: SingleChildScrollView(
            child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Column(children: [
                    CircularProgressIndicator(color: CColors.orange, strokeWidth: 3),
                    SizedBox(height: 16),
                    Text('AI กำลังวิเคราะห์โภชนาการ...', style: TextStyle(color: CColors.muted, fontSize: 13)),
                  ]),
                )
              : _error != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Column(children: [
                      Icon(Icons.error_rounded, color: Colors.red.shade400, size: 40),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: CColors.muted, fontSize: 13), textAlign: TextAlign.center),
                    ]),
                  )
                : _data != null
                  ? _buildNutrition(_data!)
                  : const SizedBox(),
          ),
        ),

        // Add to cart button
        Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: widget.onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: CColors.orange, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_shopping_cart_rounded, size: 20),
                SizedBox(width: 8),
                Text('เพิ่มลงตะกร้า', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildNutrition(Map<String, dynamic> d) {
    final calories = (d['calories'] as num?)?.toInt() ?? 0;
    final protein = (d['protein'] as num?)?.toDouble() ?? 0;
    final carbs = (d['carbs'] as num?)?.toDouble() ?? 0;
    final fat = (d['fat'] as num?)?.toDouble() ?? 0;
    final fiber = (d['fiber'] as num?)?.toDouble() ?? 0;
    final sodium = (d['sodium'] as num?)?.toInt() ?? 0;
    final score = (d['healthScore'] as num?)?.toInt() ?? 0;
    final total = protein + carbs + fat;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if ((d['description'] ?? '').toString().isNotEmpty)
          Text(d['description'], style: const TextStyle(fontSize: 13, color: CColors.muted, height: 1.4)),
        if ((d['servingSize'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.restaurant_rounded, size: 13, color: CColors.muted),
            const SizedBox(width: 4),
            Text(d['servingSize'], style: const TextStyle(fontSize: 12, color: CColors.muted)),
          ]),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _NumBox(label: 'แคลอรี่', value: '$calories', unit: 'kcal')),
          const SizedBox(width: 10),
          Expanded(child: _NumBox(label: 'Health Score', value: '$score', unit: '/ 10')),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(child: _MacroCol(label: 'โปรตีน', value: protein, total: total, color: CColors.orange)),
            _Divider(),
            Expanded(child: _MacroCol(label: 'คาร์บ', value: carbs, total: total, color: CColors.orange)),
            _Divider(),
            Expanded(child: _MacroCol(label: 'ไขมัน', value: fat, total: total, color: CColors.orange)),
            _Divider(),
            Expanded(child: _MacroCol(label: 'ใยอาหาร', value: fiber, total: total, color: CColors.orange)),
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.water_drop_rounded, size: 15, color: CColors.muted),
            const SizedBox(width: 6),
            const Text('โซเดียม', style: TextStyle(fontSize: 12, color: CColors.muted)),
            const Spacer(),
            Text('${sodium}mg', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CColors.text)),
          ]),
        ),
        if ((d['healthNote'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.tips_and_updates_rounded, color: CColors.muted, size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(d['healthNote'], style: const TextStyle(fontSize: 12, color: CColors.muted, height: 1.4))),
            ]),
          ),
        ],
        const SizedBox(height: 4),
      ]),
    );
  }
}

class _NumBox extends StatelessWidget {
  final String label, value, unit;
  const _NumBox({required this.label, required this.value, required this.unit});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: CColors.muted, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      RichText(text: TextSpan(children: [
        TextSpan(text: value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: CColors.text)),
        TextSpan(text: ' $unit', style: const TextStyle(fontSize: 11, color: CColors.muted, fontWeight: FontWeight.w500)),
      ])),
    ]),
  );
}

class _MacroCol extends StatelessWidget {
  final String label;
  final double value, total;
  final Color color;
  const _MacroCol({required this.label, required this.value, required this.total, required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Column(children: [
      Text('${value.toStringAsFixed(1)}g', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: CColors.muted)),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: pct, minHeight: 4,
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 40, color: const Color(0xFFE8E8E8), margin: const EdgeInsets.symmetric(horizontal: 6));
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool isDiscount;
  const _SummaryRow({required this.label, required this.value, this.bold = false, this.isDiscount = false});
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? CColors.text : CColors.muted);
    final valueColor = isDiscount ? const Color(0xFFD32F2F) : (bold ? CColors.orange : CColors.muted);
    return Row(children: [Text(label, style: style), const Spacer(), Text(value, style: style.copyWith(color: valueColor))]);
  }
}

// ─── Fly-to-cart animation ────────────────────────────────────────────────────

class _CartFlyDot extends StatefulWidget {
  final Offset from, to;
  final VoidCallback onDone;
  const _CartFlyDot({required this.from, required this.to, required this.onDone});
  @override
  State<_CartFlyDot> createState() => _CartFlyDotState();
}

class _CartFlyDotState extends State<_CartFlyDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _scale    = Tween<double>(begin: 1.0, end: 0.2).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)));
    _opacity  = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.75, 1.0)));
    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Offset _bezier(double t) {
    // Arc through a midpoint shifted upward
    final mid = Offset(
      (widget.from.dx + widget.to.dx) / 2,
      (widget.from.dy + widget.to.dy) / 2 - 80,
    );
    final u = 1 - t;
    return Offset(
      u * u * widget.from.dx + 2 * u * t * mid.dx + t * t * widget.to.dx,
      u * u * widget.from.dy + 2 * u * t * mid.dy + t * t * widget.to.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final pos = _bezier(_progress.value);
        return Positioned(
          left: pos.dx - 12,
          top:  pos.dy - 12,
          child: IgnorePointer(
            child: Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(
                    color: CColors.orange, shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fastfood_rounded, color: Colors.white, size: 12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _SheetOption({required this.icon, required this.iconColor, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: CColors.text)),
        const Spacer(),
        const Icon(Icons.chevron_right_rounded, color: CColors.muted, size: 20),
      ]),
    ),
  );
}
