import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/customer_service.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  final int customerId;
  const OrdersScreen({super.key, required this.customerId});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await CustomerService.getOrders(widget.customerId);
    if (!mounted) return;
    setState(() { _orders = orders; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('ออเดอร์ของฉัน', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: CColors.text)),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: CColors.orange))
                  : _orders.isEmpty
                      ? Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(width: 80, height: 80, decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
                                child: const Icon(Icons.receipt_long_rounded, color: CColors.orange, size: 40)),
                            const SizedBox(height: 16),
                            const Text('ยังไม่มีออเดอร์', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CColors.text)),
                            const SizedBox(height: 8),
                            const Text('สั่งอาหารแรกของคุณได้เลย!', style: TextStyle(color: CColors.muted)),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: CColors.orange,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) => _OrderCard(order: _orders[i], onTap: () => _showDetail(_orders[i]['id'])),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(int orderId) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => OrderTrackingScreen(orderId: orderId),
    ));
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  static const _statusLabel = {
    'pending': 'รอร้านรับ', 'accepted': 'ร้านรับแล้ว', 'preparing': 'กำลังทำ',
    'ready': 'พร้อมส่ง', 'delivering': 'กำลังส่ง', 'completed': 'ส่งแล้ว', 'cancelled': 'ยกเลิก',
  };
  static const _statusColor = {
    'pending': Color(0xFFFFA000), 'accepted': CColors.orange, 'preparing': CColors.orange,
    'ready': CColors.orange, 'delivering': CColors.orange, 'completed': CColors.green, 'cancelled': CColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0;
    final status = order['status'] ?? 'pending';
    final color = _statusColor[status] ?? CColors.muted;
    final date = DateTime.tryParse(order['created_at'] ?? '');
    final dateStr = date != null ? DateFormat('dd/MM/yy HH:mm').format(date) : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: CColors.orange.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.storefront_rounded, color: CColors.orange, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order['store_name'] ?? '-', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CColors.text)),
              Text(dateStr, style: const TextStyle(fontSize: 12, color: CColors.muted)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel[status] ?? status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: CColors.orangeLight),
          const SizedBox(height: 10),
          Text(order['items_summary'] ?? '-', style: const TextStyle(fontSize: 13, color: CColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [
            const Text('รวม', style: TextStyle(fontSize: 13, color: CColors.muted)),
            const Spacer(),
            Text('฿${fmt.format(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CColors.orange)),
          ]),
        ]),
      ),
    );
  }
}

