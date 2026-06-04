import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_settings.dart';
import '../../main.dart';
import '../../services/rider_service.dart';
import '../../services/rider_alert_service.dart';

class AvailableOrdersScreen extends StatefulWidget {
  final String riderId;
  final bool isOnline;
  final VoidCallback onOrderAccepted;

  const AvailableOrdersScreen({
    super.key,
    required this.riderId,
    required this.isOnline,
    required this.onOrderAccepted,
  });

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadOrders());
  }

  @override
  void didUpdateWidget(AvailableOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline != oldWidget.isOnline && widget.isOnline) _loadOrders();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!widget.isOnline) {
      setState(() { _orders = []; _loading = false; });
      return;
    }
    if (!_loading) setState(() => _loading = true);
    final orders = await RiderService.getAvailableOrders();
    if (!mounted) return;
    setState(() { _orders = orders; _loading = false; });
    RiderAlertService.instance.syncWithOrderCount(orders.length);
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(rt('รับงานนี้?', 'Accept this job?'), style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${rt('ร้าน', 'Store')}: ${order['store_name']}', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text('${rt('ส่งไป', 'Deliver to')}: ${order['address']}', style: const TextStyle(fontSize: 14, color: RiderColors.muted)),
            const SizedBox(height: 8),
            Text(
              '${rt('ค่าส่ง', 'Fee')}: ฿${order['delivery_fee']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RiderColors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(rt('ยกเลิก', 'Cancel'), style: const TextStyle(color: RiderColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: RiderColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(rt('รับงาน', 'Accept')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await RiderService.acceptOrder(order['id'], widget.riderId);
    if (!mounted) return;
    if (success) {
      RiderAlertService.instance.onOrderAccepted();
      widget.onOrderAccepted();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rt('รับงานสำเร็จ! ไปรับอาหารที่ร้านได้เลย', 'Accepted! Go pick up the food')),
          backgroundColor: RiderColors.blue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rt('รับงานไม่สำเร็จ อาจถูกรับไปแล้ว', 'Failed to accept, may already be taken')), backgroundColor: Colors.red),
      );
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: RiderColors.blueLight, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, color: RiderColors.muted, size: 40),
            ),
            const SizedBox(height: 16),
            Text(rt('คุณอยู่ในโหมด Offline', 'You are Offline'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.rFg)),
            const SizedBox(height: 8),
            Text(rt('เปิด Online เพื่อรับงานส่ง', 'Go Online to receive jobs'), style: TextStyle(color: context.rMuted)),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: RiderColors.blue));
    }

    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        color: RiderColors.blue,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: RiderColors.blueLight, shape: BoxShape.circle),
                      child: const Icon(Icons.search_off_rounded, color: RiderColors.muted, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(rt('ยังไม่มีงานใหม่', 'No new jobs yet'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.rFg)),
                    const SizedBox(height: 8),
                    Text(rt('ระบบจะแจ้งเตือนอัตโนมัติเมื่อมีงาน', 'System will notify when jobs arrive'), style: TextStyle(color: context.rMuted)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: RiderColors.blue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (_, i) => _OrderCard(order: _orders[i], onAccept: () => _acceptOrder(_orders[i])),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;
  const _OrderCard({required this.order, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final deliveryFee = double.tryParse(order['delivery_fee'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.rCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: RiderColors.blue.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: RiderColors.blueLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.store_rounded, color: RiderColors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order['store_name'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: context.rFg),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: RiderColors.blue, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '฿${fmt.format(deliveryFee)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(icon: Icons.restaurant_rounded, label: rt('รับจาก', 'Pick up'), value: order['store_address'] ?? '-'),
                const SizedBox(height: 10),
                _InfoRow(icon: Icons.location_on_rounded, label: rt('ส่งไป', 'Deliver to'), value: order['address'] ?? '-'),
                const SizedBox(height: 10),
                _InfoRow(icon: Icons.receipt_long_rounded, label: rt('รายการ', 'Items'), value: order['items_summary'] ?? '-'),
                if ((order['note'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoRow(icon: Icons.note_rounded, label: rt('หมายเหตุ', 'Note'), value: order['note']),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RiderColors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(rt('รับงานนี้', 'Accept Job'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: RiderColors.blue),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(label, style: TextStyle(fontSize: 12, color: context.rMuted)),
        ),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: context.rFg, fontWeight: FontWeight.w500))),
      ],
    );
  }
}
