import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../services/rider_service.dart';
import '../navigation_screen.dart';

// ── Delivery steps (local UI state only) ──────────────────────────────────────
enum _OrderStep { goToStore, atStore, delivering }

class ActiveDeliveryScreen extends StatefulWidget {
  final String riderId;
  final Map<String, dynamic>? order;
  final bool isLoading;
  final VoidCallback onDeliveryComplete;

  const ActiveDeliveryScreen({
    super.key,
    required this.riderId,
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

  // ── Get current GPS position ───────────────────────────────────────────────
  Future<Position?> _getPosition() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return null;
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

    final pos = await _getPosition();
    await RiderService.updateOrderStep(
      order['id'],
      widget.riderId,
      apiStep,
      lat: pos?.latitude,
      lng: pos?.longitude,
    );

    if (!mounted) return;
    setState(() {
      _step = nextStep;
      _updatingStep = false;
    });
  }

  // ── Complete delivery & show earnings ─────────────────────────────────────────
  Future<void> _completeDelivery() async {
    final order = widget.order;
    if (order == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันส่งสำเร็จ?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('กรุณายืนยันเมื่อส่งอาหารถึงมือลูกค้าแล้ว'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยังไม่ส่ง',
                style: TextStyle(color: RiderColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: RiderColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ยืนยัน'),
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
      await _showEarningsSheet(order);
      if (mounted) widget.onDeliveryComplete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่'),
            backgroundColor: Colors.red),
      );
    }
  }

  // ── Earnings bottom sheet ──────────────────────────────────────────────────────
  Future<void> _showEarningsSheet(Map<String, dynamic> order) async {
    final fmt = NumberFormat('#,##0.00');
    final deliveryFee =
        double.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0;
    final totalAmount =
        double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0;
    final foodAmount = totalAmount - deliveryFee;

    // Simple distance-based fee breakdown: ฿20 base + ฿5/km (approx)
    // We show delivery_fee as actual earning since it's what backend computed.
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Success icon
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
              color: RiderColors.blueLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: RiderColors.blue, size: 40),
          ),
          const SizedBox(height: 12),
          const Text('ส่งสำเร็จ!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: RiderColors.text)),
          const SizedBox(height: 4),
          Text('ออเดอร์ #${order['orderNumber'] ?? order['id'].toString().substring(0, 8)}',
              style: const TextStyle(fontSize: 13, color: RiderColors.muted)),
          const SizedBox(height: 24),

          // Earnings card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C5A), Color(0xFFFF4500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              const Text('รายได้ของคุณ',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 4),
              Text('฿${fmt.format(deliveryFee)}',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              _EarningRow(label: 'ยอดอาหาร', value: '฿${fmt.format(foodAmount)}'),
              const SizedBox(height: 8),
              _EarningRow(
                label: 'ค่าส่ง (รายได้คุณ)',
                value: '฿${fmt.format(deliveryFee)}',
                highlight: true,
              ),
              const SizedBox(height: 8),
              _EarningRow(
                label: 'ยอดรวมออเดอร์',
                value: '฿${fmt.format(totalAmount)}',
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Fee breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RiderColors.blueLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.calculate_rounded, color: RiderColors.blue, size: 16),
                  SizedBox(width: 6),
                  Text('วิธีคิดค่าส่ง',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: RiderColors.blue)),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'ค่าส่งพื้นฐาน ฿20 + ระยะทาง × ฿5/กม.\n(ขั้นต่ำ ฿30)',
                  style: TextStyle(fontSize: 12, color: RiderColors.muted, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderColors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('รับเงินแล้ว ปิดหน้าต่าง',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: RiderColors.blue));
    }

