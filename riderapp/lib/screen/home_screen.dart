import 'package:flutter/material.dart';
import '../main.dart';
import '../services/rider_service.dart';
import 'orders/available_orders_screen.dart';
import 'orders/active_delivery_screen.dart';
import 'earnings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String riderId;
  final String riderName;
  const HomeScreen({super.key, required this.riderId, required this.riderName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isOnline = true;
  Map<String, dynamic>? _activeOrder;
  bool _loadingActive = true;

  @override
  void initState() {
    super.initState();
    _loadActiveOrder();
  }

  Future<void> _loadActiveOrder() async {
    setState(() => _loadingActive = true);
    final order = await RiderService.getActiveDelivery(widget.riderId);
    if (!mounted) return;
    setState(() {
      _activeOrder = order;
      _loadingActive = false;
      if (order != null) _currentIndex = 1;
    });
  }

  List<Widget> get _screens => [
    AvailableOrdersScreen(
      riderId: widget.riderId,
      isOnline: _isOnline,
      onOrderAccepted: _loadActiveOrder,
    ),
    ActiveDeliveryScreen(
      riderId: widget.riderId,
      order: _activeOrder,
      isLoading: _loadingActive,
      onDeliveryComplete: () {
        setState(() => _activeOrder = null);
        _loadActiveOrder();
      },
    ),
    EarningsScreen(riderId: widget.riderId),
    ProfileScreen(riderId: widget.riderId, riderName: widget.riderName),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderColors.bg,
      appBar: AppBar(
        backgroundColor: RiderColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.delivery_dining, size: 22),
            const SizedBox(width: 8),
            const Text('Rider', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => setState(() => _isOnline = !_isOnline),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.white : Colors.white60,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 0) _loadActiveOrder();
          setState(() => _currentIndex = i);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: RiderColors.blue,
        unselectedItemColor: RiderColors.muted,
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'งานใหม่',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.directions_bike_rounded),
                if (_activeOrder != null)
                  Positioned(
                    right: -4, top: -4,
                    child: Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(color: RiderColors.blue, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            label: 'กำลังส่ง',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'รายได้',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
