import 'dart:async';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../services/api_service.dart';

class SmartPromoScreen extends StatefulWidget {
  const SmartPromoScreen({super.key});

  @override
  State<SmartPromoScreen> createState() => _SmartPromoScreenState();
}

class _SmartPromoScreenState extends State<SmartPromoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _pending   = [];
  List<dynamic> _active    = [];
  List<dynamic> _history   = [];
  bool _loading    = false;
  bool _analyzing  = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getPromotions();
      if (!mounted) return;
      setState(() {
        _pending  = (data['pending']   as List?) ?? [];
        _active   = (data['active']    as List?) ?? [];
        final completed = (data['completed'] as List?) ?? [];
        final rejected  = (data['rejected']  as List?) ?? [];
        _history  = [...completed, ...rejected];
        _loading  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    try {
      final result = await ApiService.analyzePromotion();
      if (!mounted) return;
      setState(() => _analyzing = false);
      if (result['shouldCreate'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['reasoning'] as String? ?? 'AI ไม่แนะนำโปรโมชั่นตอนนี้'),
            backgroundColor: AppColors.muted,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI สร้างข้อเสนอโปรโมชั่นแล้ว!'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _load();
      _tabController.animateTo(0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      _showError(e.toString());
    }
  }

  Future<void> _approve(dynamic promo) async {
    try {
      final id = (promo['id'] as num?)?.toInt();
      if (id == null) return;
      await ApiService.approvePromotion(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อนุมัติโปรโมชั่นแล้ว'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _onPromoExpired() async {
    await ApiService.finalizePromotions();
    await _load();
  }

  Future<void> _deletePromo(dynamic promo) async {
    try {
      final id = (promo['id'] as num?)?.toInt();
      if (id == null) return;
      await ApiService.deletePromotion(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบโปรโมชั่นแล้ว'),
          backgroundColor: AppColors.muted,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _reject(dynamic promo) async {
    try {
      final id = (promo['id'] as num?)?.toInt();
      if (id == null) return;
      await ApiService.rejectPromotion(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ปฏิเสธโปรโมชั่นแล้ว'),
          backgroundColor: AppColors.muted,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: NestedScrollView(
        headerSliverBuilder: (context2, innerScrolled) => [_buildAppBar()],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
            : TabBarView(
                controller: _tabController,
                children: [
                  _PendingTab(
                    promos: _pending,
                    onApprove: _approve,
                    onReject: _reject,
                  ),
                  _ActiveTab(promos: _active, onExpired: _onPromoExpired, onDelete: _deletePromo),
                  _HistoryTab(promos: _history, onDelete: _deletePromo),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _analyzing ? null : _analyze,
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: _analyzing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.auto_awesome_rounded),
        label: Text(
          _analyzing ? 'กำลังวิเคราะห์...' : 'ให้ AI วิเคราะห์',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.orange,
      elevation: 0,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('AI Smart Promo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _load,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'ข้อเสนอ AI${_pending.isNotEmpty ? " (${_pending.length})" : ""}'),
            Tab(text: 'ใช้งานอยู่${_active.isNotEmpty ? " (${_active.length})" : ""}'),
            const Tab(text: 'ประวัติ'),
          ],
        ),
      ),
    );
  }
}

class _PendingTab extends StatelessWidget {
  final List<dynamic> promos;
  final Future<void> Function(dynamic) onApprove;
  final Future<void> Function(dynamic) onReject;

  const _PendingTab({
    required this.promos,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (promos.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.auto_awesome_rounded, size: 36, color: AppColors.orange),
          ),
          const SizedBox(height: 16),
          const Text('ยังไม่มีข้อเสนอ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('กด "ให้ AI วิเคราะห์" เพื่อรับโปรโมชั่น', style: TextStyle(fontSize: 13, color: AppColors.muted), textAlign: TextAlign.center),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      color: AppColors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: promos.length,
        itemBuilder: (_, i) => _PendingCard(
          promo: promos[i],
          onApprove: onApprove,
          onReject: onReject,
        ),
      ),
    );
  }
}

class _PendingCard extends StatefulWidget {
  final dynamic promo;
  final Future<void> Function(dynamic) onApprove;
  final Future<void> Function(dynamic) onReject;

  const _PendingCard({
    required this.promo,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calcRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _calcRemaining();
    });
  }

  void _calcRemaining() {
    final pendingUntil = widget.promo['pending_until'];
    if (pendingUntil == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final until = DateTime.tryParse(pendingUntil.toString());
    if (until == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final diff = until.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdownText {
    if (_remaining == Duration.zero) return 'อนุมัติอัตโนมัติแล้ว';
    final m = _remaining.inMinutes.toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return 'อนุมัติอัตโนมัติใน $m:$s';
  }

  IconData _promoIcon(String? type) {
    switch (type) {
      case 'flash_sale':       return Icons.flash_on_rounded;
      case 'bogo':             return Icons.card_giftcard_rounded;
      case 'free_delivery':    return Icons.delivery_dining_rounded;
      case 'discount':
      default:                 return Icons.local_offer_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.promo;
    final title       = p['title']         as String? ?? 'โปรโมชั่น';
    final description = p['description']   as String? ?? '';
    final promoType   = p['promo_type']    as String?;
    final reasoning   = p['ai_reasoning']  as String? ?? '';
    final discType    = p['discount_type'] as String? ?? '';
    final discValue   = double.tryParse(p['discount_value']?.toString() ?? '0') ?? 0;
    final duration    = (p['duration_minutes'] as num?)?.toInt() ?? 120;
    final expRev      = double.tryParse(p['expected_revenue']?.toString() ?? '0') ?? 0;
    final expCost     = double.tryParse(p['expected_cost']?.toString() ?? '0') ?? 0;

    String discLabel;
    if (discType == 'percentage') {
      discLabel = 'ลด ${discValue.toStringAsFixed(0)}%';
    } else if (discType == 'fixed') {
      discLabel = 'ลด ฿${discValue.toStringAsFixed(0)}';
    } else {
      discLabel = 'ส่งฟรี';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header row ──
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(12)),
              child: Icon(_promoIcon(promoType), color: AppColors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.hourglass_bottom_rounded, size: 12, color: AppColors.orange),
                  const SizedBox(width: 4),
                  Text(_countdownText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.orange)),
                ]),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(20)),
              child: Text(discLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          // ── Description ──
          if (description.isNotEmpty) ...[
            Text(description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 12),
          ],
          // ── AI Reasoning ──
          if (reasoning.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.smart_toy_rounded, color: AppColors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(reasoning, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D2D2D)))),
              ]),
            ),
          const SizedBox(height: 12),
          // ── Stats row ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              _StatCell(label: 'คาดได้', value: '฿${expRev.toStringAsFixed(0)}'),
              Container(width: 1, height: 32, color: const Color(0xFFE0E0E0)),
              _StatCell(label: 'ต้นทุน', value: '฿${expCost.toStringAsFixed(0)}'),
              Container(width: 1, height: 32, color: const Color(0xFFE0E0E0)),
              _StatCell(label: 'เวลา', value: '$duration น.'),
            ]),
          ),
          const SizedBox(height: 16),
          // ── Action buttons ──
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.onApprove(widget.promo),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('อนุมัติ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onReject(widget.promo),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('ปฏิเสธ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  final List<dynamic> promos;
  final VoidCallback? onExpired;
  final Future<void> Function(dynamic)? onDelete;
  const _ActiveTab({required this.promos, this.onExpired, this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (promos.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.local_offer_rounded, size: 36, color: AppColors.orange),
          ),
          const SizedBox(height: 16),
          const Text('ไม่มีโปรโมชั่นที่ใช้งาน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('อนุมัติข้อเสนอ AI เพื่อเริ่มใช้งาน', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: promos.length,
      itemBuilder: (_, i) => _ActiveCard(promo: promos[i], onExpired: onExpired, onDelete: onDelete),
    );
  }
}

class _ActiveCard extends StatefulWidget {
  final dynamic promo;
  final VoidCallback? onExpired;
  final Future<void> Function(dynamic)? onDelete;
  const _ActiveCard({required this.promo, this.onExpired, this.onDelete});

  @override
  State<_ActiveCard> createState() => _ActiveCardState();
}

class _ActiveCardState extends State<_ActiveCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  Duration _total     = Duration.zero;
  bool _expired       = false;

  @override
  void initState() {
    super.initState();
    _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _calc();
    });
  }

  void _calc() {
    final endsAt   = DateTime.tryParse(widget.promo['ends_at']?.toString()   ?? '');
    final startsAt = DateTime.tryParse(widget.promo['starts_at']?.toString() ?? '');
    if (endsAt == null || startsAt == null) return;
    final remaining = endsAt.difference(DateTime.now());
    final total     = endsAt.difference(startsAt);
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
      _total     = total.isNegative     ? Duration.zero : total;
    });
    if (remaining.isNegative && !_expired) {
      _expired = true;
      _timer?.cancel();
      widget.onExpired?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress {
    if (_total.inSeconds == 0) return 0;
    final elapsed = _total.inSeconds - _remaining.inSeconds;
    return (elapsed / _total.inSeconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.promo;
    final title    = p['title']         as String? ?? 'โปรโมชั่น';
    final discType = p['discount_type'] as String? ?? '';
    final discVal  = double.tryParse(p['discount_value']?.toString() ?? '0') ?? 0;
    final duration = (p['duration_minutes'] as num?)?.toInt() ?? 120;

    String discLabel;
    if (discType == 'percentage') {
      discLabel = 'ลด ${discVal.toStringAsFixed(0)}%';
    } else if (discType == 'fixed') {
      discLabel = 'ลด ฿${discVal.toStringAsFixed(0)}';
    } else {
      discLabel = 'ส่งฟรี';
    }

    final m = _remaining.inMinutes.toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: AppColors.green, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'กำลังใช้งาน',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                discLabel,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.orange),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFFE0E0E0),
              color: AppColors.orange,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เหลือ $m:$s นาที',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange),
              ),
              Text(
                'ระยะเวลา $duration นาที',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
          if (widget.onDelete != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => widget.onDelete!(widget.promo),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('ลบ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<dynamic> promos;
  final Future<void> Function(dynamic)? onDelete;
  const _HistoryTab({required this.promos, this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (promos.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.history_rounded, size: 36, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          const Text('ยังไม่มีประวัติ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('ประวัติโปรโมชั่นจะแสดงที่นี่', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: promos.length,
      itemBuilder: (_, i) => _HistoryCard(promo: promos[i], onDelete: onDelete),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic promo;
  final Future<void> Function(dynamic)? onDelete;
  const _HistoryCard({required this.promo, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p          = promo;
    final title      = p['title']          as String? ?? 'โปรโมชั่น';
    final status     = p['status']         as String? ?? '';
    final isComplete = status == 'completed';
    final orders     = (p['actual_orders'] as num?)?.toInt() ?? 0;
    final revenue    = double.tryParse(p['actual_revenue']?.toString() ?? '0') ?? 0;
    final reasoning  = p['ai_reasoning']   as String? ?? '';
    final discType   = p['discount_type']  as String? ?? '';
    final discVal    = double.tryParse(p['discount_value']?.toString() ?? '0') ?? 0;
    final accentColor = isComplete ? AppColors.green : AppColors.red;

    String discLabel;
    if (discType == 'percentage') { discLabel = 'ลด ${discVal.toStringAsFixed(0)}%'; }
    else if (discType == 'fixed') { discLabel = 'ลด ฿${discVal.toStringAsFixed(0)}'; }
    else { discLabel = 'ส่งฟรี'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Title + badge
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isComplete ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: accentColor, size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(discLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        isComplete ? 'สำเร็จ' : 'ปฏิเสธ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor),
                      ),
                    ),
                  ]),
                  // Stats for completed
                  if (isComplete) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: const Color(0xFFF0F0F0)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: _StatBox(
                          icon: Icons.receipt_long_rounded,
                          label: 'ออเดอร์',
                          value: '$orders',
                          color: AppColors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          icon: Icons.payments_rounded,
                          label: 'รายได้',
                          value: '฿${revenue.toStringAsFixed(0)}',
                          color: AppColors.green,
                        ),
                      ),
                    ]),
                  ],
                  // Reasoning
                  if (reasoning.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(reasoning, style: const TextStyle(fontSize: 12, color: AppColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  // Delete
                  if (onDelete != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => onDelete!(promo),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.red),
                            SizedBox(width: 4),
                            Text('ลบ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.red)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatBox({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(icon, color: const Color(0xFFBDBDBD), size: 16),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        ]),
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label, value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted)),
      ]),
    );
  }
}
