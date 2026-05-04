import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _tabs = const [
    ('active', 'Active'),
    ('delivering', 'Delivery Queue'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _showTestOrderDialog() async {
    await showDialog(
      context: context,
      builder: (_) => const _TestOrderDialog(),
    );
    // After dialog closes, trigger refresh on active tab
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          title: const Text('Orders', style: TextStyle(fontWeight: FontWeight.w700)),
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _showTestOrderDialog,
                icon: const Icon(Icons.science_outlined, color: Colors.white, size: 18),
                label: const Text('Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: _tabs.map((t) => _OrderList(status: t.$1)).toList(),
        ),
      );
}

class _OrderList extends StatefulWidget {
  final String status;
  const _OrderList({required this.status});
  @override
  State<_OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<_OrderList> with AutomaticKeepAliveClientMixin {
  List<Order> _orders = [];
  bool _loading = true;
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) { if (mounted) _load(); });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await ApiService.getOrders(status: widget.status);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    if (_orders.isEmpty) {
      return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 56, color: AppColors.muted.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        const Text('No orders', style: TextStyle(color: AppColors.muted)),
      ]),
    );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _OrderCard(order: _orders[i], onRefresh: _load),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onRefresh;
  const _OrderCard({required this.order, required this.onRefresh});

  static const _statusColor = {
    'pending': Color(0xFFFFA000),
    'accepted': Color(0xFF1976D2),
    'preparing': Color(0xFFF5A623),
    'ready': Color(0xFF388E3C),
    'delivering': Color(0xFF7B1FA2),
    'completed': Color(0xFF388E3C),
    'cancelled': Color(0xFF757575),
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor[order.status] ?? Colors.grey;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)));
        onRefresh();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
          border: order.status == 'pending' ? Border.all(color: const Color(0xFFFFA000), width: 1.5) : null,
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Text('#${order.id}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(order.label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(DateFormat('HH:mm').format(order.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(order.customerName, style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w600)),
              ]),
              if (order.itemsSummary != null) ...[
                const SizedBox(height: 4),
                Text(order.itemsSummary!, style: const TextStyle(fontSize: 12, color: AppColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Text('฿${order.totalAmount.toStringAsFixed(0)} (+ delivery ฿${order.deliveryFee.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.orange))),
                if (order.next != null) _ActionButton(order: order, onDone: onRefresh),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final Order order;
  final VoidCallback onDone;
  const _ActionButton({required this.order, required this.onDone});
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _loading = false;
  static const _nextLabel = {
    'pending': 'Accept',
    'accepted': 'Start Cooking',
    'preparing': 'Finish',
    'ready': 'Start Delivery',
    'delivering': 'Done',
  };

  Future<void> _tap() async {
    final next = widget.order.next;
    if (next == null) return;
    setState(() => _loading = true);
    try {
      await ApiService.updateOrderStatus(widget.order.id, next);
      widget.onDone();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 34,
        child: ElevatedButton(
          onPressed: _loading ? null : _tap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: _loading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_nextLabel[widget.order.status] ?? 'Update', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
}

// ─── Order Detail ─────────────────────────────────────────────────────────────

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final o = await ApiService.getOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = o;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await ApiService.updateOrderStatus(widget.orderId, status);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        title: Text(_order == null ? 'Order' : '#${_order!.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _order == null
              ? const Center(child: Text('Order not found'))
              : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final o = _order!;
    final timeline = ['pending', 'accepted', 'preparing', 'ready', 'delivering', 'completed'];
    final statusLabels = Order.statusLabel;
    final currentIdx = timeline.indexOf(o.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _InfoCard(children: [
          _Row(icon: Icons.person_outline, label: 'Customer', value: o.customerName),
          if (o.customerPhone != null) _Row(icon: Icons.phone_outlined, label: 'Phone', value: o.customerPhone!),
          if (o.address != null) _Row(icon: Icons.location_on_outlined, label: 'Address', value: o.address!),
          if (o.note != null && o.note!.isNotEmpty) _Row(icon: Icons.note_outlined, label: 'Note', value: o.note!),
        ]),
        const SizedBox(height: 14),
        _InfoCard(children: [
          const Text('Order Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
          const SizedBox(height: 10),
          ...o.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Expanded(child: Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: 13, color: AppColors.text))),
                  Text('฿${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
                ]),
              )),
          const Divider(height: 16),
          Row(children: [
            const Expanded(child: Text('Delivery fee', style: TextStyle(fontSize: 13, color: AppColors.muted))),
            Text('฿${o.deliveryFee.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.muted)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text))),
            Text('฿${o.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.orange)),
          ]),
        ]),
        const SizedBox(height: 14),
        if (o.status != 'completed' && o.status != 'cancelled') ...[
          _InfoCard(children: [
            const Text('Order Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
            const SizedBox(height: 14),
            ...List.generate(timeline.length - 1, (i) {
              final done = i < currentIdx;
              final active = i == currentIdx;
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: done || active ? AppColors.orange : AppColors.orangeMid),
                    child: done
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : active
                            ? const Icon(Icons.radio_button_checked, size: 12, color: Colors.white)
                            : null,
                  ),
                  if (i < timeline.length - 2) Container(width: 2, height: 28, color: done ? AppColors.orange : AppColors.orangeMid),
                ]),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    statusLabels[timeline[i]] ?? timeline[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? AppColors.orange : done ? AppColors.text : AppColors.muted,
                    ),
                  ),
                ),
              ]);
            }),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            if (o.status == 'pending')
              Expanded(child: OutlinedButton(
                onPressed: () => _updateStatus('cancelled'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Reject', style: TextStyle(color: Colors.red)),
              )),
            if (o.status == 'pending') const SizedBox(width: 10),
            if (o.next != null)
              Expanded(child: ElevatedButton(
                onPressed: () => _updateStatus(o.next!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  o.status == 'pending' ? 'Accept Order' : 'Update Status',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )),
          ]),
        ],
        if (o.status == 'cancelled')
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              Icon(Icons.cancel_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Order Cancelled', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ]),
          ),
        if (o.status == 'completed')
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Order Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            ]),
          ),
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500))),
        ]),
      );
}

