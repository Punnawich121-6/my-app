import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';
import '../../../services/order_alert_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../order/orders_screen.dart';
import '../menu/menu_screen.dart';
import '../promo/smart_promo_screen.dart';
import 'notification_screen.dart';
import '../store/store_settings_screen.dart';

class MerchantMainScreen extends StatefulWidget {
  const MerchantMainScreen({super.key});

  @override
  State<MerchantMainScreen> createState() => _MerchantMainScreenState();
}

class _MerchantMainScreenState extends State<MerchantMainScreen> {
  int _currentIndex = 0;
  int _pendingOrders = 0;
  int _pendingPromos = 0;
  bool _ready = false;
  List<Widget> _screens = [];

  void setTab(int index) {
    if (mounted) setState(() => _currentIndex = index);
  }

  void updatePendingBadge(int count) {
    if (!mounted) return;
    setState(() => _pendingOrders = count);
    // เสียงหยุดเมื่อ pending = 0 เท่านั้น (หลังรับออเดอร์ครบ)
    OrderAlertService.instance.syncWithPendingCount(count);
  }

  Future<void> _refreshPromoBadge() async {
    try {
      final data = await ApiService.getPromotions();
      final pending = (data['pending'] as List?)?.length ?? 0;
      if (mounted) setState(() => _pendingPromos = pending);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    SocketService.instance.on('new_order', (_) {});
    super.dispose();
  }

  Future<void> _initialize() async {
    await ApiService.init();
    if (!mounted) return;

    // join store socket room & listen for new orders
    SocketService.instance.connect();
    SocketService.instance.joinStoreRoom(ApiService.storeId);
    SocketService.instance.on('new_order', (data) {
      if (!mounted) return;
      final storeId = data['store_id']?.toString();
      if (storeId != ApiService.storeId) return;
      // เพิ่ม count แล้ว sync — dashboard poll จะ confirm ตัวเลขจริงอีกที
      final newCount = _pendingOrders + 1;
      if (mounted) setState(() => _pendingOrders = newCount);
      OrderAlertService.instance.syncWithPendingCount(newCount);
    });

    // pre-fetch เสียงจาก Botnoi ล่วงหน้า
    OrderAlertService.instance.prefetch();

    _screens = [
      DashboardScreen(
        onPendingChanged: updatePendingBadge,
        onViewAllOrders: () => setTab(1),
        onViewMenu: () => setTab(2),
      ),
      const OrdersScreen(),
      const MenuScreen(),
      const SmartPromoScreen(),
      const MerchantNotificationScreen(),
      const StoreSettingsScreen(),
    ];
    setState(() => _ready = true);
    _refreshPromoBadge();
  }

  void _onFabTap() => setTab(2);

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildFab() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C5A), Color(0xFFFF4500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _onFabTap,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF222222) : Colors.white;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFF0F0F0);
    return BottomAppBar(
      color: navBg,
      elevation: 0,
      notchMargin: 10,
      shape: const CircularNotchedRectangle(),
      padding: EdgeInsets.zero,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(child: _NavItem(icon: Icons.grid_view_rounded, index: 0, currentIndex: _currentIndex, onTap: setTab)),
            Expanded(child: _NavItem(
              icon: Icons.receipt_long_rounded,
              index: 1,
              currentIndex: _currentIndex,
              onTap: setTab,
              badge: _pendingOrders,
            )),
            const SizedBox(width: 58),
            Expanded(child: _NavItem(
              icon: Icons.auto_awesome_rounded,
              index: 3,
              currentIndex: _currentIndex,
              onTap: (i) { setTab(i); _refreshPromoBadge(); },
              badge: _pendingPromos,
            )),
            Expanded(child: _NavItem(icon: Icons.person_outline_rounded, index: 5, currentIndex: _currentIndex, onTap: setTab)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 62,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge', style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.orange,
                child: Icon(
                  icon,
                  size: 24,
                  color: isActive ? AppColors.orange : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4, height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
