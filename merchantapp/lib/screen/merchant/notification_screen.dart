import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import 'orders_screen.dart';

class MerchantNotificationScreen extends StatefulWidget {
  const MerchantNotificationScreen({super.key});
  @override
  State<MerchantNotificationScreen> createState() => _MerchantNotificationScreenState();
}

class _MerchantNotificationScreenState extends State<MerchantNotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Order> _orders = [];
  bool _loading = true;

  static const _mockMessages = [
    {'name': 'Royal Parvej', 'msg': 'Sounds awesome!', 'time': '19:37', 'unread': 1, 'online': true},
    {'name': 'Cameron Williamson', 'msg': 'Ok, Just hurry up little bit...🙂', 'time': '19:37', 'unread': 2, 'online': true},
    {'name': 'Ralph Edwards', 'msg': 'Thanks dude.', 'time': '19:37', 'unread': 0, 'online': true},
    {'name': 'Cody Fisher', 'msg': 'How is going...?', 'time': '19:37', 'unread': 0, 'online': true},
    {'name': 'Eleanor Pena', 'msg': 'Thanks for the awesome food man...!', 'time': '19:37', 'unread': 0, 'online': false},
  ];

  int get _unreadCount => _mockMessages.fold(0, (s, m) => s + (m['unread'] as int));

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await ApiService.getOrders(status: 'active');
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd/MM').format(date);
  }

  String _actionText(String status) => const {
    'pending': 'Placed a new order',
    'accepted': 'Order accepted',
    'preparing': 'Order is being prepared',
    'ready': 'Order is ready',
    'completed': 'Order completed',
    'cancelled': 'agreed to cancel',
  }[status] ?? status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF1A1A1A)),
          ),
        ),
        title: Text(
          _tab.index == 0 ? 'Notifications' : 'Messages',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1A1A1A)),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.orange,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          indicatorColor: AppColors.orange,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2.5,
          tabs: [
            const Tab(text: 'Notifications'),
            Tab(text: 'Messages ($_unreadCount)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildNotificationsTab(), _buildMessagesTab()],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    if (_orders.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: AppColors.orangeLight, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded, color: AppColors.orange, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('No notifications yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('New orders will appear here', style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _orders.length,
        itemBuilder: (_, i) {
          final o = _orders[i];
          final imgs = [
            'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=200&h=200&fit=crop',
            'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=200&h=200&fit=crop',
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200&h=200&fit=crop',
          ];
          return _NotifTile(
            name: o.customerName,
            action: _actionText(o.status),
            timeAgo: _timeAgo(o.createdAt),
            foodImgUrl: imgs[i % imgs.length],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: o.id),
            )).then((_) => _load()),
          );
        },
      ),
    );
  }

  Widget _buildMessagesTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _mockMessages.length,
      separatorBuilder: (_, i) => const Divider(height: 1, indent: 76, endIndent: 20),
      itemBuilder: (_, i) {
        final m = _mockMessages[i];
        return _MessageTile(
          name: m['name'] as String,
          lastMsg: m['msg'] as String,
          time: m['time'] as String,
          unread: m['unread'] as int,
          isOnline: m['online'] as bool,
        );
      },
    );
  }
}

// ─── Notification Tile ────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final String name, action, timeAgo, foodImgUrl;
  final VoidCallback onTap;

  const _NotifTile({
    required this.name,
    required this.action,
    required this.timeAgo,
    required this.foodImgUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.orangeLight,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), height: 1.4),
                  children: [
                    TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.orange)),
                    TextSpan(text: ' $action'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(timeAgo, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            ]),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              foodImgUrl,
              width: 52, height: 52,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Container(
                width: 52, height: 52,
                color: AppColors.orangeLight,
                child: const Icon(Icons.fastfood_rounded, color: AppColors.orange, size: 22),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Message Tile ─────────────────────────────────────────────────────────────

class _MessageTile extends StatelessWidget {
  final String name, lastMsg, time;
  final int unread;
  final bool isOnline;

  const _MessageTile({
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.unread,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Stack(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.orangeLight,
            child: Text(initials, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700)),
          ),
          if (isOnline)
            Positioned(
              right: 1, bottom: 1,
              child: Container(
                width: 11, height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 3),
            Text(
              lastMsg,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 6),
          if (unread > 0)
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
              child: Center(
                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      ]),
    );
  }
}