// ─── Test Order Dialog ────────────────────────────────────────────────────────

class _TestOrderDialog extends StatefulWidget {
  const _TestOrderDialog();
  @override
  State<_TestOrderDialog> createState() => _TestOrderDialogState();
}

class _TestOrderDialogState extends State<_TestOrderDialog> {
  List<Map<String, dynamic>> _menuItems = [];
  final Map<int, int> _quantities = {}; // menuItemId -> qty
  bool _loading = true;
  bool _sending = false;
  String? _successMsg;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final data = await ApiService.getMenu();
      if (!mounted) return;
      final items = data['items'] as List;
      setState(() {
        _menuItems = items.cast<dynamic>().map((e) => {
          'id': (e as dynamic).id,
          'name': e.name,
          'price': e.price,
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _selectedItems => _menuItems
      .where((m) => (_quantities[m['id']] ?? 0) > 0)
      .map((m) => {
            'menu_item_id': m['id'],
            'name': m['name'],
            'price': m['price'],
            'quantity': _quantities[m['id']]!,
          })
      .toList();

  Future<void> _submit() async {
    final items = _selectedItems;
    if (items.isEmpty) return;
    setState(() => _sending = true);
    try {
      final res = await ApiService.createTestOrder(items);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _successMsg = '✅ สร้าง Order #${res['order_id']} สำเร็จ!';
        _quantities.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _selectedItems.fold<double>(0, (s, i) => s + (i['price'] as double) * (i['quantity'] as int));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(children: [
              const Icon(Icons.science_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('สร้าง Test Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),

          if (_successMsg != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Text(_successMsg!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF43A047))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _successMsg = null),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('สร้างอีกอัน'),
                ),
              ]),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.orange),
            )
          else ...[
            // Menu list
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _menuItems.length,
                itemBuilder: (_, i) {
                  final item = _menuItems[i];
                  final qty = _quantities[item['id']] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: qty > 0 ? AppColors.orangeLight : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                      border: qty > 0 ? Border.all(color: AppColors.orange, width: 1.5) : null,
                    ),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fastfood_rounded, color: AppColors.orange, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('฿${(item['price'] as double).toStringAsFixed(0)}', style: const TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      Row(children: [
                        _QtyBtn(icon: Icons.remove, onTap: qty > 0 ? () => setState(() => _quantities[item['id']] = qty - 1) : null),
                        SizedBox(width: 28, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                        _QtyBtn(icon: Icons.add, onTap: () => setState(() => _quantities[item['id']] = qty + 1)),
                      ]),
                    ]),
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('ยอดรวม', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    Text('฿${(total + 30).toStringAsFixed(0)} (รวม delivery ฿30)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.orange)),
                  ]),
                ),
                ElevatedButton(
                  onPressed: (_sending || _selectedItems.isEmpty) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('สร้าง Order', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: onTap != null ? AppColors.orange : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      );
}
