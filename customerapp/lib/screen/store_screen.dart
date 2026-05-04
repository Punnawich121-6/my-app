import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/customer_service.dart';

class StoreScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  final int customerId;
  final String customerName;
  final String customerPhone;
  const StoreScreen({super.key, required this.store, required this.customerId, required this.customerName, required this.customerPhone});
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _items = [];
  final Map<int, int> _cart = {};
  bool _loading = true;
  int _selectedCat = -1;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await CustomerService.getMenu(widget.store['id']);
    if (!mounted || data == null) return;
    setState(() {
      _categories = List<Map<String, dynamic>>.from(data['categories'] ?? []);
      _items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _loading = false;
    });
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
        onUpdate: (id, qty) => setState(() { if (qty == 0) { _cart.remove(id); } else { _cart[id] = qty; } }),
        onOrderPlaced: () { setState(() => _cart.clear()); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final rating = double.tryParse(widget.store['rating']?.toString() ?? '0') ?? 0;
    return Scaffold(
      backgroundColor: CColors.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: CColors.orange))
          : Stack(children: [
              CustomScrollView(
                slivers: [
                  // Hero image with back + more buttons
                  SliverToBoxAdapter(
                    child: Stack(children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 52, 16, 0),
                        height: 220,
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
                      Positioned(
                        top: 60, left: 28,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))]),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Color(0xFF1A1A1A)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 60, right: 28,
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))]),
                          child: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                    ]),
                  ),

                  // Store info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.star_outline_rounded, color: CColors.orange, size: 18),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CColors.text)),
                          const SizedBox(width: 18),
                          const Icon(Icons.delivery_dining_rounded, color: CColors.orange, size: 18),
                          const SizedBox(width: 4),
                          const Text('ส่งฟรี', style: TextStyle(fontSize: 14, color: CColors.text)),
                          const SizedBox(width: 18),
                          const Icon(Icons.access_time_rounded, color: CColors.orange, size: 18),
                          const SizedBox(width: 4),
                          const Text('30 นาที', style: TextStyle(fontSize: 14, color: CColors.text)),
                        ]),
                        const SizedBox(height: 12),
                        Text(widget.store['name'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: CColors.text)),
                        const SizedBox(height: 6),
                        Text(widget.store['address'] ?? '',
                          style: const TextStyle(fontSize: 14, color: CColors.muted, height: 1.5), maxLines: 3),
                        const SizedBox(height: 16),
                      ]),
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        _selectedCat == -1
                            ? 'เมนูทั้งหมด (${_filteredItems.length})'
                            : '${_categories.firstWhere((c) => c['id'] == _selectedCat, orElse: () => {'name': ''})['name']} (${_filteredItems.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CColors.text),
                      ),
                    ),
                  ),

                  // Food grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 0.72,
                        crossAxisSpacing: 12, mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _MenuGridCard(
                          item: _filteredItems[i],
                          storeName: widget.store['name'] ?? '',
                          qty: _cart[_filteredItems[i]['id']] ?? 0,
                          onAdd: () => setState(() => _cart[_filteredItems[i]['id']] = (_cart[_filteredItems[i]['id']] ?? 0) + 1),
                          onRemove: () => setState(() {
                            final id = _filteredItems[i]['id'];
                            if ((_cart[id] ?? 0) > 1) { _cart[id] = _cart[id]! - 1; } else { _cart.remove(id); }
                          }),
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
                  bottom: 24, left: 20, right: 20,
                  child: GestureDetector(
                    onTap: _openCart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: CColors.orange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: CColors.orange.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text('$_cartCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('ดูตะกร้า', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                        Text('฿${fmt.format(_cartTotal)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      ]),
                    ),
                  ),
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
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final NumberFormat fmt;
  const _MenuGridCard({required this.item, required this.storeName, required this.qty, required this.onAdd, required this.onRemove, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(item['price'].toString()) ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
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
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['name'] ?? '',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(storeName,
                  style: const TextStyle(fontSize: 11, color: CColors.muted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
              Row(children: [
                Text('฿${fmt.format(price)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                const Spacer(),
                if (qty == 0)
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(width: 30, height: 30,
                      decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
                  )
                else
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    GestureDetector(onTap: onRemove, child: Container(width: 26, height: 26, decoration: BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle), child: const Icon(Icons.remove_rounded, color: CColors.orange, size: 14))),
                    SizedBox(width: 22, child: Center(child: Text('$qty', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))),
                    GestureDetector(onTap: onAdd, child: Container(width: 26, height: 26, decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 14))),
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
  final int customerId;
  final String customerName;
  final String customerPhone;
  final Function(int id, int qty) onUpdate;
  final VoidCallback onOrderPlaced;
  const _CartSheet({required this.items, required this.store, required this.customerId, required this.customerName, required this.customerPhone, required this.onUpdate, required this.onOrderPlaced});
  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _placing = false;
  bool _addressError = false;
  late List<Map<String, dynamic>> _items;

  @override
  void initState() { super.initState(); _items = List.from(widget.items); }

  @override
  void dispose() { _addressCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  int get _subtotal => _items.fold(0, (s, i) => s + (double.tryParse(i['price'].toString()) ?? 0).round() * (i['qty'] as int));

  Future<void> _placeOrder() async {
    if (_addressCtrl.text.trim().isEmpty) {
      setState(() => _addressError = true);
      return;
    }
    setState(() => _placing = true);
    final result = await CustomerService.placeOrder(
      customerId: widget.customerId,
      customerName: widget.customerName,
      customerPhone: widget.customerPhone,
      storeId: widget.store['id'],
      items: _items.map((i) => {'menu_item_id': i['id'], 'name': i['name'], 'price': i['price'], 'quantity': i['qty']}).toList(),
      address: _addressCtrl.text.trim(),
      note: _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _placing = false);
    if (result != null && result['success'] == true) {
      widget.onOrderPlaced();
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64, height: 64, decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: CColors.orange, size: 36)),
            const SizedBox(height: 16),
            const Text('สั่งอาหารสำเร็จ!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CColors.text)),
            const SizedBox(height: 8),
            const Text('ร้านอาหารกำลังรับออเดอร์ของคุณ', style: TextStyle(color: CColors.muted)),
          ]),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: CColors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('ดูออเดอร์'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สั่งอาหารไม่สำเร็จ กรุณาลองใหม่')));
    }
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
              TextField(
                controller: _addressCtrl, maxLines: 2,
                style: const TextStyle(fontSize: 14, color: CColors.text),
                onChanged: (_) => setState(() => _addressError = false),
                decoration: InputDecoration(
                  hintText: 'บ้านเลขที่, ถนน, แขวง, เขต...',
                  hintStyle: const TextStyle(color: CColors.muted, fontSize: 14),
                  filled: true, fillColor: CColors.orangeLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _addressError ? Colors.red : CColors.orange, width: 1.5)),
                  errorText: _addressError ? 'กรุณากรอกที่อยู่จัดส่ง' : null,
                  contentPadding: const EdgeInsets.all(14),
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
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'ค่าจัดส่ง', value: '฿30'),
                  const Divider(height: 16, color: CColors.orangeMid),
                  _SummaryRow(label: 'รวมทั้งหมด', value: '฿${fmt.format(_subtotal + 30)}', bold: true),
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
                onPressed: (_placing || _items.isEmpty) ? null : _placeOrder,
                style: ElevatedButton.styleFrom(backgroundColor: CColors.orange, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _placing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('สั่งอาหาร ฿${fmt.format(_subtotal + 30)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow({required this.label, required this.value, this.bold = false});
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? CColors.text : CColors.muted);
    return Row(children: [Text(label, style: style), const Spacer(), Text(value, style: style.copyWith(color: bold ? CColors.orange : CColors.muted))]);
  }
}
