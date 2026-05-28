import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app_settings.dart';
import '../../../l10n.dart';
import '../../../main.dart';
import '../../../models/store_model.dart';
import '../../../services/api_service.dart';
import '../store/store_settings_screen.dart';
import '../promo/smart_promo_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int) onPendingChanged;
  final VoidCallback? onViewAllOrders;
  final VoidCallback? onViewMenu;
  const DashboardScreen({super.key, required this.onPendingChanged, this.onViewAllOrders, this.onViewMenu});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
  bool _loading = true;
  String _revenuePeriod = 'Daily';
  List<Map<String, dynamic>> _chartOverride = [];
  List<Map<String, dynamic>> _popularItems = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onSettings);
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _silentRefresh());
  }

  void _onSettings() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _popularItems = data.popularItems;
        _loading = false;
      });
      widget.onPendingChanged(data.pendingOrders);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final data = await ApiService.getDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _popularItems = data.popularItems;
      });
      widget.onPendingChanged(data.pendingOrders);
    } catch (_) {}
  }

  Future<void> _changePeriod(String period) async {
    setState(() => _revenuePeriod = period);
    if (period == 'Daily') {
      setState(() => _chartOverride = []);
      return;
    }
    try {
      final apiPeriod = period == 'Weekly' ? 'week' : 'month';
      final earnings = await ApiService.getEarnings(period: apiPeriod);
      final chart = (earnings['chart'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _chartOverride = chart.map<Map<String, dynamic>>((e) => {
          'revenue': e['revenue'] ?? 0,
          'date': e['date'],
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _showReviewsSheet() async {
    Map<String, dynamic>? reviews;
    try {
      reviews = await ApiService.getReviews();
    } catch (_) {}
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReviewsSheet(data: reviews),
    );
  }


  Future<void> _toggleOpen() async {
    try {
      final isOpen = await ApiService.toggleStoreOpen();
      if (!mounted) return;
      setState(() => _data!.store.isOpen = isOpen);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _data == null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.orange,
                  child: CustomScrollView(
                    slivers: [
                      _buildSliverAppBar(),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildStatsRow(),
                            const SizedBox(height: 16),
                            _buildSmartPromoBanner(),
                            const SizedBox(height: 16),
                            _buildRevenueCard(),
                            const SizedBox(height: 16),
                            _buildReviewsCard(),
                            const SizedBox(height: 16),
                            _buildPopularItems(),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSliverAppBar() {
    final storeName = _data?.store.name ?? t('ร้านของฉัน', 'My Store');
    final isOpen = _data?.store.isOpen ?? false;

    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.orange,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreSettingsScreen())),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildAppBarBg(storeName, isOpen),
      ),
    );
  }

  Widget _buildAppBarBg(String storeName, bool isOpen) {
    final imgUrl = _data?.store.imageUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        // รูปร้านหรือ gradient fallback
        if (imgUrl != null && imgUrl.isNotEmpty)
          Image.network(imgUrl, fit: BoxFit.cover,
            errorBuilder: (ctx, err, e) => _orangeGradientBg())
        else
          _orangeGradientBg(),
        // Dark overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withValues(alpha: 0.45), Colors.black.withValues(alpha: 0.15)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _toggleOpen,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              color: isOpen ? const Color(0xFF69F0AE) : Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? t('เปิดรับออเดอร์', 'Open') : t('ปิดร้านอยู่', 'Closed'),
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
  }

  Widget _orangeGradientBg() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFFF8C5A), Color(0xFFFF4500)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );

  void _showRunningOrdersSheet(int count) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RunningOrdersSheet(count: count),
    );
  }

  Widget _buildError() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(t('เชื่อมต่อ server ไม่ได้', 'Cannot connect to server'), style: const TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(t('ลองใหม่', 'Retry'), style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Widget _buildSmartPromoBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmartPromoScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Smart Promo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t('ให้ AI สร้างโปรโมชั่นอัตโนมัติเพื่อเพิ่มยอดขาย', 'Let AI auto-generate promotions to boost sales'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final running = _data!.todayOrders;
    final pending = _data!.pendingOrders;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: running,
            label: 'Running Orders',
            sublabel: t('กำลังดำเนินการ', 'In Progress'),
            icon: Icons.local_fire_department_rounded,
            accentColor: AppColors.orange,
            onTap: () => _showRunningOrdersSheet(running),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: pending,
            label: 'Order Request',
            sublabel: t('รอการยืนยัน', 'Awaiting Confirm'),
            icon: Icons.inbox_rounded,
            accentColor: AppColors.orange,
            onTap: () => widget.onViewAllOrders?.call(),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard() {
    final revenue = _data!.todayRevenue;
    final fmt = NumberFormat('#,##0');
    final sales = _data!.weekSales;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Total Revenue',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _revenuePeriod,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF424242), fontWeight: FontWeight.w500),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF424242)),
                    items: ['Daily', 'Weekly', 'Monthly'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) { if (v != null) _changePeriod(v); },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => widget.onViewAllOrders?.call(),
                child: const Text(
                  'See Details',
                  style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '฿${fmt.format(revenue)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: _LineChart(
              data: _chartOverride.isNotEmpty
                  ? _chartOverride
                  : sales.isNotEmpty ? sales : _placeholderSales(),
              period: _revenuePeriod,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _placeholderSales() => [
    {'revenue': 120}, {'revenue': 340}, {'revenue': 500}, {'revenue': 280},
    {'revenue': 420}, {'revenue': 390}, {'revenue': 450},
  ];

  Widget _buildReviewsCard() {
    final rating = _data!.store.rating;
    final count = _data!.store.reviewCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(children: [
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _showReviewsSheet,
              child: const Text(
                'See All Reviews',
                style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFF6B35), size: 28),
            const SizedBox(width: 8),
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : '0.0',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(width: 12),
            Text(
              'Total $count Reviews',
              style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
            ),
          ]),
        ],
      ),
    );
  }

  void _showItemDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(item: item),
    );
  }

  Widget _buildItemGrid() {
    final items = _popularItems.take(4).toList();
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(child: SizedBox(
            height: 140,
            child: _PopularItemCard(
              name: items[i]['name'] as String,
              imgUrl: items[i]['image_url'] as String?,
              onTap: () => _showItemDetail(items[i]),
            ),
          )),
          const SizedBox(width: 12),
          if (i + 1 < items.length)
            Expanded(child: SizedBox(
              height: 140,
              child: _PopularItemCard(
                name: items[i + 1]['name'] as String,
                imgUrl: items[i + 1]['image_url'] as String?,
                onTap: () => _showItemDetail(items[i + 1]),
              ),
            ))
          else
            const Expanded(child: SizedBox()),
        ],
      ));
      if (i + 2 < items.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }

  Widget _buildPopularItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text(
            'Popular Items This Week',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onViewMenu,
            child: const Text(
              'See All',
              style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (_popularItems.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(t('ยังไม่มีเมนู', 'No menu items yet'), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ))
        else
          _buildItemGrid(),
      ],
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  const _StatCard({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              value.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: accentColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF616161)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Line Chart ───────────────────────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String period;
  const _LineChart({required this.data, this.period = 'Daily'});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(data: data, period: period),
      size: Size.infinite,
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String period;
  static const _orange = Color(0xFFFF6B35);
  static const _labelColor = Color(0xFF9E9E9E);

  _LineChartPainter({required this.data, this.period = 'Daily'});

  List<String> _buildLabels() {
    final thaiDays = AppSettings.instance.isEnglish
        ? ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
        : ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];
    final count = data.length;

    if (count > 0 && data.first['date'] != null) {
      return List.generate(count, (i) {
        final dateStr = data[i]['date'].toString().split('T').first;
        try {
          final d = DateTime.parse(dateStr);
          if (period == 'Monthly' && count > 10) {
            final dayNum = d.day;
            if (i == 0 || i == count - 1 || dayNum % 5 == 0) {
              return '${d.day}';
            }
            return '';
          } else {
            return thaiDays[d.weekday % 7];
          }
        } catch (_) {
          return '';
        }
      });
    }

    if (count <= 7) {
      return thaiDays.take(count).toList();
    }
    return List.generate(count, (i) => (i % 5 == 0) ? '${i + 1}' : '');
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const labelHeight = 20.0;
    final chartH = size.height - labelHeight;
    final values = data.map((e) => double.parse(e['revenue'].toString())).toList();
    final maxVal = values.fold(0.0, math.max);
    final range = maxVal > 0 ? maxVal : 1.0;
    final count = values.length;
    final dx = count > 1 ? size.width / (count - 1) : size.width;

    final pts = List.generate(count, (i) {
      final x = i * dx;
      final y = chartH - (values[i] / range) * chartH * 0.85;
      return Offset(x, y);
    });

    final fillPath = Path()
      ..moveTo(pts.first.dx, chartH)
      ..lineTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final mid = Offset((pts[i - 1].dx + pts[i].dx) / 2, (pts[i - 1].dy + pts[i].dy) / 2);
      fillPath.quadraticBezierTo(pts[i - 1].dx, pts[i - 1].dy, mid.dx, mid.dy);
    }
    fillPath
      ..lineTo(pts.last.dx, chartH)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_orange.withValues(alpha: 0.28), _orange.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
    );

    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final mid = Offset((pts[i - 1].dx + pts[i].dx) / 2, (pts[i - 1].dy + pts[i].dy) / 2);
      linePath.quadraticBezierTo(pts[i - 1].dx, pts[i - 1].dy, mid.dx, mid.dy);
    }
    linePath.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = _orange
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    int peakIdx = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[peakIdx]) peakIdx = i;
    }
    final peak = pts[peakIdx];

    canvas.drawCircle(peak, 7, Paint()..color = Colors.white);
    canvas.drawCircle(peak, 5, Paint()..color = _orange);

    if (maxVal > 0) {
      _drawTooltip(canvas, peak, '฿${NumberFormat('#,##0').format(values[peakIdx])}');
    }

    final labels = _buildLabels();
    for (int i = 0; i < pts.length; i++) {
      final label = i < labels.length ? labels[i] : '';
      if (label.isNotEmpty) {
        _drawText(canvas, label, Offset(pts[i].dx, chartH + 4), _labelColor, 9);
      }
    }
  }

  void _drawTooltip(Canvas canvas, Offset point, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    const pad = 8.0;
    final bw = tp.width + pad * 2;
    final bh = tp.height + pad;
    var bx = point.dx - bw / 2;
    var by = point.dy - bh - 14;

    if (bx < 0) bx = 0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(8)),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    final arrowPath = Path()
      ..moveTo(point.dx - 5, by + bh)
      ..lineTo(point.dx + 5, by + bh)
      ..lineTo(point.dx, by + bh + 6)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = const Color(0xFF1A1A1A));

    tp.paint(canvas, Offset(bx + pad, by + pad / 2));
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.data != data || old.period != period;
}

