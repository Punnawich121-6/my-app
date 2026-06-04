import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../app_settings.dart';
import '../../config.dart';
import '../../main.dart';
import '../../services/rider_alert_service.dart';
import '../../services/rider_service.dart';
import '../navigation_screen.dart';
import '../chat/chat_screen.dart';
import 'report_screen.dart';

// ── Delivery steps (local UI state only) ──────────────────────────────────────
enum _OrderStep { goToStore, atStore, delivering }

class ActiveDeliveryScreen extends StatefulWidget {
  final String riderId;
  final String riderName;
  final String? riderPhotoUrl;
  final Map<String, dynamic>? order;
  final bool isLoading;
  final VoidCallback onDeliveryComplete;

  const ActiveDeliveryScreen({
    super.key,
    required this.riderId,
    this.riderName = 'ไรเดอร์',
    this.riderPhotoUrl,
    required this.order,
    required this.isLoading,
    required this.onDeliveryComplete,
  });

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  _OrderStep _step = _OrderStep.goToStore;
  bool _completing = false;
  bool _updatingStep = false;

  @override
  void initState() {
    super.initState();
    _step = _stepFromStatus(widget.order?['status']?.toString());
  }

  @override
  void didUpdateWidget(ActiveDeliveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newId = widget.order?['id']?.toString();
    final oldId = oldWidget.order?['id']?.toString();
    // รีเซ็ต step เมื่อเปลี่ยนงาน (รับงานใหม่ หรือ งานถูกเคลียร์)
    if (newId != oldId) {
      setState(() => _step = _stepFromStatus(widget.order?['status']?.toString()));
    }
  }

  _OrderStep _stepFromStatus(String? status) {
    if (status == 'at_store') return _OrderStep.atStore;
    if (status == 'picking_up') return _OrderStep.delivering;
    // 'delivering' = รับงานแล้ว กำลังไปร้าน, null = ไม่มีงาน
    return _OrderStep.goToStore;
  }

  // ── Get current GPS position ───────────────────────────────────────────────
  Future<Position?> _getPosition() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Update step + location ─────────────────────────────────────────────────
  Future<void> _updateStep(String apiStep, _OrderStep nextStep) async {
    final order = widget.order;
    if (order == null || _updatingStep) return;

    setState(() => _updatingStep = true);

    Position? pos = await _getPosition();

    // DEV: เมื่อกด "ถึงร้านแล้ว" ให้ใช้ location ร้านแทน GPS จริง
    double? lat = pos?.latitude;
    double? lng = pos?.longitude;
    if (kDevMockLocation && apiStep == 'at_store') {
      final storeLat = double.tryParse(order['store_lat']?.toString() ?? '');
      final storeLng = double.tryParse(order['store_lng']?.toString() ?? '');
      if (storeLat != null && storeLng != null) {
        lat = storeLat;
        lng = storeLng;
      }
    }

    await RiderService.updateOrderStep(
      order['id'],
      widget.riderId,
      apiStep,
      lat: lat,
      lng: lng,
    );

    if (!mounted) return;
    setState(() {
      _step = nextStep;
      _updatingStep = false;
    });

    // Fire AI chat to customer in background
    _triggerStepNotification(apiStep, pos);
  }

