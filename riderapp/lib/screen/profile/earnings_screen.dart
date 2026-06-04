import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../services/rider_service.dart';
import '../orders/report_screen.dart';

class EarningsScreen extends StatefulWidget {
  final String riderId;
  const EarningsScreen({super.key, required this.riderId});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? _earnings;
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _reviewData;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  double _targetAmount = 500;
  final _targetCtrl = TextEditingController(text: '500');
  String? _aiTip;
  Map<String, dynamic>? _aiInsight;
  bool _loadingAi = false;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _load();
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredHistory {
    return _history.where((order) {
      final date = DateTime.tryParse(order['created_at'] ?? '');
      if (date == null) return false;
      final d = DateTime(date.year, date.month, date.day);
      return d == _selectedDate;
    }).toList();
  }

  bool get _isCustomDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    return _selectedDate != today && _selectedDate != yesterday;
  }

  Widget _buildDateChip(String label, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final isSelected = _selectedDate == d;
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = d),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? RiderColors.blue : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : RiderColors.muted,
          )),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: RiderColors.blue),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      RiderService.getEarnings(widget.riderId),
      RiderService.getHistory(widget.riderId),
      RiderService.getAnalytics(widget.riderId),
      RiderService.getReviews(widget.riderId),
    ]);
    if (!mounted) return;
    setState(() {
      _earnings = results[0] as Map<String, dynamic>?;
      _history = results[1] as List<Map<String, dynamic>>;
      _analytics = results[2] as Map<String, dynamic>?;
      _reviewData = results[3] as Map<String, dynamic>?;
      _loading = false;
    });
  }

  Future<void> _getAiAnalysis({
    required double today, required int todayCount,
    required double week, required int weekCount,
    required double total, required int totalCount,
    required int avg,
  }) async {
    setState(() { _loadingAi = true; _aiTip = null; _aiInsight = null; });
    final remaining = ((_targetAmount - today) / avg).ceil().clamp(0, 999);
    final peakHours = (_analytics?['peakHours'] as List?)?.cast<dynamic>();
    final avgRating = double.tryParse(_reviewData?['average']?.toString() ?? '');
    final recentComments = (_reviewData?['reviews'] as List?)
        ?.cast<Map<String, dynamic>>()
        .take(5)
        .map((r) => r['comment'] as String? ?? '')
        .where((c) => c.isNotEmpty)
        .toList();
    final results = await Future.wait([
      RiderService.getRiderPlan(
        todayEarned: today, todayCount: todayCount,
        avgPerDelivery: avg, targetAmount: _targetAmount.toInt(),
        remainingDeliveries: remaining,
      ),
      RiderService.getRiderInsight(
        todayEarned: today, todayCount: todayCount,
        weekEarned: week, weekCount: weekCount,
        totalEarned: total, totalCount: totalCount,
        avgPerDelivery: avg, targetAmount: _targetAmount.toInt(),
        peakHours: peakHours,
        avgRating: avgRating,
        recentComments: recentComments,
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _aiTip = results[0] as String?;
      _aiInsight = results[1] as Map<String, dynamic>?;
      _loadingAi = false;
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

    // Prescriptive analytics calculations
    final allTimeCount = int.tryParse(_earnings?['total']?['count']?.toString() ?? '0') ?? 0;
    final allTimeAmt = double.tryParse(_earnings?['total']?['amount']?.toString() ?? '0') ?? 0;
    final avgPerRun = allTimeCount > 0 ? (allTimeAmt / allTimeCount).round() : 40;
    final progressPct = _targetAmount > 0 ? (today / _targetAmount).clamp(0.0, 1.0) : 0.0;
    final tripsNeeded = avgPerRun > 0 ? (_targetAmount / avgPerRun).ceil() : 0;
    final remaining = ((_targetAmount - today) / avgPerRun).ceil().clamp(0, 999);

    return RefreshIndicator(
      onRefresh: _load,
      color: RiderColors.blue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Prescriptive Analytics ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.insights_rounded, color: RiderColors.blue, size: 18),
                SizedBox(width: 8),
                Text('วางแผนรายได้วันนี้', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RiderColors.text)),
              ]),
              const SizedBox(height: 14),

              // Goal input
              Row(children: [
                const Text('เป้าหมาย', style: TextStyle(fontSize: 13, color: RiderColors.muted)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    final v = double.tryParse(_targetCtrl.text);
                    if (v != null && v > 50) setState(() { _targetAmount = v - 50; _targetCtrl.text = (_targetAmount).toStringAsFixed(0); });
                  },
                  child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove, size: 16, color: RiderColors.blue)),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _targetCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RiderColors.blue),
                    decoration: InputDecoration(
                      prefixText: '฿',
                      prefixStyle: const TextStyle(fontSize: 14, color: RiderColors.blue, fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: const Color(0xFFF0F4FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    ),
                    onChanged: (v) { final d = double.tryParse(v); if (d != null) setState(() => _targetAmount = d); },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() { _targetAmount += 50; _targetCtrl.text = _targetAmount.toStringAsFixed(0); }),
                  child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add, size: 16, color: RiderColors.blue)),
                ),
              ]),
              const SizedBox(height: 12),

              // Progress bar
              Stack(children: [
                Container(height: 10, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8))),
                FractionallySizedBox(
                  widthFactor: progressPct,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Text('฿${fmt.format(today)} / ฿${fmt.format(_targetAmount)}', style: const TextStyle(fontSize: 12, color: RiderColors.blue, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${(progressPct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RiderColors.blue)),
              ]),
              const SizedBox(height: 14),

              // Stats row
              Row(children: [
                _PlanStat(label: 'วิ่งแล้ว', value: '$todayCount รอบ'),
                _PlanStat(label: 'ต้องวิ่งทั้งหมด', value: '$tripsNeeded รอบ'),
                _PlanStat(label: 'เหลืออีก', value: '$remaining รอบ', highlight: true),
                _PlanStat(label: 'เฉลี่ย/รอบ', value: '฿$avgPerRun'),
              ]),
              const SizedBox(height: 14),

              // AI results
              if (_aiTip != null || _aiInsight != null) ...[
                if (_aiTip != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFFF3EE), borderRadius: BorderRadius.circular(12)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFF6B35), size: 15),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_aiTip!, style: const TextStyle(fontSize: 13, color: RiderColors.text, height: 1.5))),
                    ]),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_aiInsight != null) ...[
                  _InsightContent(insight: _aiInsight!),
                  const SizedBox(height: 10),
                ],
              ],

              GestureDetector(
                onTap: _loadingAi ? null : () => _getAiAnalysis(
                  today: today, todayCount: todayCount,
                  week: week, weekCount: weekCount,
                  total: total, totalCount: totalCount,
                  avg: avgPerRun,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _loadingAi ? const Color(0xFFFFEDE7) : const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _loadingAi
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFFFF4500), strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('AI กำลังวิเคราะห์...', style: TextStyle(color: Color(0xFFFF4500), fontSize: 13)),
                        ])
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            (_aiTip != null || _aiInsight != null) ? '🔄 วิเคราะห์ใหม่' : '✨ AI แนะนำแผนวันนี้',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Today earnings
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('รายได้วันนี้', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '฿${fmt.format(today)}',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                ),
                Text('$todayCount งาน', style: const TextStyle(color: Colors.white, fontSize: 13)),
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

          // History header + date selector
          Row(children: [
            const Text('ประวัติการส่ง', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: RiderColors.text)),
            const Spacer(),
            _buildDateChip('วันนี้', DateTime.now()),
            const SizedBox(width: 6),
            _buildDateChip('เมื่อวาน', DateTime.now().subtract(const Duration(days: 1))),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isCustomDate ? RiderColors.blue : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_month_rounded, size: 13,
                      color: _isCustomDate ? Colors.white : RiderColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    _isCustomDate ? DateFormat('d MMM').format(_selectedDate) : 'เลือก',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: _isCustomDate ? Colors.white : RiderColors.muted),
                  ),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          if (_filteredHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.inbox_rounded, color: RiderColors.muted, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'ไม่มีการส่งในวันที่ ${DateFormat('d MMM yy').format(_selectedDate)}',
                    style: const TextStyle(color: RiderColors.muted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            )
          else
            ..._buildGroupedHistory(_filteredHistory, fmt),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedHistory(List<Map<String, dynamic>> history, NumberFormat fmt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // group by date string
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final order in history) {
      final date = DateTime.tryParse(order['created_at'] ?? '');
      final String key;
      if (date == null) {
        key = '—';
      } else {
        final d = DateTime(date.year, date.month, date.day);
        if (d == today) {
          key = 'วันนี้';
        } else if (d == yesterday) {
          key = 'เมื่อวาน';
        } else {
          key = DateFormat('d MMM yy').format(date);
        }
      }
      grouped.putIfAbsent(key, () => []).add(order);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      // date header
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(entry.key,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RiderColors.muted)),
      ));
      // compact card group
      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: List.generate(entry.value.length, (i) {
            final order = entry.value[i];
            final isLast = i == entry.value.length - 1;
            return _CompactHistoryRow(order: order, fmt: fmt, isLast: isLast, riderId: widget.riderId);
          }),
        ),
      ));
    }
    return widgets;
  }
}

