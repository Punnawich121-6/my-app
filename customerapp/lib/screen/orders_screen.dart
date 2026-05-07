import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/customer_service.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  final String customerId;
  const OrdersScreen({super.key, required this.customerId});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  Timer? _timer;
  late TabController _tab;

  static const _ongoingStatuses = {
    'pending', 'accepted', 'preparing', 'ready', 'delivering'
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this, initialIndex: 1);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final orders = await CustomerService.getOrders(widget.customerId);
    if (!mounted) return;
    setState(() { _orders = orders; _loading = false; });
  }

  List<Map<String, dynamic>> get _ongoing =>
      _orders.where((o) => _ongoingStatuses.contains(o['status'])).toList();

  List<Map<String, dynamic>> get _history =>
      _orders.where((o) => !_ongoingStatuses.contains(o['status'])).toList();

  void _goTracking(String orderId) => Navigator.push(
    context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      body: SafeArea(
        child: Column(children: [
          // ── AppBar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              _CircleBtn(icon: Icons.chevron_left_rounded, onTap: () {}),
              const Spacer(),
              const Text('My Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: CColors.text)),
              const Spacer(),
              _CircleBtn(icon: Icons.more_horiz_rounded, onTap: () {}),
            ]),
          ),

          // ── Tabs ──────────────────────────────────────────────────────
          TabBar(
            controller: _tab,
            labelColor: CColors.orange,
            unselectedLabelColor: CColors.muted,
            labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            indicatorColor: CColors.orange,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: const Color(0xFFEEEEEE),
            tabs: const [Tab(text: 'Ongoing'), Tab(text: 'History')],
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: CColors.orange))
                : TabBarView(
                    controller: _tab,
                    children: [
                      _OrderList(orders: _ongoing, onTap: _goTracking,
                          emptyMsg: 'ไม่มีออเดอร์ที่กำลังดำเนินการ', onRefresh: _load),
                      _OrderList(orders: _history, onTap: _goTracking,
                          emptyMsg: 'ยังไม่มีประวัติการสั่ง', onRefresh: _load),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─── Order List ───────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final Function(String) onTap;
  final String emptyMsg;
  final Future<void> Function() onRefresh;
  const _OrderList({
    required this.orders, required this.onTap,
    required this.emptyMsg, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: CColors.orange, size: 40),
          ),
          const SizedBox(height: 16),
          Text(emptyMsg,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CColors.text)),
          const SizedBox(height: 8),
          const Text('สั่งอาหารอร่อยๆ กันเถอะ!',
              style: TextStyle(color: CColors.muted, fontSize: 13)),
        ]),
      );
    }
    return RefreshIndicator(
      color: CColors.orange,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _OrderCard(
          order: orders[i],
          onTap: () => onTap(orders[i]['id'].toString()),
        ),
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  static const _statusLabel = {
    'pending': 'Pending', 'accepted': 'Accepted', 'preparing': 'Preparing',
    'ready': 'Ready', 'delivering': 'On the Way',
    'completed': 'Completed', 'cancelled': 'Cancelled',
  };

  Color _statusColor(String s) {
    if (s == 'completed') return CColors.green;
    if (s == 'cancelled') return CColors.red;
    return CColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0;
    final status = order['status'] as String? ?? 'pending';
    final sColor = _statusColor(status);
    final date = DateTime.tryParse(order['created_at'] ?? '');
    final dateStr = date != null ? DateFormat('dd MMM, HH:mm').format(date) : '';
    final summary = order['items_summary']?.toString() ?? '';
    final orderId = order['orderNumber']?.toString() ?? '#${order['id']?.toString().substring(0, 8).toUpperCase() ?? '------'}';
    final imageUrl = order['store_image']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Status header ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            const Text('Food',
                style: TextStyle(fontSize: 13, color: CColors.muted, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Text(_statusLabel[status] ?? status,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sColor)),
          ]),
        ),
        Container(height: 1, color: const Color(0xFFF5F5F5)),

        // ── Main row ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imageUrl != null
                  ? Image.network(imageUrl, width: 72, height: 72, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _Thumb())
                  : _Thumb(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(order['store_name'] ?? '-',
                        style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: CColors.text),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 6),
                  Text(orderId,
                      style: const TextStyle(fontSize: 11, color: CColors.muted)),
                ]),
                const SizedBox(height: 4),
                Text('฿${fmt.format(total)}',
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: CColors.text)),
                const SizedBox(height: 3),
                if (summary.isNotEmpty)
                  Text(summary,
                      style: const TextStyle(fontSize: 12, color: CColors.muted),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(dateStr,
                      style: const TextStyle(fontSize: 11, color: CColors.muted)),
                ],
              ]),
            ),
          ]),
        ),

        // ── Rate / Re-Order buttons ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CColors.orange,
                  side: const BorderSide(color: CColors.orange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Rate',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Re-Order',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Thumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 72, height: 72,
    color: CColors.orangeLight,
    child: const Center(child: Icon(Icons.restaurant_rounded, color: CColors.orange, size: 30)),
  );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
      child: Icon(icon, color: CColors.text, size: 22),
    ),
  );
}
