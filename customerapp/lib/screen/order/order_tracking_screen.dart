import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../config.dart';
import '../../main.dart';
import '../../services/customer_service.dart';
import '../../services/order_notification_service.dart';
import '../../services/socket_service.dart';
import '../chat/chat_screen.dart';
import '../chat/call_screen.dart';
import 'dispute_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});
  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _error = false;
  bool _cancelling = false;
  StreamSubscription<Map<String, dynamic>>? _orderSub;

  static const _steps = [
    {'key': 'pending',    'label': 'สั่งแล้ว',    'icon': Icons.receipt_long_rounded},
    {'key': 'accepted',   'label': 'ร้านรับ',     'icon': Icons.store_rounded},
    {'key': 'preparing',  'label': 'กำลังทำ',    'icon': Icons.restaurant_rounded},
    {'key': 'ready',      'label': 'พร้อมส่ง',   'icon': Icons.inventory_2_rounded},
    {'key': 'picking_up', 'label': 'กำลังส่ง',   'icon': Icons.delivery_dining_rounded},
    {'key': 'completed',  'label': 'ส่งแล้ว',    'icon': Icons.home_rounded},
  ];

  static const _statusMsg = {
    'pending':    'รอร้านอาหารยืนยัน...',
    'accepted':   'ร้านรับออเดอร์แล้ว กำลังเตรียม',
    'preparing':  'กำลังทำอาหาร รอสักครู่...',
    'ready':      'อาหารพร้อม กำลังรอไรเดอร์',
    'delivering': 'ไรเดอร์กำลังนำอาหารมาส่ง!',
    'picking_up': 'ไรเดอร์กำลังนำอาหารมาส่ง!',
    'completed':  'ส่งอาหารเรียบร้อยแล้ว ขอบคุณ 😊',
    'cancelled':  'ออเดอร์ถูกยกเลิก',
  };

  static const _statusIcon = {
    'pending':    Icons.access_time_rounded,
    'accepted':   Icons.check_circle_rounded,
    'preparing':  Icons.restaurant_rounded,
    'ready':      Icons.inventory_2_rounded,
    'delivering': Icons.delivery_dining_rounded,
    'picking_up': Icons.delivery_dining_rounded,
    'completed':  Icons.lunch_dining,
    'cancelled':  Icons.cancel_rounded,
  };

  @override
  void initState() {
    super.initState();
    _load();
    SocketService.instance.connect();
    SocketService.instance.joinOrder(widget.orderId);
    _orderSub = SocketService.instance.orderUpdates.listen((data) {
      if (!mounted) return;
      if (data['order_id']?.toString() == widget.orderId) _load();
    });
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    SocketService.instance.leaveOrder(widget.orderId);
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = false; });
    try {
      final data = await CustomerService.getOrderDetail(widget.orderId)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() { _order = data; _loading = false; _error = data == null; });
      if (data != null) {
        OrderNotificationService.instance.syncFromTracking(widget.orderId, data);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = true; });
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยกเลิกออเดอร์?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('ออเดอร์ยังไม่ได้รับการยืนยันจากร้าน\nต้องการยกเลิกใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ไม่', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยกเลิกออเดอร์',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _cancelling = true);
    final ok = await CustomerService.cancelOrder(widget.orderId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยกเลิกไม่สำเร็จ กรุณาลองใหม่')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawStatus = _order?['status'] ?? 'pending';
    final status = rawStatus == 'delivering' ? 'picking_up' : rawStatus;
    final stepIdx = _steps.indexWhere((s) => s['key'] == status);
    final isActive = !['completed', 'cancelled', 'picking_up'].contains(status);

    return Scaffold(
      backgroundColor: CColors.bg,
      body: _loading && _order == null
          ? const Center(child: CircularProgressIndicator(color: CColors.orange))
          : _error && _order == null
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: CColors.muted),
                    const SizedBox(height: 12),
                    const Text('โหลดข้อมูลไม่สำเร็จ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CColors.text)),
                    const SizedBox(height: 6),
                    const Text('กรุณาตรวจสอบการเชื่อมต่อ', style: TextStyle(fontSize: 13, color: CColors.muted)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(backgroundColor: CColors.orange, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('ลองใหม่'),
                    ),
                  ]),
                )
              : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  foregroundColor: CColors.text,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.black12,
                  elevation: 1,
                  title: Text('ออเดอร์ #${widget.orderId}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: CColors.text, fontSize: 15)),
                  actions: [
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(right: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          _PulseDot(),
                          const SizedBox(width: 6),
                          const Text('LIVE', style: TextStyle(color: CColors.orange, fontSize: 11, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                  ],
                ),
                if (_order != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _buildBanner(status),
                        const SizedBox(height: 16),
                        _buildTimeline(stepIdx, status),
                        if (status == 'pending') ...[
                          const SizedBox(height: 16),
                          _buildCancelButton(),
                        ],
                        if (status == 'completed') ...[
                          const SizedBox(height: 16),
                          _buildDisputeButton(),
                        ],
                        if (status == 'picking_up') ...[
                          const SizedBox(height: 16),
                          _buildRiderCard(),
                        ],
                        if (!['cancelled'].contains(status)) ...[
                          const SizedBox(height: 16),
                          _MapCard(
                            storeAddress: _order!['store_address'] ?? '',
                            deliveryAddress: _order!['address'] ?? '',
                            hasRider: _order!['rider_id'] != null,
                            riderPhotoUrl: () {
                              final p = _order!['rider_photo']?.toString();
                              return (p != null && p.isNotEmpty) ? '$kBackendUrl$p' : null;
                            }(),
                            riderName: _order!['rider_name']?.toString() ?? '',
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildInfoCard('ร้านอาหาร', [
                          _InfoRow(Icons.store_rounded, _order!['store_name'] ?? '-', bold: true),
                          const SizedBox(height: 4),
                          _InfoRow(Icons.location_on_rounded, _order!['store_address'] ?? '-'),
                        ]),
                        const SizedBox(height: 12),
                        _buildInfoCard('ที่อยู่จัดส่ง', [
                          _InfoRow(Icons.home_rounded, _order!['address'] ?? '-', bold: true),
                          if ((_order!['note'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _InfoRow(Icons.note_rounded, _order!['note']),
                          ],
                        ]),
                        const SizedBox(height: 12),
                        _buildItemsCard(),
                        const SizedBox(height: 12),
                        _buildTotalCard(),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildRiderCard() {
    final riderName  = _order?['rider_name']?.toString() ?? 'ไรเดอร์';
    final riderPhoto = _order?['rider_photo']?.toString();
    final photoUrl   = (riderPhoto != null && riderPhoto.isNotEmpty)
        ? '$kBackendUrl$riderPhoto'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10)],
      ),
      child: Row(children: [
        _RiderAvatar(photoUrl: photoUrl, name: riderName, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(riderName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CColors.text)),
            const SizedBox(height: 2),
            const Text('ไรเดอร์ของคุณ', style: TextStyle(fontSize: 12, color: CColors.muted)),
          ]),
        ),
        GestureDetector(
          onTap: _order == null ? null : () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChatScreen(
              orderId: widget.orderId,
              customerId: _order!['customer_id']?.toString() ?? '',
              customerName: _order!['customer_name']?.toString() ?? 'ลูกค้า',
              storeName: _order!['store_name']?.toString() ?? 'ร้านอาหาร',
            ),
          )),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.chat_bubble_rounded, color: CColors.orange, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CallScreen())),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: CColors.orange, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _cancelling ? null : _cancelOrder,
        icon: _cancelling
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
            : const Icon(Icons.cancel_rounded, size: 18),
        label: Text(_cancelling ? 'กำลังยกเลิก...' : 'ยกเลิกออเดอร์',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEBEE),
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildDisputeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final customerId = _order?['customer_id']?.toString() ?? '';
          final orderNum   = _order?['order_number']?.toString() ?? widget.orderId;
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => DisputeScreen(
              orderId:     widget.orderId,
              customerId:  customerId,
              orderNumber: orderNum,
            ),
          ));
        },
        icon: const Icon(Icons.report_problem_rounded, size: 18),
        label: const Text('แจ้งปัญหาออเดอร์นี้',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEBEE),
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildBanner(String status) {
    final cancelled = status == 'cancelled';
    final iconColor = cancelled ? CColors.muted : CColors.orange;
    final bgColor = cancelled ? const Color(0xFFF5F5F5) : CColors.orangeLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cancelled ? const Color(0xFFE0E0E0) : CColors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: cancelled ? Colors.white : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 2)],
          ),
          child: Icon(_statusIcon[status] ?? Icons.info_rounded, color: iconColor, size: 32),
        ),
        const SizedBox(height: 12),
        Text(_statusMsg[status] ?? status,
            style: TextStyle(color: cancelled ? CColors.muted : CColors.text, fontSize: 15, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildTimeline(int stepIdx, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10)]),
      child: Column(
        children: List.generate(_steps.length, (i) {
          final step = _steps[i];
          final done = i <= stepIdx && status != 'cancelled';
          final active = i == stepIdx && status != 'cancelled';
          final isLast = i == _steps.length - 1;
          final dotColor = active
              ? CColors.orange
              : done
                  ? const Color(0xFF9E9E9E)
                  : const Color(0xFFEEEEEE);
          final iconColor = active
              ? Colors.white
              : done
                  ? Colors.white
                  : CColors.muted;
          final lineColor = i < stepIdx ? const Color(0xFFBDBDBD) : const Color(0xFFEEEEEE);

          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: active ? Border.all(color: CColors.orange, width: 2.5) : null,
                ),
                child: Icon(step['icon'] as IconData, size: 17, color: iconColor),
              ),
              if (!isLast) Container(width: 2, height: 30, color: lineColor),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 30),
                child: Row(children: [
                  Text(step['label'] as String, style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? CColors.orange : done ? CColors.text : CColors.muted)),
                  if (done && !active) ...[
                    const Spacer(),
                    const Icon(Icons.check_rounded, color: Color(0xFF9E9E9E), size: 16),
                  ],
                ]),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CColors.muted, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }

  List<Map<String, dynamic>> get _items {
    final raw = _order?['items'];
    if (raw == null) return [];
    return (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Widget _buildItemsCard() {
    final items = _items;
    final fmt = NumberFormat('#,##0.00');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('รายการอาหาร', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CColors.muted, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        ...items.map((item) {
          final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
          final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('$qty', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CColors.orange))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item['name']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: CColors.text))),
              Text('฿${fmt.format(price * qty)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.text)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildTotalCard() {
    final fmt = NumberFormat('#,##0.00');
    final items = _items;
    final subtotal = items.fold<double>(0, (s, i) => s + (double.tryParse(i['price']?.toString() ?? '0') ?? 0) * (int.tryParse(i['quantity']?.toString() ?? '1') ?? 1));
    final fee = double.tryParse(_order?['delivery_fee']?.toString() ?? '30') ?? 30;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        _TotalRow('ค่าอาหาร', '฿${fmt.format(subtotal)}'),
        const SizedBox(height: 4),
        _TotalRow('ค่าจัดส่ง', '฿${fmt.format(fee)}'),
        const Divider(height: 16, color: CColors.orangeMid),
        _TotalRow('รวมทั้งหมด', '฿${fmt.format(subtotal + fee)}', bold: true),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String? text;
  final bool bold;
  const _InfoRow(this.icon, this.text, {this.bold = false});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 14, color: CColors.orange),
    const SizedBox(width: 8),
    Expanded(child: Text(text ?? '-', style: TextStyle(fontSize: 13, color: CColors.text, fontWeight: bold ? FontWeight.w600 : FontWeight.normal))),
  ]);
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _TotalRow(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) {
    final s = TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? CColors.text : CColors.muted);
    return Row(children: [Text(label, style: s), const Spacer(), Text(value, style: s.copyWith(color: bold ? CColors.orange : null))]);
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
  );
}