// ─── Running Orders Sheet ─────────────────────────────────────────────────────

class _RunningOrdersSheet extends StatelessWidget {
  final int count;
  const _RunningOrdersSheet({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Running Orders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count orders',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.orange),
          const SizedBox(height: 12),
          Text(
            count == 0 ? t('ไม่มีออเดอร์ที่กำลังดำเนินการ', 'No orders in progress') : t('มี $count ออเดอร์กำลังดำเนินการ', '$count orders in progress'),
            style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Reviews Sheet ────────────────────────────────────────────────────────────

class _ReviewsSheet extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _ReviewsSheet({this.data});

  @override
  Widget build(BuildContext context) {
    final reviews = (data?['reviews'] as List?) ?? [];
    final average = data?['average'] ?? '0.0';
    final total = data?['total'] ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
            child: Column(children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Text(t('รีวิวทั้งหมด', 'All Reviews'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                  const Spacer(),
                  const Icon(Icons.star_rounded, color: Color(0xFFFF6B35), size: 20),
                  const SizedBox(width: 4),
                  Text('$average', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('  ($total ${t('รีวิว', 'reviews')})', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
            ]),
          ),
          Expanded(
            child: reviews.isEmpty
                ? Center(child: Text(t('ยังไม่มีรีวิว', 'No reviews yet'), style: const TextStyle(color: AppColors.muted)))
                : ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const Divider(height: 20),
                    itemBuilder: (_, i) {
                      final r = reviews[i] as Map<String, dynamic>;
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(radius: 16, backgroundColor: AppColors.orangeLight,
                              child: const Icon(Icons.person_rounded, color: AppColors.orange, size: 18)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(r['customer_name'] ?? t('ลูกค้า', 'Customer'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                          Row(children: List.generate(5, (s) => Icon(Icons.star_rounded, size: 14,
                              color: s < (r['rating'] as num).toInt() ? const Color(0xFFFF6B35) : const Color(0xFFE0E0E0)))),
                        ]),
                        if (r['comment'] != null && (r['comment'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(r['comment'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF424242))),
                        ],
                      ]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Popular Item Card ────────────────────────────────────────────────────────

class _PopularItemCard extends StatelessWidget {
  final String name;
  final String? imgUrl;
  final VoidCallback? onTap;
  const _PopularItemCard({required this.name, this.imgUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imgUrl != null && imgUrl!.startsWith('http')
                    ? Image.network(
                        imgUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Text(
                name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: double.infinity,
        color: AppColors.orangeLight,
        child: const Icon(Icons.fastfood_rounded, color: AppColors.orange, size: 40),
      );
}

// ─── Item Detail Sheet ────────────────────────────────────────────────────────

class _ItemDetailSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? '-';
    final imgUrl = item['image_url']?.toString();
    int parseInt(dynamic v) => v == null ? 0 : int.tryParse(v.toString()) ?? 0;
    double parseDouble(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
    final orderCount = parseInt(item['order_count'] ?? item['total_orders'] ?? item['total_sold']);
    final price = item['price'] != null ? double.tryParse(item['price'].toString()) : null;
    final revenue = parseDouble(item['revenue'] ?? item['total_revenue']) > 0
        ? parseDouble(item['revenue'] ?? item['total_revenue'])
        : (price != null ? price * orderCount : 0.0);
    final category = item['category_name']?.toString() ?? item['category']?.toString();
    final fmt = NumberFormat('#,##0');
    final fmtDec = NumberFormat('#,##0.00');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(99)),
          ),
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: imgUrl != null && imgUrl.startsWith('http')
                  ? Image.network(imgUrl, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imagePlaceholder())
                  : _imagePlaceholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + category
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Text(name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                  ),
                  if (price != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.orangeLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('฿${fmtDec.format(price)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.orange)),
                    ),
                  ],
                ]),
                if (category != null) ...[
                  const SizedBox(height: 4),
                  Text(category, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
                const SizedBox(height: 20),
                // Stats row
                Row(children: [
                  _StatChip(
                    icon: Icons.receipt_long_rounded,
                    label: t('ออเดอร์ทั้งหมด', 'Total Orders'),
                    value: '${fmt.format(orderCount)} ${t('ครั้ง', 'times')}',
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.payments_rounded,
                    label: t('รายได้รวม', 'Total Revenue'),
                    value: '฿${fmt.format(revenue)}',
                    color: const Color(0xFF43A047),
                  ),
                ]),
                if (orderCount > 0 && price != null && price > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.trending_up_rounded, color: AppColors.muted, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        t('เฉลี่ย ${fmtDec.format(revenue / orderCount)} บาท / ออเดอร์', 'Avg ฿${fmtDec.format(revenue / orderCount)} / order'),
                        style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: AppColors.orangeLight,
    child: const Center(child: Icon(Icons.fastfood_rounded, color: AppColors.orange, size: 48)),
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ]),
      ),
    );
  }
}
