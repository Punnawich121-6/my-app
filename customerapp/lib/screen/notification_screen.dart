import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/customer_service.dart';
import 'order_tracking_screen.dart';

class NotificationScreen extends StatefulWidget {
  final int customerId;
  const NotificationScreen({super.key, required this.customerId});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  static const _statusLabel = {
    'pending': 'รอร้านอาหารยืนยัน',
    'accepted': 'ร้านอาหารรับออเดอร์แล้ว',
    'preparing': 'กำลังเตรียมอาหารให้คุณ',
    'ready': 'อาหารพร้อม รอไรเดอร์มารับ',
    'delivering': 'ไรเดอร์กำลังนำอาหารมาส่ง!',
    'completed': 'ส่งอาหารเรียบร้อยแล้ว',
    'cancelled': 'ออเดอร์ถูกยกเลิก',
  };

  static const _statusIcon = {
    'pending': Icons.access_time_rounded,
    'accepted': Icons.check_circle_outline_rounded,
    'preparing': Icons.restaurant_rounded,
    'ready': Icons.inventory_2_rounded,
    'delivering': Icons.delivery_dining_rounded,
    'completed': Icons.sentiment_satisfied_alt_rounded,
    'cancelled': Icons.cancel_outlined,
  };

  static const _statusColor = {
    'pending': Color(0xFFFFA000),
    'accepted': CColors.orange,
    'preparing': CColors.orange,
    'ready': CColors.orange,
    'delivering': CColors.orange,
    'completed': CColors.green,
    'cancelled': CColors.muted,
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await CustomerService.getOrders(widget.customerId);
    if (!mounted) return;
    setState(() { _orders = orders; _loading = false; });
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: CColors.bg,
        elevation: 0,
        title: const Text('การแจ้งเตือน', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: CColors.text)),
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
          : _orders.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 80, height: 80, decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_none_rounded, color: CColors.orange, size: 40)),
                    const SizedBox(height: 16),
                    const Text('ยังไม่มีการแจ้งเตือน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CColors.text)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: CColors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final order = _orders[i];
                      final status = order['status'] ?? 'pending';
                      final color = _statusColor[status] ?? CColors.muted;
                      final isActive = !['completed', 'cancelled'].contains(status);
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(orderId: (order['id'] as num).toInt()),
                        )),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isActive ? Border.all(color: CColors.orange.withValues(alpha: 0.3), width: 1.5) : null,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                              child: Icon(_statusIcon[status] ?? Icons.info_outline, color: color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(order['store_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: CColors.text))),
                                Text(_timeAgo(order['created_at']), style: const TextStyle(fontSize: 11, color: CColors.muted)),
                              ]),
                              const SizedBox(height: 3),
                              Text(_statusLabel[status] ?? status, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(order['items_summary'] ?? '', style: const TextStyle(fontSize: 11, color: CColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right_rounded, color: CColors.muted, size: 18),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
