import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../app_settings.dart';
import '../../../l10n.dart';
import '../../../main.dart';
import '../../../models/order_model.dart';
import '../../../services/api_service.dart';
import '../chat/chat_screen.dart';
import 'report_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  List<(String, String)> get _tabs => [
    ('active', t('ออเดอร์ปัจจุบัน', 'Current Orders')),
    ('completed', t('เสร็จแล้ว', 'Completed')),
    ('cancelled', t('ยกเลิก', 'Cancelled')),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    AppSettings.instance.addListener(_onSettings);
  }

  void _onSettings() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        appBar: AppBar(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          title: Text(t('ออเดอร์', 'Orders'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          elevation: 0,
          bottom: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: _tabs.map((t) => _OrderList(status: t.$1)).toList(),
        ),
      );
}

class _OrderList extends StatefulWidget {
  final String status;
  const _OrderList({required this.status});
  @override
  State<_OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<_OrderList> with AutomaticKeepAliveClientMixin {
  List<Order> _orders = [];
  bool _loading = true;
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) { if (mounted) _load(); });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await ApiService.getOrders(status: widget.status);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    if (_orders.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.receipt_long_rounded, size: 36, color: AppColors.orange),
          ),
          const SizedBox(height: 14),
          Text(t('ไม่มีออเดอร์', 'No Orders'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text(t('ออเดอร์ใหม่จะแสดงที่นี่', 'New orders will appear here'), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _OrderCard(order: _orders[i], onRefresh: _load),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onRefresh;
  const _OrderCard({required this.order, required this.onRefresh});

  Color get _color => switch (order.status) {
    'completed'  => const Color(0xFF388E3C),
    'cancelled'  => const Color(0xFFE53935),
    _            => AppColors.orange,
  };

  IconData get _icon => switch (order.status) {
    'pending'    => Icons.hourglass_top_rounded,
    'accepted'   => Icons.check_circle_outline_rounded,
    'preparing'  => Icons.restaurant_rounded,
    'ready'      => Icons.done_all_rounded,
    'delivering' => Icons.delivery_dining_rounded,
    'completed'  => Icons.check_circle_rounded,
    _            => Icons.cancel_outlined,
  };

  String get _shortLabel => switch (order.status) {
    'pending'    => t('รอรับ', 'Pending'),
    'accepted'   => t('รับแล้ว', 'Accepted'),
    'preparing'  => t('กำลังทำ', 'Preparing'),
    'ready'      => t('พร้อมส่ง', 'Ready'),
    'delivering' => t('กำลังส่ง', 'Delivering'),
    'completed'  => t('สำเร็จ', 'Completed'),
    _            => t('ยกเลิก', 'Cancelled'),
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final shortId = order.id.split('-').last.toUpperCase();

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)));
        onRefresh();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left accent bar ──
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16), bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // ── Content ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: icon + ID + date + badge
                      Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              '#$shortId',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                            ),
                            Text(
                              DateFormat('HH:mm  ·  d MMM').format(order.createdAt),
                              style: const TextStyle(fontSize: 11, color: AppColors.muted),
                            ),
                          ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withValues(alpha: 0.25)),
                          ),
                          child: Text(_shortLabel, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Container(height: 1, color: const Color(0xFFE0E0E0)),
                      const SizedBox(height: 12),
                      // Customer name
                      Row(children: [
                        const Icon(Icons.person_rounded, size: 15, color: AppColors.muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.customerName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      if (order.itemsSummary != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 21),
                          child: Text(
                            order.itemsSummary!,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Bottom: price + action
                      Row(children: [
                        Text(
                          '฿${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.orange),
                        ),
                        const Spacer(),
                        if (order.next != null) _ActionButton(order: order, onDone: onRefresh),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final Order order;
  final VoidCallback onDone;
  const _ActionButton({required this.order, required this.onDone});
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _loading = false;
  Map<String, String> get _nextLabel => {
    'pending': t('รับออเดอร์', 'Accept Order'),
    'accepted': t('เริ่มทำอาหาร', 'Start Cooking'),
    'preparing': t('พร้อมเสิร์ฟ', 'Ready to Serve'),
  };

  Future<void> _tap() async {
    final next = widget.order.next;
    if (next == null) return;
    setState(() => _loading = true);
    try {
      await ApiService.updateOrderStatus(widget.order.id, next);
      widget.onDone();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 34,
        child: ElevatedButton(
          onPressed: _loading ? null : _tap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: _loading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_nextLabel[widget.order.status] ?? 'Update', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
}

// ─── Order Detail ─────────────────────────────────────────────────────────────

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final o = await ApiService.getOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = o;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await ApiService.updateOrderStatus(widget.orderId, status);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        title: Text(_order == null ? 'Order' : '#${_order!.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _order == null
              ? const Center(child: Text('Order not found'))
              : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final o = _order!;
    final timeline = ['pending', 'accepted', 'preparing', 'ready', 'completed'];
    final statusLabels = Order.statusLabel;
    final currentIdx = timeline.indexOf(o.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _InfoCard(children: [
          _Row(icon: Icons.person_outline, label: t('ลูกค้า', 'Customer'), value: o.customerName),
          if (o.customerPhone != null) _Row(icon: Icons.phone_outlined, label: t('เบอร์โทร', 'Phone'), value: o.customerPhone!),
          if (o.address != null) _Row(icon: Icons.location_on_outlined, label: t('ที่อยู่', 'Address'), value: o.address!),
          if (o.note != null && o.note!.isNotEmpty) _Row(icon: Icons.note_outlined, label: t('หมายเหตุ', 'Note'), value: o.note!),
        ]),
        if (o.address != null) ...[
          const SizedBox(height: 14),
          _DeliveryMapCard(address: o.address!),
        ],
        const SizedBox(height: 14),
        _InfoCard(children: [
          Text(t('รายการอาหาร', 'Items'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
          const SizedBox(height: 10),
          ...o.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Expanded(child: Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: 13, color: AppColors.text))),
                  Text('฿${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
                ]),
              )),
          const Divider(height: 16),
          Row(children: [
            Expanded(child: Text(t('ยอดรวม', 'Total'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text))),
            Text('฿${o.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.orange)),
          ]),
        ]),
        const SizedBox(height: 14),
        if (o.status != 'completed' && o.status != 'cancelled') ...[
          _InfoCard(children: [
            Text(t('สถานะออเดอร์', 'Order Status'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
            const SizedBox(height: 14),
            ...List.generate(timeline.length - 1, (i) {
              final done = i < currentIdx;
              final active = i == currentIdx;
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: done || active ? AppColors.orange : AppColors.orangeMid),
                    child: done
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : active
                            ? const Icon(Icons.radio_button_checked, size: 12, color: Colors.white)
                            : null,
                  ),
                  if (i < timeline.length - 2) Container(width: 2, height: 28, color: done ? AppColors.orange : AppColors.orangeMid),
                ]),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    statusLabels[timeline[i]] ?? timeline[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? AppColors.orange : done ? AppColors.text : AppColors.muted,
                    ),
                  ),
                ),
              ]);
            }),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            if (o.status == 'pending')
              Expanded(child: OutlinedButton(
                onPressed: () => _updateStatus('cancelled'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(t('ปฏิเสธ', 'Reject'), style: const TextStyle(color: Colors.red)),
              )),
            if (o.status == 'pending') const SizedBox(width: 10),
            if (o.status == 'ready')
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.directions_bike_rounded, color: AppColors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(t('รอไรเดอร์มารับอาหาร', 'Waiting for rider pickup'), style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              )),
            if (o.next != null)
              Expanded(child: ElevatedButton(
                onPressed: () => _updateStatus(o.next!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  o.status == 'pending' ? t('รับออเดอร์', 'Accept Order') : t('อัปเดตสถานะ', 'Update Status'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )),
          ]),
        ],
        if (o.status == 'cancelled')
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.cancel_outlined, color: Colors.red),
              const SizedBox(width: 8),
              Text(t('ออเดอร์ถูกยกเลิก', 'Order Cancelled'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ]),
          ),
        if (o.status == 'completed')
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Text(t('ออเดอร์เสร็จเรียบร้อย', 'Order Completed'), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            ]),
          ),
        if (o.status == 'completed' || o.status == 'cancelled') ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => MerchantReportScreen(
                  orderId:     widget.orderId,
                  orderNumber: o.id,
                ),
              )),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.report_problem_rounded, size: 18),
              label: Text(t('แจ้งปัญหาออเดอร์นี้', 'Report Issue'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MerchantChatScreen(
                orderId: widget.orderId,
                customerName: o.customerName,
                chatType: 'store',
              ),
            )),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.orange),
              foregroundColor: AppColors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: Text(t('แชทกับ ${o.customerName}', 'Chat with ${o.customerName}'),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        if (o.riderId != null && o.riderId!.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => MerchantChatScreen(
                  orderId: widget.orderId,
                  customerName: t('ไรเดอร์', 'Rider'),
                  chatType: 'rider',
                ),
              )),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.orange),
                foregroundColor: AppColors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.directions_bike_rounded, size: 18),
              label: Text(t('แชทกับไรเดอร์', 'Chat with Rider'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500))),
        ]),
      );
}

// ─── Delivery Location Map ────────────────────────────────────────────────────

class _DeliveryMapCard extends StatefulWidget {
  final String address;
  const _DeliveryMapCard({required this.address});

  @override
  State<_DeliveryMapCard> createState() => _DeliveryMapCardState();
}

class _DeliveryMapCardState extends State<_DeliveryMapCard> {
  static const _kBangkok = LatLng(13.7563, 100.5018);
  LatLng? _loc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _geocode();
  }

  Future<void> _geocode() async {
    if (widget.address.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': widget.address, 'format': 'json', 'limit': '1', 'countrycodes': 'th',
      });
      final res = await http
          .get(uri, headers: {'User-Agent': 'ZestAndSavory/1.0'})
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (list.isNotEmpty) {
          setState(() {
            _loc = LatLng(double.parse(list[0]['lat']), double.parse(list[0]['lon']));
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.orangeLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }

    final center = _loc ?? _kBangkok;
    return Container(
      height: 180,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 15),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.merchantapp',
          ),
          MarkerLayer(markers: [
            Marker(
              point: center,
              width: 44,
              height: 44,
              child: Container(
                decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