    if (widget.order == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
                color: RiderColors.blueLight, shape: BoxShape.circle),
            child: const Icon(Icons.directions_bike_rounded,
                color: RiderColors.muted, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('ไม่มีงานที่กำลังส่ง',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: RiderColors.text)),
          const SizedBox(height: 8),
          const Text('รับงานจากหน้า "งานใหม่"',
              style: TextStyle(color: RiderColors.muted)),
        ]),
      );
    }

    final order = widget.order!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // ── Step progress ──────────────────────────────────────────────────────
        _buildStepsCard(),
        const SizedBox(height: 16),

        // ── Step action button ─────────────────────────────────────────────────
        _buildStepAction(),
        const SizedBox(height: 16),

        // ── Order detail ───────────────────────────────────────────────────────
        _buildOrderDetail(order),
        const SizedBox(height: 16),

        // ── Buttons: nav + call ────────────────────────────────────────────────
        _buildNavButton(order),
        const SizedBox(height: 8),
        _buildCallButton(),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ── Step progress bar ─────────────────────────────────────────────────────────
  Widget _buildStepsCard() {
    final stepIdx = _step.index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: RiderColors.blue.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        _StepDot(
          icon: Icons.store_rounded,
          label: 'ไปร้าน',
          done: stepIdx > 0,
          active: stepIdx == 0,
        ),
        _StepLine(filled: stepIdx > 0),
        _StepDot(
          icon: Icons.shopping_bag_rounded,
          label: 'ถึงร้าน',
          done: stepIdx > 1,
          active: stepIdx == 1,
        ),
        _StepLine(filled: stepIdx > 1),
        _StepDot(
          icon: Icons.directions_bike_rounded,
          label: 'กำลังส่ง',
          done: stepIdx > 2,
          active: stepIdx == 2,
        ),
        _StepLine(filled: false),
        _StepDot(
          icon: Icons.check_circle_rounded,
          label: 'ส่งแล้ว',
          done: false,
          active: false,
        ),
      ]),
    );
  }

  // ── Action button per step ────────────────────────────────────────────────────
  Widget _buildStepAction() {
    final busy = _updatingStep || _completing;
    if (_step == _OrderStep.goToStore) {
      return SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton.icon(
          onPressed: busy ? null : () => _updateStep('at_store', _OrderStep.atStore),
          style: ElevatedButton.styleFrom(
            backgroundColor: RiderColors.blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: RiderColors.blueMid,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: busy
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.store_rounded, size: 20),
          label: Text(busy ? 'กำลังอัพเดท...' : 'ถึงร้านแล้ว',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );
    } else if (_step == _OrderStep.atStore) {
      return SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton.icon(
          onPressed: busy ? null : () => _updateStep('picking_up', _OrderStep.delivering),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8F00),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFFFCC80),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: busy
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_rounded, size: 20),
          label: Text(busy ? 'กำลังอัพเดท...' : 'รับอาหารแล้ว ออกเดินทาง',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton.icon(
          onPressed: busy ? null : _completeDelivery,
          style: ElevatedButton.styleFrom(
            backgroundColor: RiderColors.blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: RiderColors.blueMid,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: busy
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.flag_rounded, size: 20),
          label: Text(busy ? 'กำลังบันทึก...' : 'ส่งสำเร็จ รับเงิน!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );
    }
  }

  // ── Order detail card ─────────────────────────────────────────────────────────
  Widget _buildOrderDetail(Map<String, dynamic> order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: RiderColors.blue.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('รายละเอียดออเดอร์',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: RiderColors.text)),
        const SizedBox(height: 12),
        _DetailRow(
            icon: Icons.store_rounded,
            label: 'ร้านอาหาร',
            value: order['store_name'] ?? '-'),
        const SizedBox(height: 8),
        _DetailRow(
            icon: Icons.location_on_rounded,
            label: 'รับที่',
            value: order['store_address'] ?? '-',
            accent: true),
        const Divider(height: 20, color: RiderColors.blueLight),
        _DetailRow(
            icon: Icons.person_rounded,
            label: 'ลูกค้า',
            value: order['customer_name'] ?? '-'),
        const SizedBox(height: 8),
        _DetailRow(
            icon: Icons.phone_rounded,
            label: 'เบอร์',
            value: order['customer_phone'] ?? '-'),
        const SizedBox(height: 8),
        _DetailRow(
            icon: Icons.home_rounded,
            label: 'ส่งที่',
            value: order['address'] ?? '-',
            accent: true),
        const Divider(height: 20, color: RiderColors.blueLight),
        _DetailRow(
            icon: Icons.receipt_long_rounded,
            label: 'รายการ',
            value: order['items_summary'] ?? '-'),
        if ((order['note'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          _DetailRow(
              icon: Icons.note_rounded,
              label: 'หมายเหตุ',
              value: order['note']),
        ],
      ]),
    );
  }

  Widget _buildNavButton(Map<String, dynamic> order) => SizedBox(
        width: double.infinity, height: 48,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NavigationScreen(
                storeAddress: order['store_address'] ?? '-',
                storeName: order['store_name'] ?? '-',
                customerAddress: order['address'] ?? '-',
                customerName: order['customer_name'] ?? '-',
                customerLat: double.tryParse(
                    order['delivery_lat']?.toString() ?? ''),
                customerLng: double.tryParse(
                    order['delivery_lng']?.toString() ?? ''),
              ),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: RiderColors.blue),
            foregroundColor: RiderColors.blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.map_rounded, size: 18),
          label: const Text('ดูเส้นทาง',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      );

  Widget _buildCallButton() => SizedBox(
        width: double.infinity, height: 48,
        child: OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: RiderColors.blue),
            foregroundColor: RiderColors.blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.phone_rounded, size: 18),
          label: const Text('โทรหาลูกค้า',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      );
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  final bool active;
  const _StepDot(
      {required this.icon,
      required this.label,
      required this.done,
      required this.active});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: active ? 42 : 34,
            height: active ? 42 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? RiderColors.blue
                  : active
                      ? RiderColors.blue
                      : RiderColors.blueLight,
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: RiderColors.blue.withValues(alpha: 0.4),
                          blurRadius: 10)
                    ]
                  : null,
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              color: done || active ? Colors.white : RiderColors.muted,
              size: active ? 20 : 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: done
                      ? RiderColors.blue
                      : active
                          ? RiderColors.blue
                          : RiderColors.muted,
                  fontWeight: active || done
                      ? FontWeight.w700
                      : FontWeight.w400)),
        ],
      );
}

class _StepLine extends StatelessWidget {
  final bool filled;
  const _StepLine({required this.filled});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 3,
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: filled ? RiderColors.blue : RiderColors.blueLight,
          ),
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
                color: highlight ? Colors.white : Colors.white70)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: highlight ? 16 : 13,
                fontWeight:
                    highlight ? FontWeight.w800 : FontWeight.w500,
                color: Colors.white)),
      ]);
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool accent;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.accent = false});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16,
              color: accent ? RiderColors.blue : RiderColors.muted),
          const SizedBox(width: 8),
          SizedBox(
              width: 55,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: RiderColors.muted))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      color: RiderColors.text,
                      fontWeight: accent
                          ? FontWeight.w600
                          : FontWeight.w500))),
        ],
      );
}
