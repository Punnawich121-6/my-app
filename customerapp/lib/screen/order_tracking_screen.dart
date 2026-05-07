import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/customer_service.dart';
import 'chat_screen.dart';
import 'call_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});
  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  Timer? _timer;

  static const _steps = [
    {'key': 'pending',    'label': 'สั่งแล้ว',    'icon': Icons.receipt_long_rounded},
    {'key': 'accepted',   'label': 'ร้านรับ',     'icon': Icons.store_rounded},
    {'key': 'preparing',  'label': 'กำลังทำ',    'icon': Icons.restaurant_rounded},
    {'key': 'ready',      'label': 'พร้อมส่ง',   'icon': Icons.inventory_2_rounded},
    {'key': 'delivering', 'label': 'กำลังส่ง',   'icon': Icons.delivery_dining_rounded},
    {'key': 'completed',  'label': 'ส่งแล้ว',    'icon': Icons.home_rounded},
  ];

  static const _statusMsg = {
    'pending':    'รอร้านอาหารยืนยัน...',
    'accepted':   'ร้านรับออเดอร์แล้ว กำลังเตรียม',
    'preparing':  'กำลังทำอาหาร รอสักครู่...',
    'ready':      'อาหารพร้อม กำลังรอไรเดอร์',
    'delivering': 'ไรเดอร์กำลังนำอาหารมาส่ง!',
    'completed':  'ส่งอาหารเรียบร้อยแล้ว ขอบคุณ 😊',
    'cancelled':  'ออเดอร์ถูกยกเลิก',
  };

  static const _statusIcon = {
    'pending':    Icons.access_time_rounded,
    'accepted':   Icons.check_circle_outline_rounded,
    'preparing':  Icons.restaurant_rounded,
    'ready':      Icons.inventory_2_rounded,
    'delivering': Icons.delivery_dining_rounded,
    'completed':  Icons.sentiment_satisfied_alt_rounded,
    'cancelled':  Icons.cancel_outlined,
  };

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    final data = await CustomerService.getOrderDetail(widget.orderId);
    if (!mounted) return;
    setState(() { _order = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final status = _order?['status'] ?? 'pending';
    final stepIdx = _steps.indexWhere((s) => s['key'] == status);
    final isActive = !['completed', 'cancelled'].contains(status);

    return Scaffold(
      backgroundColor: CColors.bg,
      body: _loading && _order == null
          ? const Center(child: CircularProgressIndicator(color: CColors.orange))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: CColors.orange,
                  foregroundColor: Colors.white,
                  title: Text('ออเดอร์ #${widget.orderId}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  actions: [
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(right: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          _PulseDot(),
                          const SizedBox(width: 6),
                          const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                  ],
                ),
                if (_order != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _buildBanner(status),
                        const SizedBox(height: 16),
                        _buildTimeline(stepIdx, status),
                        if (status == 'delivering') ...[
                          const SizedBox(height: 16),
                          _buildRiderCard(),
                        ],
                        const SizedBox(height: 16),
                        _buildInfoCard('ร้านอาหาร', [
                          _InfoRow(Icons.store_rounded, _order!['store_name'] ?? '-', bold: true),
                          const SizedBox(height: 4),
                          _InfoRow(Icons.location_on_outlined, _order!['store_address'] ?? '-'),
                        ]),
                        const SizedBox(height: 12),
                        _buildInfoCard('ที่อยู่จัดส่ง', [
                          _InfoRow(Icons.home_rounded, _order!['address'] ?? '-', bold: true),
                          if ((_order!['note'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _InfoRow(Icons.note_rounded, _order!['note']),
                          ],
                        ]),
                        const SizedBox(height: 12),
                        _buildItemsCard(),
                        const SizedBox(height: 12),
                        _buildTotalCard(),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildRiderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
          child: const Icon(Icons.person_rounded, color: CColors.orange, size: 26),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Robert Fox', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CColors.text)),
            SizedBox(height: 2),
            Text('Your Rider', style: TextStyle(fontSize: 12, color: CColors.muted)),
          ]),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: CColors.orange, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CallScreen())),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: CColors.orange, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _buildBanner(String status) {
    final cancelled = status == 'cancelled';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cancelled ? [CColors.muted, const Color(0xFF757575)] : [CColors.orange, const Color(0xFFFF8F00)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Icon(_statusIcon[status] ?? Icons.info_outline, color: Colors.white, size: 42),
        const SizedBox(height: 10),
        Text(_statusMsg[status] ?? status, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildTimeline(int stepIdx, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
      child: Column(
        children: List.generate(_steps.length, (i) {
          final step = _steps[i];
          final done = i <= stepIdx && status != 'cancelled';
          final active = i == stepIdx && status != 'cancelled';
          final isLast = i == _steps.length - 1;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: done ? CColors.orange : CColors.orangeLight,
                  shape: BoxShape.circle,
                  border: active ? Border.all(color: CColors.orange, width: 2.5) : null,
                ),
                child: Icon(step['icon'] as IconData, size: 17, color: done ? Colors.white : CColors.muted),
              ),
              if (!isLast) Container(width: 2, height: 30, color: i < stepIdx ? CColors.orange : CColors.orangeLight),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 30),
                child: Row(children: [
                  Text(step['label'] as String, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: done ? CColors.text : CColors.muted)),
                  if (done && !active) ...[
                    const Spacer(),
                    const Icon(Icons.check_rounded, color: CColors.orange, size: 16),
                  ],
                ]),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CColors.muted, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }

  Widget _buildItemsCard() {
    final items = _order?['items'] as List? ?? [];
    final fmt = NumberFormat('#,##0.00');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('รายการอาหาร', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CColors.muted, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        ...items.map((item) {
          final price = double.tryParse(item['price'].toString()) ?? 0;
          final qty = item['quantity'] as int? ?? 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('$qty', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CColors.orange))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item['name'] ?? '', style: const TextStyle(fontSize: 13, color: CColors.text))),
              Text('฿${fmt.format(price * qty)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.text)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildTotalCard() {
    final fmt = NumberFormat('#,##0.00');
    final items = _order?['items'] as List? ?? [];
    final subtotal = items.fold<double>(0, (s, i) => s + (double.tryParse(i['price'].toString()) ?? 0) * (i['quantity'] as int? ?? 1));
    final fee = double.tryParse(_order?['delivery_fee']?.toString() ?? '30') ?? 30;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        _TotalRow('ค่าอาหาร', '฿${fmt.format(subtotal)}'),
        const SizedBox(height: 4),
        _TotalRow('ค่าจัดส่ง', '฿${fmt.format(fee)}'),
        const Divider(height: 16, color: CColors.orangeMid),
        _TotalRow('รวมทั้งหมด', '฿${fmt.format(subtotal + fee)}', bold: true),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String? text;
  final bool bold;
  const _InfoRow(this.icon, this.text, {this.bold = false});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 14, color: CColors.orange),
    const SizedBox(width: 8),
    Expanded(child: Text(text ?? '-', style: TextStyle(fontSize: 13, color: CColors.text, fontWeight: bold ? FontWeight.w600 : FontWeight.normal))),
  ]);
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _TotalRow(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) {
    final s = TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? CColors.text : CColors.muted);
    return Row(children: [Text(label, style: s), const Spacer(), Text(value, style: s.copyWith(color: bold ? CColors.orange : null))]);
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
  );
}
