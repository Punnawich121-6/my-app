import 'package:flutter/material.dart';
import '../../main.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'menu_screen.dart';
import 'earnings_screen.dart';
import 'store_settings_screen.dart';

class MerchantMainScreen extends StatefulWidget {
  const MerchantMainScreen({super.key});

  static final GlobalKey<_MerchantMainScreenState> globalKey = GlobalKey<_MerchantMainScreenState>();

  @override
  State<MerchantMainScreen> createState() => _MerchantMainScreenState();
}

class _MerchantMainScreenState extends State<MerchantMainScreen> {
  int _currentIndex = 0;
  int _pendingOrders = 0;
  static _MerchantMainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MerchantMainScreenState>();

  void setTab(int index) {
    if (mounted) setState(() => _currentIndex = index);
  }

  void updatePendingBadge(int count) {
    if (mounted) setState(() => _pendingOrders = count);
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onPendingChanged: updatePendingBadge, onViewAllOrders: () => setTab(1)),
      const OrdersScreen(), 
      const MenuScreen(),
      const EarningsScreen(),
      const StoreSettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.muted,
        backgroundColor: Colors.white,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 12,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _pendingOrders > 0,
              label: Text('$_pendingOrders'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: _pendingOrders > 0,
              label: Text('$_pendingOrders'),
              child: const Icon(Icons.receipt_long),
            ),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined), activeIcon: Icon(Icons.restaurant_menu), label: 'Menu'),
          const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
          const BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: 'Store'),
        ],
      ),
    );
  }
}