  // ── Send AI chat message to customer ──────────────────────────────────────
  Future<void> _triggerStepNotification(String apiStep, Position? currentPos) async {
    final order = widget.order;
    if (order == null) return;
    final orderId = order['id']?.toString() ?? '';
    if (orderId.isEmpty) return;

    final storeName    = order['store_name']?.toString()    ?? 'ร้านค้า';
    final customerName = order['customer_name']?.toString() ?? 'ลูกค้า';

    // Calculate ETA to customer (25 km/h city average)
    int? etaMinutes;
    final pos = currentPos ?? await _getPosition();
    if (pos != null) {
      final destLat = double.tryParse(order['delivery_lat']?.toString() ?? '');
      final destLng = double.tryParse(order['delivery_lng']?.toString() ?? '');
      if (destLat != null && destLng != null) {
        final distM = Geolocator.distanceBetween(
            pos.latitude, pos.longitude, destLat, destLng);
        etaMinutes = (distM / 1000 / 25 * 60).ceil().clamp(1, 999);
      }
    }

    // Get AI-generated message (rider → customer perspective)
    final aiMsg = await RiderService.getRiderNotification(
      step: apiStep,
      storeName: storeName,
      customerName: customerName,
      riderName: widget.riderName,
      etaMinutes: etaMinutes,
    );

    final etaSuffix = etaMinutes != null ? ' อีกประมาณ $etaMinutes นาทีนะครับ' : '';
    final fallbacks = {
      'at_store':   'สวัสดีครับ ผมถึงร้านแล้วนะครับ กำลังรับอาหารให้อยู่ 🙏',
      'picking_up': 'รับอาหารเรียบร้อยแล้วครับ กำลังออกเดินทางมาส่งครับ$etaSuffix 🚴',
    };
    final message = aiMsg ?? fallbacks[apiStep] ?? 'อัพเดทสถานะออเดอร์ของคุณแล้วครับ';

    // Send as chat message to customer
    final sent = await RiderService.sendAutoChat(
      orderId: orderId,
      riderId: widget.riderId,
      riderName: widget.riderName,
      message: message,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(
          sent ? 'ส่งข้อความแจ้งลูกค้าแล้ว ✓' : 'ส่งข้อความไม่สำเร็จ',
          style: const TextStyle(fontSize: 13),
        ),
      ]),
      backgroundColor: sent ? RiderColors.blue : Colors.red,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    ));
  }

  // ── Complete delivery & show earnings ─────────────────────────────────────
  Future<void> _completeDelivery() async {
    final order = widget.order;
    if (order == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(rt('ยืนยันส่งสำเร็จ?', 'Confirm delivery?'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(rt('กรุณายืนยันเมื่อส่งอาหารถึงมือลูกค้าแล้ว', 'Please confirm when food has been delivered')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(rt('ยังไม่ส่ง', 'Not yet'),
                style: const TextStyle(color: RiderColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: RiderColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(rt('ยืนยัน', 'Confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _completing = true);
    final success =
        await RiderService.completeDelivery(order['id'], widget.riderId);
    if (!mounted) return;
    setState(() => _completing = false);

    if (success) {
      RiderAlertService.instance.playPaymentSound();
      await _showEarningsSheet(order);
      if (mounted) widget.onDeliveryComplete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(rt('เกิดข้อผิดพลาด กรุณาลองใหม่', 'An error occurred, please try again')),
            backgroundColor: Colors.red),
      );
    }
  }

  // ── Earnings bottom sheet ─────────────────────────────────────────────────
  Future<void> _showEarningsSheet(Map<String, dynamic> order) async {
    final fmt = NumberFormat('#,##0.00');
    final deliveryFee =
        double.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0;
    final totalAmount =
        double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0;
    final foodAmount = totalAmount - deliveryFee;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        decoration: BoxDecoration(
          color: context.rCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: context.rDiv,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: RiderColors.blueLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: RiderColors.blue, size: 40),
          ),
          const SizedBox(height: 12),
          Text(rt('ส่งสำเร็จ!', 'Delivered!'),
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.rFg)),
          const SizedBox(height: 4),
          Text(
              '${rt('ออเดอร์', 'Order')} #${order['orderNumber'] ?? order['id'].toString().substring(0, 8)}',
              style: TextStyle(fontSize: 13, color: context.rMuted)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Text(rt('รายได้ของคุณ', 'Your Earnings'),
                  style: const TextStyle(fontSize: 13, color: Colors.white)),
              const SizedBox(height: 4),
              Text('฿${fmt.format(deliveryFee)}',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              _EarningRow(
                  label: rt('ยอดอาหาร', 'Food amount'),
                  value: '฿${fmt.format(foodAmount)}'),
              const SizedBox(height: 8),
              _EarningRow(
                label: rt('ค่าส่ง (รายได้คุณ)', 'Delivery fee (your income)'),
                value: '฿${fmt.format(deliveryFee)}',
                highlight: true,
              ),
              const SizedBox(height: 8),
              _EarningRow(
                  label: rt('ยอดรวมออเดอร์', 'Order total'),
                  value: '฿${fmt.format(totalAmount)}'),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RiderColors.blueLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.calculate_rounded,
                      color: RiderColors.blue, size: 16),
                  const SizedBox(width: 6),
                  Text(rt('วิธีคิดค่าส่ง', 'Fee calculation'),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: RiderColors.blue)),
                ]),
                const SizedBox(height: 8),
                Text(
                  rt('ค่าส่งพื้นฐาน ฿20 + ระยะทาง × ฿5/กม.\n(ขั้นต่ำ ฿30)',
                     'Base ฿20 + distance × ฿5/km\n(min ฿30)'),
                  style: const TextStyle(
                      fontSize: 12, color: RiderColors.muted, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderColors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(rt('รับเงินแล้ว ปิดหน้าต่าง', 'Got paid, close'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator(color: RiderColors.blue));
    }

    if (widget.order == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: RiderColors.blueLight, shape: BoxShape.circle),
            child: const Icon(Icons.directions_bike_rounded, color: RiderColors.muted, size: 40),
          ),
          const SizedBox(height: 16),
          Text(rt('ไม่มีงานที่กำลังส่ง', 'No active delivery'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.rFg)),
          const SizedBox(height: 8),
          Text(rt('รับงานจากหน้า "งานใหม่"', 'Accept a job from "New Jobs"'), style: TextStyle(color: context.rMuted)),
        ]),
      );
    }

    final order = widget.order!;

    return Column(
      children: [
        _buildStepStrip(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(children: [
              _buildDestCard(order),
              const SizedBox(height: 12),
              _buildCompactDetail(order),
              const SizedBox(height: 12),
              _buildActionRow(order),
              const SizedBox(height: 16),
            ]),
          ),
        ),
        Container(
          color: context.rCard,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: _buildStepAction(context),
        ),
      ],
    );
  }

  // ── Grab-style step strip ────────────────────────────────────────────────
  Widget _buildStepStrip() {
    final stepIdx = _step.index;
    final steps = [
      (Icons.store_rounded, rt('ไปร้าน', 'Go to Store')),
      (Icons.shopping_bag_rounded, rt('รับอาหาร', 'Pick Up')),
      (Icons.directions_bike_rounded, rt('กำลังส่ง', 'Delivering')),
      (Icons.check_circle_rounded, rt('ส่งแล้ว', 'Done')),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.rCard,
        border: Border(bottom: BorderSide(color: context.rDiv, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: i ~/ 2 < stepIdx
                    ? RiderColors.blue
                    : const Color(0xFFEEEEEE),
              ),
            );
          }
          final idx = i ~/ 2;
          final isDone = idx < stepIdx;
          final isActive = idx == stepIdx;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isActive
                    ? RiderColors.blue
                    : const Color(0xFFF0F0F0),
                border: isActive
                    ? Border.all(color: RiderColors.blue, width: 2.5)
                    : null,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : steps[idx].$1,
                size: 16,
                color: isDone || isActive ? Colors.white : const Color(0xFFBDBDBD),
              ),
            ),
            const SizedBox(height: 4),
            Text(steps[idx].$2,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? RiderColors.blue : const Color(0xFFBDBDBD),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                )),
          ]);
        }),
      ),
    );
  }

  // ── Current destination card ─────────────────────────────────────────────
  Widget _buildDestCard(Map<String, dynamic> order) {
    final isDelivering = _step == _OrderStep.delivering;
    final label = isDelivering ? rt('ส่งถึงลูกค้า', 'Deliver to Customer') : (_step == _OrderStep.atStore ? rt('รับอาหารที่ร้าน', 'Pick Up at Store') : rt('ไปรับที่ร้าน', 'Go to Store'));
    final name = isDelivering ? (order['customer_name'] ?? '-') : (order['store_name'] ?? '-');
    final address = isDelivering ? (order['address'] ?? '-') : (order['store_address'] ?? '-');
    final icon = isDelivering ? Icons.home_rounded : Icons.store_rounded;
    final iconBg = isDelivering ? const Color(0xFFE8F5E9) : RiderColors.blueLight;
    final iconColor = isDelivering ? RiderColors.green : RiderColors.blue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.rCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.rDiv, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: context.rMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.rFg)),
          ])),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => NavigationScreen(
                storeAddress: order['store_address'] ?? '-',
                storeName: order['store_name'] ?? '-',
                customerAddress: order['address'] ?? '-',
                customerName: order['customer_name'] ?? '-',
                customerLat: double.tryParse(order['delivery_lat']?.toString() ?? ''),
                customerLng: double.tryParse(order['delivery_lng']?.toString() ?? ''),
                riderPhotoUrl: widget.riderPhotoUrl,
                riderName: widget.riderName,
              ),
            )),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.rCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: RiderColors.blue, width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.navigation_rounded, color: RiderColors.blue, size: 14),
                const SizedBox(width: 5),
                Text(rt('นำทาง', 'Navigate'), style: const TextStyle(color: RiderColors.blue, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Divider(height: 1, color: context.rDiv),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.location_on_rounded, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(address,
              style: TextStyle(fontSize: 13, color: context.rFg, height: 1.45))),
        ]),
      ]),
    );
  }

  // ── Compact order info ────────────────────────────────────────────────────
  Widget _buildCompactDetail(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.rCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.rDiv, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 16, color: RiderColors.muted),
          const SizedBox(width: 8),
          Text(order['customer_name'] ?? '-',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.rFg)),
          const Spacer(),
          const Icon(Icons.phone_outlined, size: 14, color: RiderColors.muted),
          const SizedBox(width: 4),
          Text(order['customer_phone'] ?? '-',
              style: const TextStyle(fontSize: 13, color: RiderColors.muted)),
        ]),
        const SizedBox(height: 10),
        Divider(height: 1, color: context.rDiv),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.receipt_long_rounded, size: 16, color: RiderColors.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(order['items_summary'] ?? '-',
              style: TextStyle(fontSize: 13, color: context.rFg, height: 1.4))),
        ]),
        if ((order['note'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.sticky_note_2_outlined, size: 16, color: RiderColors.muted),
            const SizedBox(width: 8),
            Expanded(child: Text(order['note'],
                style: TextStyle(fontSize: 13, color: context.rMuted, fontStyle: FontStyle.italic))),
          ]),
        ],
      ]),
    );
  }

  // ── Secondary action row ─────────────────────────────────────────────────
  Widget _buildActionRow(Map<String, dynamic> order) {
    return Row(children: [
      Expanded(child: _ActionChip(
        icon: Icons.person_rounded,
        label: rt('ลูกค้า', 'Customer'),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => RiderChatScreen(
            orderId: order['id'].toString(), riderId: widget.riderId,
            riderName: widget.riderName,
            customerName: order['customer_name'] ?? rt('ลูกค้า', 'Customer'),
            storeName: order['store_name'] ?? rt('ร้านค้า', 'Store'),
            chatType: 'rider',
          ),
        )),
      )),
      const SizedBox(width: 8),
      Expanded(child: _ActionChip(
        icon: Icons.store_rounded,
        label: rt('ร้านค้า', 'Store'),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => RiderChatScreen(
            orderId: order['id'].toString(), riderId: widget.riderId,
            riderName: widget.riderName,
            customerName: order['customer_name'] ?? rt('ลูกค้า', 'Customer'),
            storeName: order['store_name'] ?? rt('ร้านค้า', 'Store'),
            chatType: 'store',
          ),
        )),
      )),
      const SizedBox(width: 8),
      Expanded(child: _ActionChip(
        icon: Icons.flag_rounded,
        label: rt('รายงาน', 'Report'),
        color: RiderColors.red,
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => RiderReportScreen(
            orderId: order['id'].toString(),
            orderNumber: order['orderNumber']?.toString() ?? order['id'].toString().substring(0, 8),
            riderId: widget.riderId,
          ),
        )),
      )),
    ]);
  }

  // ── Action button per step ────────────────────────────────────────────────
  ButtonStyle _actionBtnStyle(BuildContext ctx) => ElevatedButton.styleFrom(
        backgroundColor: ctx.rCard,
        foregroundColor: RiderColors.blue,
        disabledBackgroundColor: ctx.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        disabledForegroundColor: RiderColors.blueMid,
        elevation: 0,
        side: const BorderSide(color: RiderColors.blue, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );

  Widget _buildStepAction(BuildContext context) {
    final busy = _updatingStep || _completing;
    if (_step == _OrderStep.goToStore) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: busy ? null : () => _updateStep('at_store', _OrderStep.atStore),
          style: _actionBtnStyle(context),
          icon: busy
              ? SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: RiderColors.blue, strokeWidth: 2))
              : const Icon(Icons.store_rounded, size: 20),
          label: Text(busy ? rt('กำลังอัพเดท...', 'Updating...') : rt('ถึงร้านแล้ว', 'Arrived at Store'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );
    } else if (_step == _OrderStep.atStore) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: busy ? null : () => _updateStep('picking_up', _OrderStep.delivering),
          style: _actionBtnStyle(context),
          icon: busy
              ? SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: RiderColors.blue, strokeWidth: 2))
              : const Icon(Icons.check_rounded, size: 20),
          label: Text(busy ? rt('กำลังอัพเดท...', 'Updating...') : rt('รับอาหารแล้ว ออกเดินทาง', 'Food picked up, heading out'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: busy ? null : _completeDelivery,
          style: _actionBtnStyle(context),
          icon: busy
              ? SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: RiderColors.blue, strokeWidth: 2))
              : const Icon(Icons.flag_rounded, size: 20),
          label: Text(busy ? rt('กำลังบันทึก...', 'Saving...') : rt('ส่งสำเร็จ รับเงิน!', 'Delivered! Get paid!'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );
    }
  }

}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = RiderColors.blue,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: context.rCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.rDiv, width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: context.rFg, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _EarningRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _EarningRow(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: highlight ? Colors.white : Colors.white)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: highlight ? 16 : 13,
                fontWeight:
                    highlight ? FontWeight.w800 : FontWeight.w500,
                color: Colors.white)),
      ]);
}

