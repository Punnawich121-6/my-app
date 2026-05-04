import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/rider_service.dart';

class EarningsScreen extends StatefulWidget {
  final int riderId;
  const EarningsScreen({super.key, required this.riderId});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? _earnings;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      RiderService.getEarnings(widget.riderId),
      RiderService.getHistory(widget.riderId),
    ]);
    if (!mounted) return;
    setState(() {
      _earnings = results[0] as Map<String, dynamic>?;
      _history = results[1] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: RiderColors.blue));

    final fmt = NumberFormat('#,##0.00');
    final today = double.tryParse(_earnings?['today']?['amount']?.toString() ?? '0') ?? 0;
    final week = double.tryParse(_earnings?['week']?['amount']?.toString() ?? '0') ?? 0;
    final total = double.tryParse(_earnings?['total']?['amount']?.toString() ?? '0') ?? 0;
    final todayCount = _earnings?['today']?['count'] ?? 0;
    final weekCount = _earnings?['week']?['count'] ?? 0;
    final totalCount = _earnings?['total']?['count'] ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      color: RiderColors.blue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today earnings
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [RiderColors.blue, Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('รายได้วันนี้', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '฿${fmt.format(today)}',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                ),
                Text('$todayCount งาน', style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly & Total
          Row(
            children: [
              Expanded(child: _SummaryCard(label: '7 วันที่ผ่านมา', amount: week, count: weekCount, fmt: fmt)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'รายได้รวม', amount: total, count: totalCount, fmt: fmt)),
            ],
          ),
          const SizedBox(height: 20),

          // History
          const Text('ประวัติการส่ง', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: RiderColors.text)),
          const SizedBox(height: 12),

          if (_history.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Center(
                child: Text('ยังไม่มีประวัติการส่ง', style: TextStyle(color: RiderColors.muted)),
              ),
            )
          else
            ..._history.map((order) => _HistoryCard(order: order, fmt: fmt)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final dynamic count;
  final NumberFormat fmt;
  const _SummaryCard({required this.label, required this.amount, required this.count, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: RiderColors.blue.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: RiderColors.muted)),
          const SizedBox(height: 6),
          Text('฿${fmt.format(amount)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RiderColors.blue)),
          Text('$count งาน', style: const TextStyle(fontSize: 12, color: RiderColors.muted)),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final NumberFormat fmt;
  const _HistoryCard({required this.order, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final deliveryFee = double.tryParse(order['delivery_fee'].toString()) ?? 0;
    final isCompleted = order['status'] == 'completed';
    final date = DateTime.tryParse(order['created_at'] ?? '');
    final dateStr = date != null ? DateFormat('dd/MM/yy HH:mm').format(date) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: RiderColors.blue.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? RiderColors.greenLight : RiderColors.redLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : Icons.close_rounded,
              color: isCompleted ? RiderColors.green : RiderColors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['store_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: RiderColors.text)),
                Text(order['address'] ?? '-', style: const TextStyle(fontSize: 12, color: RiderColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(dateStr, style: const TextStyle(fontSize: 11, color: RiderColors.muted)),
              ],
            ),
          ),
          if (isCompleted)
            Text('฿${fmt.format(deliveryFee)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: RiderColors.green)),
        ],
      ),
    );
  }
}
