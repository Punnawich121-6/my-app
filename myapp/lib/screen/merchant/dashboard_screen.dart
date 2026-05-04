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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        titleSpacing: 20,
        title: Builder(builder: (context) {
          final user = FirebaseAuth.instance.currentUser;
          final photoUrl = user?.photoURL;
          final displayName = user?.displayName ?? _data?.store.name ?? 'Store';
          return Row(
            children: [
              ClipOval(
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, err) => Container(
                          width: 40,
                          height: 40,
                          color: AppColors.orangeLight,
                          child: const Icon(Icons.person, color: AppColors.orange, size: 22),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: AppColors.orangeLight,
                        child: const Icon(Icons.person, color: AppColors.orange, size: 22),
                      ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.orange)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Merchant Mode', style: TextStyle(fontSize: 10, color: AppColors.orange, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.orange),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantNotificationScreen())),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _data == null
              ? _buildError()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildOverviewHeader(),
                    const SizedBox(height: 20),
                    _buildSalesCard(),
                    const SizedBox(height: 20),
                    _buildActiveOrdersCard(),
                    const SizedBox(height: 24),
                    _buildTopItems(),
                    const SizedBox(height: 30),
                  ],
                ),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('ลองใหม่', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Widget _buildOverviewHeader() {
    final isOpen = _data!.store.isOpen;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A), letterSpacing: -1)),
        const SizedBox(height: 4),
        Text(dateStr, style: const TextStyle(fontSize: 14, color: Color(0xFF757575))),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _toggleOpen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isOpen ? const Color(0xFF4CAF50) : const Color(0xFFBDBDBD))),
              const SizedBox(width: 8),
              Text(isOpen ? 'Store Online' : 'Store Offline', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF424242))),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesCard() {
    final revenue = _data!.todayRevenue;
    final fmt = NumberFormat('#,##0.00');
    final sales = _data!.weekSales;
    final maxVal = sales.isNotEmpty ? sales.map((e) => double.parse(e['revenue'].toString())).fold(0.0, (a, b) => a > b ? a : b) : 1.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text("Today's Sales", style: TextStyle(color: Color(0xFF757575), fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.trending_up, size: 14, color: AppColors.orange),
                SizedBox(width: 4),
                Text('+14.5%', style: TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          Text('\$${fmt.format(revenue)}', style: const TextStyle(color: AppColors.orange, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1)),
          const SizedBox(height: 24),
          if (sales.isNotEmpty)
            SizedBox(
              height: 70,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: sales.map((e) {
                  final rev = double.parse(e['revenue'].toString());
                  final h = maxVal > 0 ? (rev / maxVal) * 70 : 10.0;
                  final isToday = e['date'] != null && e['date'].toString().startsWith(DateTime.now().toIso8601String().substring(0, 10));
                  return Container(
                    width: 38,
                    height: h.clamp(10, 70),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.orange : AppColors.orangeLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersCard() {
    final pending = _data!.pendingOrders;
    final ready = _data!.readyOrders;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.orange, Color(0xFFFF8F00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.orange.withValues(alpha:0.3), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -10,
            child: Icon(Icons.receipt_long_rounded, size: 120, color: Colors.white.withValues(alpha:0.15)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Active Orders", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${pending + ready}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1)),
              const SizedBox(height: 16),
              Row(children: [
                Text('Active: $pending', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                Text('Ready: $ready', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onViewAllOrders?.call(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.orange, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopItems() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.whatshot, color: AppColors.orange),
            SizedBox(width: 8),
            Text('Top Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          ]),
          const SizedBox(height: 20),
          _TopItemTile(imgUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300&h=300&fit=crop', name: 'Classic Smash', sub: '24 orders'),
          const SizedBox(height: 16),
          _TopItemTile(imgUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=300&h=300&fit=crop', name: 'Margherita', sub: '18 orders'),
          const SizedBox(height: 16),
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.orangeMid, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('+4', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 16),
            const Text('More items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A1A))),
          ]),
        ],
      ),
    );
  }
}

class _TopItemTile extends StatelessWidget {
  final String imgUrl, name, sub;
  const _TopItemTile({required this.imgUrl, required this.name, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(imgUrl, width: 48, height: 48, fit: BoxFit.cover),
      ),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 13, color: Color(0xFF757575))),
      ]),
    ]);
  }
}
