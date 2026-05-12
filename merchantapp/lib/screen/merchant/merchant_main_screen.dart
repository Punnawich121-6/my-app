import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'menu_screen.dart';
import 'notification_screen.dart';
import 'store_settings_screen.dart';

class MerchantMainScreen extends StatefulWidget {
  const MerchantMainScreen({super.key});

  @override
  State<MerchantMainScreen> createState() => _MerchantMainScreenState();
}

class _MerchantMainScreenState extends State<MerchantMainScreen> {
  int _currentIndex = 0;
  int _pendingOrders = 0;
  bool _ready = false;
  List<Widget> _screens = [];

  void setTab(int index) {
    if (mounted) setState(() => _currentIndex = index);
  }

  void updatePendingBadge(int count) {
    if (mounted) setState(() => _pendingOrders = count);
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await ApiService.init();
    if (!mounted) return;
    _screens = [
      DashboardScreen(
        onPendingChanged: updatePendingBadge,
        onViewAllOrders: () => setTab(1),
        onViewMenu: () => setTab(2),
      ),
      const OrdersScreen(),
      const MenuScreen(),
      const MerchantNotificationScreen(),
      const StoreSettingsScreen(),
    ];
    setState(() => _ready = true);
  }

  void _onFabTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _QuickActionSheet(
        onAddMenu: () {
          Navigator.pop(sheetCtx);
          setTab(2);
        },
        onViewOrders: () {
          Navigator.pop(sheetCtx);
          setTab(1);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
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

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 0,
      notchMargin: 10,
      shape: const CircularNotchedRectangle(),
      padding: EdgeInsets.zero,
      child: Container(
        height: 62,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.grid_view_rounded, index: 0, currentIndex: _currentIndex, onTap: setTab),
            _NavItem(
              icon: Icons.receipt_long_rounded,
              index: 1,
              currentIndex: _currentIndex,
              onTap: setTab,
              badge: _pendingOrders,
            ),
            const SizedBox(width: 58),
            _NavItem(icon: Icons.notifications_none_rounded, index: 3, currentIndex: _currentIndex, onTap: setTab),
            _NavItem(icon: Icons.person_outline_rounded, index: 4, currentIndex: _currentIndex, onTap: setTab),
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
        width: 60,
        height: 62,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge', style: const TextStyle(fontSize: 10)),
                backgroundColor: AppColors.orange,
                child: Icon(
                  icon,
                  size: 24,
                  color: isActive ? AppColors.orange : const Color(0xFFBDBDBD),
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

class _QuickActionSheet extends StatelessWidget {
  final VoidCallback onAddMenu;
  final VoidCallback onViewOrders;

  const _QuickActionSheet({required this.onAddMenu, required this.onViewOrders});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 20),
          const Text('เพิ่มด่วน', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.restaurant_menu_rounded,
            color: AppColors.orange,
            title: 'เพิ่มเมนูใหม่',
            subtitle: 'เพิ่มรายการอาหารในร้าน',
            onTap: onAddMenu,
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _ActionTile(
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF1976D2),
            title: 'ดูออเดอร์',
            subtitle: 'จัดการออเดอร์ที่รอดำเนินการ',
            onTap: onViewOrders,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
    );
  }
}