// ─── Rider Avatar ─────────────────────────────────────────────────────────────

class _RiderAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  const _RiderAvatar({this.photoUrl, required this.name, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'R';
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(initial),
        ),
      );
    }
    return _fallback(initial);
  }

  Widget _fallback(String initial) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
    child: Center(
      child: Text(initial,
          style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w700, color: CColors.orange)),
    ),
  );
}

// ─── Delivery Map Card ─────────────────────────────────────────────────────────

class _MapCard extends StatefulWidget {
  final String storeAddress;
  final String deliveryAddress;
  final String? riderPhotoUrl;
  final String riderName;
  final bool hasRider;
  const _MapCard({
    required this.storeAddress,
    required this.deliveryAddress,
    this.riderPhotoUrl,
    this.riderName = '',
    this.hasRider = false,
  });

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> {
  static const _kBangkok = LatLng(13.7563, 100.5018);
  final _mapController = MapController();

  LatLng? _storeLoc;
  LatLng? _custLoc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final locs = await Future.wait([
      _geocode(widget.storeAddress),
      _geocode(widget.deliveryAddress),
    ]);
    if (!mounted) return;
    setState(() {
      _storeLoc = locs[0];
      _custLoc  = locs[1];
      _loading  = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pts = [_storeLoc, _custLoc].whereType<LatLng>().toList();
      if (pts.length >= 2) {
        _mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(pts),
          padding: const EdgeInsets.all(50),
        ));
      }
    });
  }

  Future<LatLng?> _geocode(String address) async {
    if (address.isEmpty) return null;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': address, 'format': 'json', 'limit': '1', 'countrycodes': 'th',
      });
      final res = await http
          .get(uri, headers: {'User-Agent': 'ZestAndSavory/1.0'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      return LatLng(double.parse(list[0]['lat']), double.parse(list[0]['lon']));
    } catch (_) {
      return null;
    }
  }

  Widget _riderFallbackIcon() {
    final initial = widget.riderName.isNotEmpty ? widget.riderName[0].toUpperCase() : 'R';
    return Container(
      color: CColors.orangeLight,
      child: Center(
        child: Text(initial, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CColors.orange)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: _loading
          ? Container(
              color: CColors.orangeLight,
              child: const Center(child: CircularProgressIndicator(color: CColors.orange)),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _storeLoc ?? _kBangkok,
                initialZoom: 13,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.customerapp',
                ),
                MarkerLayer(markers: [
                  if (_storeLoc != null)
                    Marker(
                      point: _storeLoc!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
                        child: const Icon(Icons.store_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  if (_custLoc != null)
                    Marker(
                      point: _custLoc!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                        child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  if (widget.hasRider && _storeLoc != null)
                    Marker(
                      point: _storeLoc!,
                      width: 52,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: CColors.orange, width: 2.5),
                          boxShadow: [BoxShadow(color: CColors.orange.withValues(alpha: 0.35), blurRadius: 8)],
                        ),
                        child: ClipOval(
                          child: widget.riderPhotoUrl != null
                              ? Image.network(
                                  widget.riderPhotoUrl!,
                                  width: 52, height: 52, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _riderFallbackIcon(),
                                )
                              : _riderFallbackIcon(),
                        ),
                      ),
                    ),
                ]),
              ],
            ),
    );
  }
}
