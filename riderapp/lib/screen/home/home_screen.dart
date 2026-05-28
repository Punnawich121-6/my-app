import 'dart:async';
import 'package:flutter/material.dart';
import '../../config.dart';
import '../../main.dart';
import '../../services/rider_service.dart';
import '../orders/available_orders_screen.dart';
import '../orders/active_delivery_screen.dart';
import '../profile/earnings_screen.dart';
import '../chat/conversations_screen.dart';
import '../profile/profile_screen.dart';

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
  Timer? _refreshTimer;
  String? _riderPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadActiveOrder();
    _loadRiderPhoto();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _silentRefresh());
  }

  Future<void> _loadRiderPhoto() async {
    final profile = await RiderService.getProfile(widget.riderId);
    if (!mounted) return;
    final photo = profile?['profile_photo']?.toString();
    if (photo != null && photo.isNotEmpty) {
      setState(() => _riderPhotoUrl = '$kBackendUrl$photo');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    final order = await RiderService.getActiveDelivery(widget.riderId);
    if (!mounted) return;
    setState(() {
      _activeOrder = order;
      if (order != null && _currentIndex == 0) _currentIndex = 1;
    });
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
      riderName: widget.riderName,
      riderPhotoUrl: _riderPhotoUrl,
      order: _activeOrder,
      isLoading: _loadingActive,
      onDeliveryComplete: () {
        setState(() => _activeOrder = null);
        _loadActiveOrder();
      },
    ),
    EarningsScreen(riderId: widget.riderId),
    RiderConversationsScreen(riderId: widget.riderId, riderName: widget.riderName),
    ProfileScreen(riderId: widget.riderId, riderName: widget.riderName),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: Color(0xFFFF6B35)),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.delivery_dining, size: 22),
            SizedBox(width: 8),
            Text('Rider', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
                  color: _isOnline
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.12),
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
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 0,
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
            _NavItem(
              icon: Icons.search_rounded,
              index: 0,
              currentIndex: _currentIndex,
              onTap: (i) { _loadActiveOrder(); setState(() => _currentIndex = i); },
            ),
            _NavItem(
              icon: Icons.directions_bike_rounded,
              index: 1,
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              hasBadge: _activeOrder != null,
            ),
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              index: 2,
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline_rounded,
              index: 3,
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              index: 4,
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
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
  final bool hasBadge;

  const _NavItem({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.hasBadge = false,
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
                isLabelVisible: hasBadge,
                backgroundColor: RiderColors.blue,
                child: Icon(
                  icon,
                  size: 24,
                  color: isActive ? RiderColors.blue : const Color(0xFFBDBDBD),
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4, height: 4,
                  decoration: const BoxDecoration(
                    color: RiderColors.blue,
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