class _InsightContent extends StatelessWidget {
  final Map<String, dynamic> insight;
  const _InsightContent({required this.insight});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF4500);
    const orangeLight = Color(0xFFFFF3EE);
    final score = (insight['score'] as num?)?.toInt();
    final scoreLabel = insight['scoreLabel'] as String? ?? '';
    final insights = (insight['insights'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final recs = (insight['recommendations'] as List?)?.cast<String>() ?? [];
    final motivation = insight['motivation'] as String?;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 1, color: Color(0xFFFFEDE7)),
      const SizedBox(height: 12),
      // Score row
      Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: orangeLight,
            shape: BoxShape.circle,
            border: Border.all(color: orange.withValues(alpha: 0.4), width: 2),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: orange)),
            Text('/10', style: TextStyle(fontSize: 9, color: orange.withValues(alpha: 0.7))),
          ]),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: orangeLight, borderRadius: BorderRadius.circular(20)),
            child: Text(scoreLabel, style: const TextStyle(color: orange, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(height: 4),
          const Text('คะแนนประสิทธิภาพ', style: TextStyle(fontSize: 11, color: RiderColors.muted)),
        ]),
      ]),
      if (insights.isNotEmpty) ...[
        const SizedBox(height: 12),
        ...insights.map((ins) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: orangeLight, borderRadius: BorderRadius.circular(10)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFF8C5A), size: 14),
            const SizedBox(width: 7),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ins['title'] ?? '', style: const TextStyle(color: orange, fontWeight: FontWeight.w700, fontSize: 11)),
              const SizedBox(height: 1),
              Text(ins['detail'] ?? '', style: const TextStyle(color: RiderColors.text, fontSize: 12, height: 1.4)),
            ])),
          ]),
        )),
      ],
      if (recs.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('คำแนะนำ', style: TextStyle(fontSize: 11, color: RiderColors.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...recs.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 18, height: 18,
              margin: const EdgeInsets.only(top: 1),
              decoration: const BoxDecoration(color: Color(0xFFFFEDE7), shape: BoxShape.circle),
              child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: orange, fontSize: 9, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 7),
            Expanded(child: Text(e.value, style: const TextStyle(color: RiderColors.text, fontSize: 12, height: 1.4))),
          ]),
        )),
      ],
      if (motivation != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: orangeLight, borderRadius: BorderRadius.circular(10)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.favorite_rounded, color: Color(0xFFFF6B35), size: 14),
            const SizedBox(width: 7),
            Expanded(child: Text(motivation, style: const TextStyle(color: RiderColors.text, fontSize: 12, height: 1.5))),
          ]),
        ),
      ],
    ]);
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
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))],
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

