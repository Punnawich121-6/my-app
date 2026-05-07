import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../services/rider_service.dart';
import '../navigation_screen.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final String riderId;
  final Map<String, dynamic>? order;
  final bool isLoading;
  final VoidCallback onDeliveryComplete;

  const ActiveDeliveryScreen({
    super.key,
    required this.riderId,
    required this.order,
    required this.isLoading,
    required this.onDeliveryComplete,
  });

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  bool _completing = false;

  Future<void> _completeDelivery() async {
    final order = widget.order;
    if (order == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการส่ง?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('กรุณายืนยันเมื่อส่งอาหารถึงลูกค้าแล้ว'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยังไม่ส่ง', style: TextStyle(color: RiderColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: RiderColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ส่งแล้ว'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _completing = true);
    final success = await RiderService.completeDelivery(order['id'], widget.riderId);
    if (!mounted) return;
    setState(() => _completing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่งอาหารสำเร็จ! ระบบบันทึกรายได้แล้ว'),
          backgroundColor: RiderColors.blue,
        ),
      );
      widget.onDeliveryComplete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator(color: RiderColors.blue));
    }

    if (widget.order == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: RiderColors.blueLight, shape: BoxShape.circle),
              child: const Icon(Icons.directions_bike_rounded, color: RiderColors.muted, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('ไม่มีงานที่กำลังส่ง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: RiderColors.text)),
            const SizedBox(height: 8),
            const Text('รับงานจากหน้า "งานใหม่"', style: TextStyle(color: RiderColors.muted)),
          ],
        ),
      );
    }

    final order = widget.order!;
    final fmt = NumberFormat('#,##0.00');
    final deliveryFee = double.tryParse(order['delivery_fee'].toString()) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [RiderColors.blue, Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.directions_bike_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                const Text('กำลังส่งอาหาร', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'ค่าส่ง ฿${fmt.format(deliveryFee)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Steps
          _StepsCard(),
          const SizedBox(height: 16),

          // Order detail card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: RiderColors.blue.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('รายละเอียดออเดอร์', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: RiderColors.text)),
                const SizedBox(height: 12),
                _DetailRow(icon: Icons.store_rounded, label: 'ร้านอาหาร', value: order['store_name'] ?? '-'),
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.location_on_rounded, label: 'รับที่', value: order['store_address'] ?? '-', accent: true),
                const Divider(height: 20, color: RiderColors.blueLight),
                _DetailRow(icon: Icons.person_rounded, label: 'ลูกค้า', value: order['customer_name'] ?? '-'),
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.phone_rounded, label: 'เบอร์', value: order['customer_phone'] ?? '-'),
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.home_rounded, label: 'ส่งที่', value: order['address'] ?? '-', accent: true),
                const Divider(height: 20, color: RiderColors.blueLight),
                _DetailRow(icon: Icons.receipt_long_rounded, label: 'รายการ', value: order['items_summary'] ?? '-'),
                if ((order['note'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailRow(icon: Icons.note_rounded, label: 'หมายเหตุ', value: order['note']),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Complete button
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton.icon(
              onPressed: _completing ? null : _completeDelivery,
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderColors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _completing
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _completing ? 'กำลังบันทึก...' : 'ส่งอาหารแล้ว',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Navigation button
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NavigationScreen(
                  storeAddress: order['store_address'] ?? '-',
                  storeName: order['store_name'] ?? '-',
                  customerAddress: order['address'] ?? '-',
                  customerName: order['customer_name'] ?? '-',
                )),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: RiderColors.blue),
                foregroundColor: RiderColors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('ดูเส้นทาง', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 8),

          // Call customer button
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: RiderColors.blue),
                foregroundColor: RiderColors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: const Text('โทรหาลูกค้า', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: RiderColors.blue.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _Step(icon: Icons.store_rounded, label: 'รับอาหาร', done: true),
          Expanded(child: Container(height: 2, color: RiderColors.blue)),
          _Step(icon: Icons.delivery_dining, label: 'กำลังส่ง', done: true, active: true),
          Expanded(child: Container(height: 2, color: RiderColors.blueLight)),
          _Step(icon: Icons.check_circle_rounded, label: 'ส่งแล้ว', done: false),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  final bool active;
  const _Step({required this.icon, required this.label, required this.done, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: done ? RiderColors.blue : RiderColors.blueLight,
            shape: BoxShape.circle,
            border: active ? Border.all(color: RiderColors.blue, width: 3) : null,
          ),
          child: Icon(icon, color: done ? Colors.white : RiderColors.muted, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: done ? RiderColors.blue : RiderColors.muted, fontWeight: done ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool accent;
  const _DetailRow({required this.icon, required this.label, required this.value, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: accent ? RiderColors.blue : RiderColors.muted),
        const SizedBox(width: 8),
        SizedBox(width: 55, child: Text(label, style: const TextStyle(fontSize: 12, color: RiderColors.muted))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: RiderColors.text, fontWeight: accent ? FontWeight.w600 : FontWeight.w500))),
      ],
    );
  }
}
