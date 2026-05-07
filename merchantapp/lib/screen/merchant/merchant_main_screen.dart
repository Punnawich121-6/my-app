import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'menu_screen.dart';
import 'earnings_screen.dart';
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
    // Fallback: if storeId still empty, find store by current Firebase user's phone
    if (ApiService.storeId.isEmpty) {
      try {
        String? phone = FirebaseAuth.instance.currentUser?.phoneNumber;
        if (phone != null && phone.startsWith('+66')) {
          phone = '0${phone.substring(3)}';
        }
        if (phone != null && phone.isNotEmpty) {
          final store = await ApiService.getStoreByPhone(phone);
          ApiService.storeId = store?['id']?.toString() ?? '';
        }
      } catch (_) {}
    }
    if (!mounted) return;
    _screens = [
      DashboardScreen(onPendingChanged: updatePendingBadge, onViewAllOrders: () => setTab(1)),
      const OrdersScreen(),
      const MenuScreen(),
      const EarningsScreen(),
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.orange,
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _onFabTap,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 12,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 60,
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
            const SizedBox(width: 56), // FAB space
            _NavItem(icon: Icons.restaurant_menu_rounded, index: 2, currentIndex: _currentIndex, onTap: setTab),
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
        width: 56,
        height: 60,
        child: Center(
          child: Badge(
            isLabelVisible: badge > 0,
            label: Text('$badge'),
            child: Icon(
              icon,
              size: 26,
              color: isActive ? AppColors.orange : AppColors.muted,
            ),
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