class _PlanStat extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _PlanStat({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: highlight ? RiderColors.blue : RiderColors.text,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: RiderColors.muted), textAlign: TextAlign.center),
    ]),
  );
}

class _CompactHistoryRow extends StatelessWidget {
  final Map<String, dynamic> order;
  final NumberFormat fmt;
  final String riderId;
  final bool isLast;
  const _CompactHistoryRow({required this.order, required this.fmt, required this.riderId, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final deliveryFee = double.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0;
    final isCompleted = order['status'] == 'completed';
    final date        = DateTime.tryParse(order['created_at'] ?? '');
    final timeStr     = date != null ? DateFormat('HH:mm').format(date) : '';

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onLongPress: isCompleted ? () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => RiderReportScreen(
              orderId:     order['id']?.toString() ?? '',
              orderNumber: order['orderNumber']?.toString() ?? order['id']?.toString() ?? '-',
              riderId:     riderId,
            ),
          )) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? RiderColors.greenLight : RiderColors.redLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : Icons.close_rounded,
                  color: isCompleted ? RiderColors.green : RiderColors.red,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(order['store_name'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RiderColors.text)),
                  Text(order['address'] ?? '-',
                      style: const TextStyle(fontSize: 11, color: RiderColors.muted),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (isCompleted)
                  Text('฿${fmt.format(deliveryFee)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: RiderColors.blue))
                else
                  const Text('ยกเลิก',
                      style: TextStyle(fontSize: 12, color: RiderColors.muted)),
                Text(timeStr, style: const TextStyle(fontSize: 11, color: RiderColors.muted)),
              ]),
            ]),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}
