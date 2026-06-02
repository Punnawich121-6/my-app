import 'package:flutter/material.dart';
import '../main.dart';

class OrderStatusBar extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const OrderStatusBar({super.key, required this.order, required this.onTap});

  static const steps = [
    {'key': 'pending',    'label': 'สั่งแล้ว'},
    {'key': 'accepted',   'label': 'ร้านรับ'},
    {'key': 'preparing',  'label': 'กำลังทำ'},
    {'key': 'ready',      'label': 'พร้อมส่ง'},
    {'key': 'picking_up', 'label': 'กำลังส่ง'},
    {'key': 'completed',  'label': 'ส่งแล้ว'},
  ];

  static const _statusMsg = {
    'pending':    'รอร้านอาหารยืนยัน...',
    'accepted':   'ร้านรับออเดอร์แล้ว',
    'preparing':  'กำลังทำอาหาร...',
    'ready':      'อาหารพร้อมส่ง',
    'delivering': 'ไรเดอร์กำลังนำมาส่ง',
    'picking_up': 'ไรเดอร์กำลังนำมาส่ง',
    'completed':  'ส่งเรียบร้อยแล้ว!',
    'cancelled':  'ออเดอร์ถูกยกเลิก',
  };

  static const _statusIcon = {
    'pending':    Icons.access_time_rounded,
    'accepted':   Icons.check_circle_rounded,
    'preparing':  Icons.restaurant_rounded,
    'ready':      Icons.inventory_2_rounded,
    'delivering': Icons.delivery_dining_rounded,
    'picking_up': Icons.delivery_dining_rounded,
    'completed':  Icons.sentiment_satisfied_alt_rounded,
    'cancelled':  Icons.cancel_rounded,
  };

  @override
  State<OrderStatusBar> createState() => _OrderStatusBarState();
}

class _OrderStatusBarState extends State<OrderStatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  bool get _isActive {
    final s = widget.order['status']?.toString() ?? '';
    return s != 'completed' && s != 'cancelled' && s != 'picking_up';
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (_isActive) _pulseCtrl.repeat();
  }

  @override
  void didUpdateWidget(OrderStatusBar old) {
    super.didUpdateWidget(old);
    if (_isActive && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat();
    } else if (!_isActive && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status      = widget.order['status']?.toString() ?? '';
    final storeName   = widget.order['store_name']?.toString() ?? 'ร้านอาหาร';
    final isCancelled = status == 'cancelled';
    final isCompleted = status == 'completed';

    final color = isCancelled
        ? CColors.red
        : isCompleted
            ? const Color(0xFF16A34A)
            : CColors.orange;

    final normalizedStatus = status == 'delivering' ? 'picking_up' : status;
    final stepKeys    = OrderStatusBar.steps.map((s) => s['key']!).toList();
    final stepIndex   = stepKeys.indexOf(normalizedStatus);
    final progressVal = stepIndex < 0 ? 0.0 : (stepIndex + 1) / stepKeys.length;
    final msg         = OrderStatusBar._statusMsg[status] ?? status;
    final icon        = OrderStatusBar._statusIcon[status] ?? Icons.receipt_long_rounded;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.card,
          border: Border(top: BorderSide(color: color, width: 3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  _PulseIcon(
                    icon: icon,
                    color: color,
                    controller: _pulseCtrl,
                    isActive: _isActive,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          storeName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: context.fg,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          msg,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!isCancelled && stepIndex >= 0)
                    _StepDots(
                      steps: OrderStatusBar.steps,
                      currentIndex: stepIndex,
                      color: color,
                    ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: color, size: 22),
                ],
              ),
            ),
            if (!isCancelled)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progressVal),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 3,
                  backgroundColor: Colors.grey.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Pulsing icon ──────────────────────────────────────────────────────────────

class _PulseIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final AnimationController controller;
  final bool isActive;

  const _PulseIcon({
    required this.icon,
    required this.color,
    required this.controller,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isActive)
            AnimatedBuilder(
              animation: controller,
              builder: (_, _) {
                final t = controller.value;
                return Transform.scale(
                  scale: 1.0 + t * 0.70,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: (1.0 - t) * 0.28),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
        ],
      ),
    );
  }
}

// ── Step dots ─────────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final List<Map<String, String>> steps;
  final int currentIndex;
  final Color color;

  const _StepDots({
    required this.steps,
    required this.currentIndex,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(steps.length, (i) {
        final isDone    = i < currentIndex;
        final isCurrent = i == currentIndex;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              width: isCurrent ? 11 : 6,
              height: isCurrent ? 11 : 6,
              decoration: BoxDecoration(
                color: (isDone || isCurrent)
                    ? color
                    : Colors.grey.withValues(alpha: 0.28),
                shape: BoxShape.circle,
                border: (!isDone && !isCurrent)
                    ? Border.all(color: Colors.grey.withValues(alpha: 0.4), width: 1)
                    : null,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.55),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            if (i < steps.length - 1)
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 7,
                height: 2,
                decoration: BoxDecoration(
                  color: isDone ? color : Colors.grey.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        );
      }),
    );
  }
}
