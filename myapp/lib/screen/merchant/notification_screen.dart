import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import 'orders_screen.dart';

class MerchantNotificationScreen extends StatefulWidget {
  const MerchantNotificationScreen({super.key});

  @override
  State<MerchantNotificationScreen> createState() => _MerchantNotificationScreenState();
}

class _MerchantNotificationScreenState extends State<MerchantNotificationScreen> {
  List<Order> _orders = [];
  bool _loading = true;

  static const _notifLabel = {
    'pending':    'ออเดอร์ใหม่ รอการยืนยัน',
    'accepted':   'รับออเดอร์แล้ว กำลังเตรียม',
    'preparing':  'กำลังทำอาหาร',
    'ready':      'อาหารพร้อม รอไรเดอร์',
    'delivering': 'ไรเดอร์รับอาหารแล้ว',
    'completed':  'ส่งอาหารสำเร็จ',
    'cancelled':  'ออเดอร์ถูกยกเลิก',
  };

  static const _notifIcon = {
    'pending':    Icons.notifications_active_rounded,
    'accepted':   Icons.check_circle_outline_rounded,
    'preparing':  Icons.restaurant_rounded,
    'ready':      Icons.inventory_2_rounded,
    'delivering': Icons.delivery_dining_rounded,
    'completed':  Icons.sentiment_satisfied_alt_rounded,
    'cancelled':  Icons.cancel_outlined,
  };

  static const _notifColor = {
    'pending':    Color(0xFFFFA000),
    'accepted':   AppColors.orange,
    'preparing':  AppColors.orange,
    'ready':      AppColors.orange,
    'delivering': AppColors.orange,
    'completed':  AppColors.green,
    'cancelled':  AppColors.muted,
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await ApiService.getOrders(status: 'all');
      if (!mounted) return;
      setState(() { _orders = orders; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final pending = _orders.where((o) => o.status == 'pending').toList();
    final others = _orders.where((o) => o.status != 'pending').toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('การแจ้งเตือน', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppColors.text),
          ),
        ),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${_orders.length} รายการ', style: const TextStyle(fontSize: 13, color: AppColors.muted))),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _orders.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 80, height: 80, decoration: const BoxDecoration(color: AppColors.orangeLight, shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_none_rounded, color: AppColors.orange, size: 40)),
                    const SizedBox(height: 16),
                    const Text('ยังไม่มีการแจ้งเตือน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text)),
                  ]),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (pending.isNotEmpty) ...[
                      _SectionHeader(title: 'ต้องการยืนยัน', count: pending.length, urgent: true),
                      const SizedBox(height: 8),
                      ...pending.map((o) => _NotifCard(order: o, label: _notifLabel[o.status]!, icon: _notifIcon[o.status]!, color: _notifColor[o.status]!, timeAgo: _timeAgo(o.createdAt), onTap: () => _openDetail(o))),
                      const SizedBox(height: 16),
                    ],
                    if (others.isNotEmpty) ...[
                      _SectionHeader(title: 'ออเดอร์ล่าสุด', count: others.length, urgent: false),
                      const SizedBox(height: 8),
                      ...others.map((o) => _NotifCard(order: o, label: _notifLabel[o.status] ?? o.status, icon: _notifIcon[o.status] ?? Icons.info_outline, color: _notifColor[o.status] ?? AppColors.muted, timeAgo: _timeAgo(o.createdAt), onTap: () => _openDetail(o))),
                    ],
                  ],
                ),
    );
  }

  void _openDetail(Order order) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => OrderDetailScreen(orderId: order.id),
    )).then((_) => _load());
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool urgent;
  const _SectionHeader({required this.title, required this.count, required this.urgent});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (urgent)
        Container(
          width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
          decoration: const BoxDecoration(color: Color(0xFFFFA000), shape: BoxShape.circle),
        ),
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: urgent ? const Color(0xFFFFF3CD) : AppColors.orangeLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: urgent ? const Color(0xFFFFA000) : AppColors.orange)),
      ),
    ]);
  }
}

class _NotifCard extends StatelessWidget {
  final Order order;
  final String label;
  final IconData icon;
  final Color color;
  final String timeAgo;
  final VoidCallback onTap;

  const _NotifCard({
    required this.order,
    required this.label,
    required this.icon,
    required this.color,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final isUrgent = order.status == 'pending';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isUrgent ? Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.4), width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('#${order.id} · ${order.customerName}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text))),
              Text(timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Row(children: [
              Expanded(child: Text(order.itemsSummary ?? '', style: const TextStyle(fontSize: 11, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('฿${fmt.format(order.totalAmount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.orange)),
            ]),
          ])),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 18),
        ]),
      ),
    );
  }
}
