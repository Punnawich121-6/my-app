import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../l10n/strings.dart';
import '../../cart_manager.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;
  const CartScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
  });
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _items = CartManager.instance.cartItems;
  }

  int get _subtotal => _items.fold(0, (s, i) => s + (double.tryParse(i['price'].toString()) ?? 0).round() * (i['qty'] as int));

  Map<String, dynamic>? get _activePromo =>
      CartManager.instance.promos.isNotEmpty ? CartManager.instance.promos.first : null;

  int get _discountAmount {
    final p = _activePromo;
    if (p == null) return 0;
    final type = p['discount_type'] as String? ?? '';
    final value = double.tryParse(p['discount_value']?.toString() ?? '0') ?? 0;
    if (type == 'percentage') return (_subtotal * value / 100).round();
    if (type == 'fixed') return value.round().clamp(0, _subtotal);
    return 0;
  }

  int get _deliveryFee => _activePromo?['discount_type'] == 'free_delivery' ? 0 : 30;
  int get _total => (_subtotal - _discountAmount + _deliveryFee).clamp(0, 999999);

  String get _discountLabel {
    final p = _activePromo;
    if (p == null) return S.discountLabel;
    final type = p['discount_type'] as String? ?? '';
    final value = double.tryParse(p['discount_value']?.toString() ?? '0') ?? 0;
    if (type == 'percentage') return '${S.discountLabel} ${value.toStringAsFixed(0)}%';
    if (type == 'fixed') return '${S.discountLabel} ฿${value.toStringAsFixed(0)}';
    return S.freeDelivery;
  }

  void _updateItem(int id, int qty) {
    CartManager.instance.setItem(id, qty);
    setState(() {
      if (qty <= 0) {
        _items.removeWhere((i) => i['id'] == id);
      } else {
        final idx = _items.indexWhere((i) => i['id'] == id);
        if (idx != -1) _items[idx] = {..._items[idx], 'qty': qty};
      }
    });
  }

  void _proceedToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          customerId: widget.customerId,
          customerName: widget.customerName,
          customerPhone: widget.customerPhone,
          items: _items,
          subtotal: _subtotal,
          deliveryFee: _deliveryFee,
          discountAmount: _discountAmount,
          discountLabel: _discountLabel,
          total: _total,
          promoId: _activePromo?['id'],
          onSuccess: () {
            CartManager.instance.clear();
            setState(() => _items = []);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final cart = CartManager.instance;
    final storeName = cart.storeName ?? '';

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(S.myCart, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.fg)),
          if (storeName.isNotEmpty)
            Text(storeName, style: TextStyle(fontSize: 12, color: context.muted, fontWeight: FontWeight.w400)),
        ]),
        centerTitle: true,
      ),
      body: cart.isEmpty
          ? _EmptyCart()
          : Column(children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  children: [
                    ..._items.map((item) => _CartItemRow(
                      item: item,
                      fmt: fmt,
                      onAdd: () => _updateItem(item['id'], (item['qty'] as int) + 1),
                      onRemove: () => _updateItem(item['id'], (item['qty'] as int) - 1),
                    )),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: context.orangeLight, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        _SummaryRow(label: S.foodCost, value: '฿${fmt.format(_subtotal)}'),
                        if (_discountAmount > 0) ...[
                          const SizedBox(height: 6),
                          _SummaryRow(label: _discountLabel, value: '-฿${fmt.format(_discountAmount)}', isDiscount: true),
                        ],
                        const SizedBox(height: 6),
                        _SummaryRow(label: S.deliveryFee, value: _deliveryFee == 0 ? S.free : '฿$_deliveryFee'),
                        Divider(height: 16, color: CColors.orangeMid),
                        _SummaryRow(label: S.totalLabel, value: '฿${fmt.format(_total)}', bold: true),
                      ]),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: context.card,
                  boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, -4))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _items.isEmpty ? null : _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(S.proceedBtn(fmt.format(_total)),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(color: context.orangeLight, shape: BoxShape.circle),
        child: const Icon(Icons.shopping_basket_rounded, color: CColors.orange, size: 44),
      ),
      const SizedBox(height: 20),
      Text(S.emptyCart, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.fg)),
      const SizedBox(height: 8),
      Text(S.emptyCartSub, style: TextStyle(fontSize: 14, color: context.muted)),
    ]),
  );
}

class _CartItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final NumberFormat fmt;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _CartItemRow({required this.item, required this.fmt, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(item['price'].toString()) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(
          child: Text(item['name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.fg)),
        ),
        Row(children: [
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: context.orangeLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.remove_rounded, color: CColors.orange, size: 16),
            ),
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: Text('${item['qty']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.fg)),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: CColors.orange, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            ),
          ),
        ]),
        const SizedBox(width: 12),
        SizedBox(
          width: 64,
          child: Text('฿${fmt.format(price * (item['qty'] as int))}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CColors.orange)),
        ),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool isDiscount;
  const _SummaryRow({required this.label, required this.value, this.bold = false, this.isDiscount = false});
  @override
  Widget build(BuildContext context) {
    final baseColor = bold ? context.fg : context.muted;
    final style = TextStyle(
        fontSize: bold ? 15 : 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: baseColor);
    final valueColor = isDiscount ? const Color(0xFFD32F2F) : (bold ? CColors.orange : context.muted);
    return Row(children: [
      Text(label, style: style),
      const Spacer(),
      Text(value, style: style.copyWith(color: valueColor)),
    ]);
  }
}
