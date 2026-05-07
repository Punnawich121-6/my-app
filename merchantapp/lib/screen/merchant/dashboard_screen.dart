import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/store_model.dart';
import '../../services/api_service.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int) onPendingChanged;
  final VoidCallback? onViewAllOrders;
  const DashboardScreen({super.key, required this.onPendingChanged, this.onViewAllOrders});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
      widget.onPendingChanged(data.pendingOrders);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _data == null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.orange,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildStatsRow(),
                      const SizedBox(height: 16),
                      _buildRevenueCard(),
                      const SizedBox(height: 16),
                      _buildReviewsCard(),
                      const SizedBox(height: 16),
                      _buildPopularItems(),
                    ],
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final storeName = _data?.store.name ?? 'ร้านของฉัน';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Color(0xFF1A1A1A), size: 26),
        onPressed: () {},
      ),
      title: GestureDetector(
        onTap: _toggleOpen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LOCATION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.orange,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1A1A1A), size: 18),
              ],
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MerchantNotificationScreen()),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.orangeLight,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person_rounded, color: AppColors.orange, size: 22)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

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
          const Text('เชื่อมต่อ server ไม่ได้', style: TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ลองใหม่', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Widget _buildStatsRow() {
    final running = _data!.todayOrders;
    final pending = _data!.pendingOrders;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: running.toString().padLeft(2, '0'),
            label: 'RUNNING ORDERS',
            onTap: () => _showRunningOrdersSheet(running),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            value: pending.toString().padLeft(2, '0'),
            label: 'ORDER REQUEST',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Daily', style: TextStyle(fontSize: 12, color: Color(0xFF424242), fontWeight: FontWeight.w500)),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF424242)),
                ]),
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
            child: _LineChart(data: sales.isNotEmpty ? sales : _placeholderSales()),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            const Text(
              'See All Reviews',
              style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
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
          const Text(
            'See All',
            style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _PopularItemCard(
                imgUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&h=400&fit=crop',
              ),
              SizedBox(width: 12),
              _PopularItemCard(
                imgUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&h=400&fit=crop',
              ),
              SizedBox(width: 12),
              _PopularItemCard(
                imgUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&h=400&fit=crop',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;
  const _StatCard({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.8,
            ),
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
  const _LineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(data: data),
      size: Size.infinite,
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  static const _orange = Color(0xFFFFA623);
  static const _labelColor = Color(0xFF9E9E9E);

  _LineChartPainter({required this.data});

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

    // Compute points
    final pts = List.generate(count, (i) {
      final x = i * dx;
      final y = chartH - (values[i] / range) * chartH * 0.85;
      return Offset(x, y);
    });

    // Gradient fill
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

    // Line
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

    // Peak point and tooltip
    int peakIdx = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[peakIdx]) peakIdx = i;
    }
    final peak = pts[peakIdx];

    // Dot
    canvas.drawCircle(peak, 7, Paint()..color = Colors.white);
    canvas.drawCircle(peak, 5, Paint()..color = _orange);

    // Tooltip
    if (maxVal > 0) {
      _drawTooltip(canvas, peak, '฿${NumberFormat('#,##0').format(values[peakIdx])}');
    }

    // Day labels
    final days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    for (int i = 0; i < pts.length; i++) {
      final label = i < days.length ? days[i] : '';
      _drawText(canvas, label, Offset(pts[i].dx, chartH + 4), _labelColor, 10);
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

    // Keep inside bounds
    if (bx < 0) bx = 0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(8)),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // Arrow
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
  bool shouldRepaint(_LineChartPainter old) => old.data != data;
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
            count == 0 ? 'ไม่มีออเดอร์ที่กำลังดำเนินการ' : 'มี $count ออเดอร์กำลังดำเนินการ',
            style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Popular Item Card ────────────────────────────────────────────────────────

class _PopularItemCard extends StatelessWidget {
  final String imgUrl;
  const _PopularItemCard({required this.imgUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imgUrl,
        width: 130,
        height: 130,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => Container(
          width: 130,
          height: 130,
          color: AppColors.orangeLight,
          child: const Icon(Icons.fastfood_rounded, color: AppColors.orange, size: 40),
        ),
      ),
    );
  }
}
