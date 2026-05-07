import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/store_model.dart';
import '../../services/api_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? _data;
  Store? _store;
  bool _loading = true;
  final String _period = 'week';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getEarnings(period: _period);
      final store = await ApiService.getStore();
      if (!mounted) return;
      setState(() {
        _data = data;
        _store = store;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          titleSpacing: 20,
          title: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1583394838336-acd977736f90?w=200&h=200&fit=crop'),
              ),
              const SizedBox(width: 12),
              Text(_store?.name ?? 'Store', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.orange)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_none_rounded, color: AppColors.orange), onPressed: () {}),
            const SizedBox(width: 10),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
            : _data == null
                ? const Center(child: Text('เชื่อมต่อไม่ได้', style: TextStyle(color: AppColors.muted)))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('Earnings', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A), letterSpacing: -1)),
                      const SizedBox(height: 4),
                      const Text('Track your daily and weekly progress.', style: TextStyle(fontSize: 14, color: Color(0xFF757575))),
                      const SizedBox(height: 24),
                      _buildBalanceCard(),
                      const SizedBox(height: 30),
                      _buildThisWeekSection(),
                      const SizedBox(height: 30),
                      _buildRecentDeliveries(),
                      const SizedBox(height: 30),
                    ],
                  ),
      );

  Widget _buildBalanceCard() {
    final summary = _data!['summary'];
    final total = double.parse((summary['total'] ?? 0).toString());
    final count = summary['count'] ?? 0;
    final fmt = NumberFormat('#,##0.00');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.orange.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text("Today's Balance", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.trending_up, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text('+12%', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            '฿${fmt.format(total)}',
            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _BalanceStat(label: 'COMPLETED', value: '$count Trips')),
            Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
            const Expanded(child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: _BalanceStat(label: 'ACTIVE TIME', value: '5h 20m'),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _buildThisWeekSection() {
    final chart = (_data!['chart'] as List?) ?? [];
    if (chart.isEmpty) return const SizedBox.shrink();

    final maxVal = chart
        .map((e) => double.parse(e['revenue'].toString()))
        .fold(0.0, (a, b) => a > b ? a : b);
    final fmt = NumberFormat('#,##0.00');

    // Calculate total week revenue
    final weekTotal = chart.map((e) => double.parse(e['revenue'].toString())).fold(0.0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('This Week', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
              Text('฿${fmt.format(weekTotal)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.orange)),
            ],
          ),
          const SizedBox(height: 30),
          Stack(
            children: [
              // Horizontal lines
              Column(
                children: List.generate(4, (index) => Container(
                  margin: const EdgeInsets.only(bottom: 25),
                  height: 1,
                  color: const Color(0xFFEEEEEE),
                )),
              ),
              // Chart bars
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: chart.map((e) {
                    final rev = double.parse(e['revenue'].toString());
                    final h = maxVal > 0 ? (rev / maxVal) * 80 : 0.0;
                    final isToday = e['date'] != null &&
                        e['date'].toString().startsWith(DateTime.now().toIso8601String().substring(0, 10));
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (rev > 0 && h > 0)
                          Container(
                            width: 2,
                            height: h,
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.orange : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: chart.map((e) {
              final date = DateTime.tryParse(e['date']?.toString() ?? '');
              final label = date != null ? DateFormat('E').format(date).substring(0,1) : '';
              final isToday = e['date'] != null &&
                  e['date'].toString().startsWith(DateTime.now().toIso8601String().substring(0, 10));
              return Text(label, style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? AppColors.orange : const Color(0xFF9E9E9E)));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDeliveries() {
    final txs = (_data!['transactions'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Deliveries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 16),
        if (txs.isEmpty)
          const Text('No recent deliveries', style: TextStyle(color: Color(0xFF757575)))
        else
          ...txs.take(3).map((tx) => _DeliveryTile(tx: tx)),
      ],
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label, value;
  const _BalanceStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      );
}

class _DeliveryTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _DeliveryTile({required this.tx});

  void _showDetail(BuildContext context) {
    final orderId = int.tryParse(tx['order_id']?.toString() ?? '');
    if (orderId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(orderId: orderId, tx: tx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final date = DateTime.tryParse(tx['created_at']?.toString() ?? '');
    final timeStr = date != null ? DateFormat('HH:mm').format(date) : '';
    final amount = double.tryParse(tx['amount'].toString()) ?? 0;
    final orderIdStr = tx['order_id']?.toString() ?? '';

    final iconId = (tx['id'] ?? 0) % 3;
    final icon = iconId == 0 ? Icons.restaurant : (iconId == 1 ? Icons.local_pizza_outlined : Icons.coffee);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(color: AppColors.orangeLight, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                tx['customer_name']?.toString().isNotEmpty == true ? tx['customer_name'] : 'Order #$orderIdStr',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr.isNotEmpty ? 'Order #$orderIdStr • $timeStr' : 'Order #$orderIdStr',
                style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
              ),
            ]),
          ),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('฿${fmt.format(amount)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.orange, fontSize: 16)),
              const SizedBox(height: 2),
              const Text('หลังหักค่าบริการ', style: TextStyle(fontSize: 10, color: Color(0xFF757575), fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD), size: 20),
          ]),
        ]),
      ),
    );
  }
}

// ─── Order Detail Bottom Sheet ───────────────────────────────────────────────

class _OrderDetailSheet extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> tx;
  const _OrderDetailSheet({required this.orderId, required this.tx});
  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  Map<String, dynamic>? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getOrderDetailMap(widget.orderId.toString());
      if (!mounted) return;
      setState(() { _order = data; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final txAmount = double.tryParse(widget.tx['amount'].toString()) ?? 0;
    final customerName = widget.tx['customer_name']?.toString() ?? 'ลูกค้า';
    final date = DateTime.tryParse(widget.tx['created_at']?.toString() ?? '');
    final dateStr = date != null ? DateFormat('d MMM yyyy • HH:mm').format(date) : '';

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Order #${widget.orderId}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 2),
                  Text(dateStr, style: const TextStyle(fontSize: 13, color: Color(0xFF757575))),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                child: const Text('✅ completed', style: TextStyle(color: Color(0xFF43A047), fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          // Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _order == null
                    ? const Center(child: Text('ไม่สามารถโหลดข้อมูลได้'))
                    : ListView(controller: ctrl, padding: const EdgeInsets.all(20), children: [
                        // Customer
                        _SectionCard(children: [
                          _DetailRow(icon: Icons.person_outline, label: 'ลูกค้า', value: customerName),
                          if (_order!['customer_phone'] != null)
                            _DetailRow(icon: Icons.phone_outlined, label: 'เบอร์โทร', value: _order!['customer_phone']),
                          if (_order!['address'] != null && (_order!['address'] as String).isNotEmpty)
                            _DetailRow(icon: Icons.location_on_outlined, label: 'ที่อยู่', value: _order!['address']),
                          if (_order!['note'] != null && (_order!['note'] as String).isNotEmpty)
                            _DetailRow(icon: Icons.note_outlined, label: 'หมายเหตุ', value: _order!['note']),
                        ]),
                        const SizedBox(height: 16),
                        // Order items
                        const Text('รายการอาหาร', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 10),
                        _SectionCard(children: [
                          ...(_order!['items'] as List? ?? []).map((item) {
                            final price = double.tryParse(item['price'].toString()) ?? 0;
                            final qty = item['quantity'] as int? ?? 1;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(8)),
                                  child: Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.orange, fontSize: 13))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                                Text('฿${fmt.format(price * qty)}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                              ]),
                            );
                          }),
                        ]),
                        const SizedBox(height: 16),
                        // Earnings breakdown
                        const Text('สรุปรายรับ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.orange, Color(0xFFFF8F00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: (() {
                            final totalAmt = double.tryParse(_order!['total_amount']?.toString() ?? '0') ?? 0;
                            final deliveryFee = double.tryParse(_order!['delivery_fee']?.toString() ?? '0') ?? 0;
                            final foodAmt = totalAmt - deliveryFee;
                            return Column(children: [
                              _EarningRow(label: 'ยอดอาหาร', value: '฿${fmt.format(foodAmt)}', light: true),
                              _EarningRow(label: 'ค่าจัดส่ง (ของ rider)', value: '- ฿${fmt.format(deliveryFee)}', light: true),
                              _EarningRow(label: 'ค่าบริการแพลตฟอร์ม 15%', value: '- 15%', light: true),
                              const Divider(color: Colors.white38, height: 20),
                              _EarningRow(label: 'ร้านได้รับ', value: '฿${fmt.format(txAmount)}', bold: true, light: true),
                            ]);
                          })(),
                        ),
                        const SizedBox(height: 30),
                      ]),
          ),
        ]),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
        ]),
      );
}

class _EarningRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final bool light;
  const _EarningRow({required this.label, required this.value, this.bold = false, this.light = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: light ? Colors.white70 : const Color(0xFF757575)))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: light ? Colors.white : const Color(0xFF1A1A1A))),
        ]),
      );
}

