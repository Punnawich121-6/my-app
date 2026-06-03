import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';

class OrderStatusPopup extends StatefulWidget {
  final String orderId;
  final String status;
  final String storeName;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const OrderStatusPopup({
    super.key,
    required this.orderId,
    required this.status,
    required this.storeName,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<OrderStatusPopup> createState() => _OrderStatusPopupState();
}

class _OrderStatusPopupState extends State<OrderStatusPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;
  double _progress = 1.0;

  static const _autoDismiss = Duration(seconds: 5);
  static const _tickMs = 40;

  static const _statusMsg = {
    'accepted':   'ร้านรับออเดอร์แล้ว!',
    'preparing':  'กำลังทำอาหาร รอสักครู่...',
    'ready':      'อาหารพร้อมส่งแล้ว!',
    'delivering': 'ไรเดอร์กำลังนำอาหารมาส่ง!',
    'picking_up': 'ไรเดอร์กำลังนำอาหารมาส่ง!',
    'completed':  'ส่งอาหารเรียบร้อยแล้ว 😊',
    'cancelled':  'ออเดอร์ถูกยกเลิก',
    'pending':    'กำลังรอร้านยืนยัน...',
  };

  static const _statusIcon = {
    'accepted':   Icons.check_circle_rounded,
    'preparing':  Icons.restaurant_rounded,
    'ready':      Icons.inventory_2_rounded,
    'delivering': Icons.delivery_dining_rounded,
    'picking_up': Icons.delivery_dining_rounded,
    'completed':  Icons.lunch_dining,
    'cancelled':  Icons.cancel_rounded,
    'pending':    Icons.access_time_rounded,
  };

  bool get _isCancelled => widget.status == 'cancelled';
  bool get _isCompleted => widget.status == 'completed';

  Color get _accentColor {
    if (_isCancelled) return CColors.red;
    if (_isCompleted) return const Color(0xFF16A34A);
    return CColors.orange;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6));
    _ctrl.forward();
    _startAutoClose();
  }

  void _startAutoClose() {
    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _progress -= _tickMs / _autoDismiss.inMilliseconds);
      if (_progress <= 0) {
        t.cancel();
        _animateOut();
      }
    });
  }

  Future<void> _animateOut() async {
    _timer?.cancel();
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg  = _statusMsg[widget.status]  ?? widget.status;
    final icon = _statusIcon[widget.status] ?? Icons.receipt_long_rounded;
    final color = _accentColor;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: () {
            _timer?.cancel();
            _ctrl.reverse().then((_) => widget.onDismiss());
            widget.onTap();
          },
          onVerticalDragUpdate: (d) {
            if (d.primaryDelta != null && d.primaryDelta! < -5) _animateOut();
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Row(
                      children: [
                        // Icon badge
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        // Texts
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.storeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: CColors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                msg,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // CTA button
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ดูออเดอร์',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress bar
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: LinearProgressIndicator(
                      value: _progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation(
                          color.withValues(alpha: 0.55)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
