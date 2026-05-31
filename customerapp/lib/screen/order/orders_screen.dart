import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../l10n/strings.dart';
import '../../utils/responsive.dart';
import '../../config.dart';
import '../../cart_manager.dart';
import '../../services/customer_service.dart';
import 'order_tracking_screen.dart';
import 'dispute_screen.dart';
import '../cart/cart_screen.dart';
import '../chat/chat_screen.dart';
import '../chat/review_screen.dart';

class OrdersScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;
  const OrdersScreen({super.key, required this.customerId, this.customerName = 'ลูกค้า', this.customerPhone = ''});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

const _kOngoingStatuses = {'pending', 'accepted', 'preparing', 'ready', 'delivering', 'picking_up', 'at_store'};

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  Timer? _timer;
  late TabController _tab;

  static bool _isToday(dynamic dateStr) {
    if (dateStr == null) return false;
    final d = DateTime.tryParse(dateStr.toString());
    if (d == null) return false;
    final local = d.toLocal();
    final now = DateTime.now();
    return local.year == now.year && local.month == now.month && local.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this, initialIndex: 0);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final orders = await CustomerService.getOrders(widget.customerId);
    if (!mounted) return;
    setState(() { _orders = orders; _loading = false; });
  }

  List<Map<String, dynamic>> get _ongoing => _orders.where((o) {
        final status = o['status'] as String? ?? '';
        return _kOngoingStatuses.contains(status) && _isToday(o['created_at']);
      }).toList();

  List<Map<String, dynamic>> get _history => _orders.where((o) {
        final status = o['status'] as String? ?? '';
        return !_kOngoingStatuses.contains(status) || !_isToday(o['created_at']);
      }).toList();

  void _goTracking(String orderId) => Navigator.push(
    context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));

  Future<void> _goReview(Map<String, dynamic> order) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(
        orderId: order['id'].toString(),
        customerId: widget.customerId,
        customerName: widget.customerName,
        storeId: order['store_id']?.toString() ?? '',
        storeName: order['store_name']?.toString() ?? 'ร้านอาหาร',
        riderId: order['rider_id']?.toString(),
      )),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(children: [
          // ── AppBar ────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(context.wp(20), context.wp(16), context.wp(20), context.wp(8)),
            child: Row(children: [
              Navigator.canPop(context)
                  ? _CircleBtn(icon: Icons.chevron_left_rounded, onTap: () => Navigator.pop(context))
                  : SizedBox(width: context.wp(40)),
              const Spacer(),
              Text(S.myOrders, style: TextStyle(fontSize: context.sp(18), fontWeight: FontWeight.w800, color: context.fg)),
              const Spacer(),
              SizedBox(width: context.wp(40)),
            ]),
          ),

          // ── Tabs ──────────────────────────────────────────────────────
          TabBar(
            controller: _tab,
            labelColor: CColors.orange,
            unselectedLabelColor: CColors.muted,
            labelStyle: TextStyle(fontSize: context.sp(15), fontWeight: FontWeight.w700),
            unselectedLabelStyle: TextStyle(fontSize: context.sp(15), fontWeight: FontWeight.w500),
            indicatorColor: CColors.orange,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: context.divider,
            tabs: [Tab(text: S.ongoing), Tab(text: S.history)],
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: CColors.orange))
                : TabBarView(
                    controller: _tab,
                    children: [
                      _OrderList(orders: _ongoing, onTap: _goTracking, onReview: _goReview,
                          customerId: widget.customerId, customerName: widget.customerName,
                          customerPhone: widget.customerPhone,
                          emptyMsg: S.noOngoing, onRefresh: _load),
                      _OrderList(orders: _history, onTap: _goTracking, onReview: _goReview,
                          customerId: widget.customerId, customerName: widget.customerName,
                          customerPhone: widget.customerPhone,
                          emptyMsg: S.noHistory, onRefresh: _load),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─── Order List ───────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final Function(String) onTap;
  final Function(Map<String, dynamic>) onReview;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String emptyMsg;
  final Future<void> Function() onRefresh;
  const _OrderList({
    required this.orders, required this.onTap, required this.onReview,
    required this.customerId, required this.customerName,
    required this.customerPhone,
    required this.emptyMsg, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: context.wp(80), height: context.wp(80),
            decoration: BoxDecoration(color: context.orangeLight, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded, color: CColors.orange, size: context.wp(40)),
          ),
          SizedBox(height: context.wp(16)),
          Text(emptyMsg, style: TextStyle(fontSize: context.sp(16), fontWeight: FontWeight.w600, color: context.fg)),
          SizedBox(height: context.wp(8)),
          Text(S.orderFood, style: TextStyle(color: context.muted, fontSize: context.sp(13))),
        ]),
      );
    }
    return RefreshIndicator(
      color: CColors.orange,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(context.wp(16), context.wp(16), context.wp(16), context.wp(16)),
        itemCount: orders.length,
        itemBuilder: (_, i) => _OrderCard(
          order: orders[i],
          customerId: customerId,
          customerName: customerName,
          customerPhone: customerPhone,
          onTap: () => onTap(orders[i]['id'].toString()),
          onReview: () => onReview(orders[i]),
          onRefresh: onRefresh,
        ),
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final VoidCallback onTap;
  final VoidCallback onReview;
  final Future<void> Function() onRefresh;
  const _OrderCard({
    required this.order, required this.onTap, required this.onReview,
    required this.customerId, required this.customerName,
    required this.customerPhone,
    required this.onRefresh,
  });
  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _cancelling = false;
  bool _reordering = false;

  Future<void> _reorder() async {
    final order = widget.order;
    final orderId = order['id']?.toString() ?? '';
    final storeId = order['store_id']?.toString() ?? '';
    setState(() => _reordering = true);
    try {
      final detail = await CustomerService.getOrderDetail(orderId);
      final menuData = await CustomerService.getMenu(storeId);
      if (!mounted) return;
      if (detail == null || menuData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถโหลดข้อมูลร้านได้')),
        );
        return;
      }
      final menuItems = (menuData['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final promos = await CustomerService.getActivePromos(storeId);
      CartManager.instance.clear();
      CartManager.instance.syncMenu(
        {'id': storeId, 'name': order['store_name'] ?? ''},
        menuItems, promos,
      );
      final orderItems = (detail['items'] as List? ?? []);
      for (final item in orderItems) {
        final itemId = (item['menu_item_id'] ?? item['item_id'] ?? item['id'])?.toString();
        final qty = int.tryParse((item['quantity'] ?? item['qty'] ?? 1).toString()) ?? 1;
        if (itemId == null) continue;
        final found = menuItems.firstWhere(
          (m) => m['id'].toString() == itemId,
          orElse: () => {},
        );
        if (found.isNotEmpty) {
          CartManager.instance.setItem(int.parse(itemId), qty);
        }
      }
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CartScreen(
          customerId: widget.customerId,
          customerName: widget.customerName,
          customerPhone: widget.customerPhone,
        ),
      ));
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  Future<void> _cancel() async {
    final orderId = widget.order['id']?.toString() ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(S.cancelQ, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(S.cancelMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.no, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.cancelOrder, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _cancelling = true);
    final ok = await CustomerService.cancelOrder(orderId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (ok) {
      await widget.onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.cancelFailed)),
      );
    }
  }

  static const _statusLabel = {
    'pending': 'Pending', 'accepted': 'Accepted', 'preparing': 'Preparing',
    'ready': 'Ready', 'delivering': 'On the Way',
    'completed': 'Completed', 'cancelled': 'Cancelled',
  };

  Color _statusColor(String s) {
    if (s == 'completed') return CColors.green;
    if (s == 'cancelled') return CColors.red;
    return CColors.orange;
  }

  static bool _isToday(dynamic dateStr) {
    if (dateStr == null) return false;
    final d = DateTime.tryParse(dateStr.toString());
    if (d == null) return false;
    final local = d.toLocal();
    final now = DateTime.now();
    return local.year == now.year && local.month == now.month && local.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final fmt = NumberFormat('#,##0.00');
    final total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0;
    final rawStatus = order['status'] as String? ?? 'pending';
    final isOldPending = _kOngoingStatuses.contains(rawStatus) && !_isToday(order['created_at']);
    final status = isOldPending ? 'completed' : rawStatus;
    final isPending = rawStatus == 'pending';
    final sColor = _statusColor(status);
    final date = DateTime.tryParse(order['created_at'] ?? '');
    final dateStr = date != null ? DateFormat('dd MMM, HH:mm').format(date) : '';
    final summary = order['items_summary']?.toString() ?? '';
    final orderId = order['orderNumber']?.toString() ?? '#${order['id']?.toString().substring(0, 8).toUpperCase() ?? '------'}';
    final rawImage = order['store_image']?.toString();
    final imageUrl = rawImage == null
        ? null
        : rawImage.startsWith('http')
            ? rawImage.replaceFirst(RegExp(r'http://localhost:\d+'), kBackendUrl)
            : '$kBackendUrl$rawImage';

    return Container(
      margin: EdgeInsets.only(bottom: context.wp(16)),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Status header ─────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(context.wp(16), context.wp(14), context.wp(16), context.wp(10)),
          child: Row(children: [
            Text('Food', style: TextStyle(fontSize: context.sp(13), color: context.muted, fontWeight: FontWeight.w500)),
            SizedBox(width: context.wp(8)),
            Text(_statusLabel[status] ?? status,
                style: TextStyle(fontSize: context.sp(13), fontWeight: FontWeight.w700, color: sColor)),
          ]),
        ),
        Divider(height: 1, color: context.divider),

        // ── Main row ──────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.all(context.wp(14)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(context.wp(14)),
              child: imageUrl != null
                  ? Image.network(imageUrl, width: context.wp(72), height: context.wp(72), fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _Thumb())
                  : _Thumb(),
            ),
            SizedBox(width: context.wp(12)),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(order['store_name'] ?? '-',
                        style: TextStyle(fontSize: context.sp(15), fontWeight: FontWeight.w700, color: context.fg),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(width: context.wp(6)),
                  Text(orderId, style: TextStyle(fontSize: context.sp(11), color: context.muted)),
                ]),
                SizedBox(height: context.wp(4)),
                Text('฿${fmt.format(total)}',
                    style: TextStyle(fontSize: context.sp(15), fontWeight: FontWeight.w800, color: context.fg)),
                SizedBox(height: context.wp(3)),
                if (summary.isNotEmpty)
                  Text(summary,
                      style: TextStyle(fontSize: context.sp(12), color: context.muted),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                if (dateStr.isNotEmpty) ...[
                  SizedBox(height: context.wp(2)),
                  Text(dateStr, style: TextStyle(fontSize: context.sp(11), color: context.muted)),
                ],
              ]),
            ),
          ]),
        ),

        // ── Buttons ────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(context.wp(14), 0, context.wp(14), context.wp(14)),
          child: Row(children: [
            Builder(builder: (ctx) {
              final oid = order['id']?.toString() ?? '';
              final storeName = order['store_name']?.toString() ?? 'ร้านอาหาร';
              return GestureDetector(
                onTap: oid.isEmpty ? null : () => Navigator.push(ctx,
                  MaterialPageRoute(builder: (_) => ChatScreen(
                    orderId: oid,
                    customerId: widget.customerId,
                    customerName: widget.customerName,
                    storeName: storeName,
                    chatType: 'store',
                  ))),
                child: Container(
                  width: context.wp(42), height: context.wp(42),
                  decoration: BoxDecoration(
                    color: context.orangeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.store_rounded, color: CColors.orange, size: context.wp(20)),
                ),
              );
            }),
            SizedBox(width: context.wp(8)),
            if ({'delivering', 'at_store', 'picking_up'}.contains(rawStatus))
              Builder(builder: (ctx) {
                final oid = order['id']?.toString() ?? '';
                final storeName = order['store_name']?.toString() ?? 'ร้านอาหาร';
                return GestureDetector(
                  onTap: oid.isEmpty ? null : () => Navigator.push(ctx,
                    MaterialPageRoute(builder: (_) => ChatScreen(
                      orderId: oid,
                      customerId: widget.customerId,
                      customerName: widget.customerName,
                      storeName: storeName,
                      chatType: 'rider',
                    ))),
                  child: Container(
                    width: context.wp(42), height: context.wp(42),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.directions_bike_rounded, color: const Color(0xFF1976D2), size: context.wp(20)),
                  ),
                );
              }),
            if ({'delivering', 'at_store', 'picking_up'}.contains(rawStatus))
              SizedBox(width: context.wp(8)),
            Expanded(child: Builder(builder: (ctx) {
              final isCompleted = status == 'completed';
              final isReviewed = (order['is_reviewed'] == 1 || order['is_reviewed'] == true);
              if (isCompleted && isReviewed) {
                return Container(
                  height: context.wp(42),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CColors.green.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_rounded, color: CColors.green, size: context.wp(15)),
                    SizedBox(width: context.wp(4)),
                    Text(S.rated, style: TextStyle(color: CColors.green, fontWeight: FontWeight.w600, fontSize: context.sp(13))),
                  ]),
                );
              }
              return OutlinedButton(
                onPressed: isCompleted ? widget.onReview : widget.onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CColors.orange,
                  side: const BorderSide(color: CColors.orange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: context.wp(10)),
                ),
                child: Text(isCompleted ? S.rate : S.track,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.sp(14))),
              );
            })),
            const SizedBox(width: 10),
            Expanded(
              child: isPending
                  ? ElevatedButton(
                      onPressed: _cancelling ? null : _cancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: context.wp(10)),
                      ),
                      child: _cancelling
                          ? SizedBox(width: context.wp(16), height: context.wp(16),
                              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                          : Text(S.cancelOrder, style: TextStyle(fontWeight: FontWeight.w700, fontSize: context.sp(14))),
                    )
                  : ElevatedButton(
                      onPressed: _reordering ? null : _reorder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: context.wp(10)),
                      ),
                      child: _reordering
                          ? SizedBox(width: context.wp(16), height: context.wp(16),
                              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(S.reorder, style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.sp(14))),
                    ),
            ),
          ]),
        ),
        if (status == 'completed')
          Padding(
            padding: EdgeInsets.fromLTRB(context.wp(14), 0, context.wp(14), context.wp(14)),
            child: GestureDetector(
              onTap: () {
                final oid  = order['id']?.toString() ?? '';
                final orderNum = order['orderNumber']?.toString() ?? '#$oid';
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DisputeScreen(
                    orderId: oid,
                    customerId: widget.customerId,
                    orderNumber: orderNum,
                  ),
                ));
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: context.wp(11)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.report_problem_rounded, size: context.wp(15), color: Colors.red),
                  SizedBox(width: context.wp(6)),
                  Text(S.reportOrder,
                      style: TextStyle(color: Colors.red, fontSize: context.sp(13), fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Thumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: context.wp(72), height: context.wp(72),
    color: context.orangeLight,
    child: Center(child: Icon(Icons.restaurant_rounded, color: CColors.orange, size: context.wp(30))),
  );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: context.wp(40), height: context.wp(40),
      decoration: BoxDecoration(color: context.subtleBg, shape: BoxShape.circle),
      child: Icon(icon, color: context.fg, size: context.wp(22)),
    ),
  );
}
