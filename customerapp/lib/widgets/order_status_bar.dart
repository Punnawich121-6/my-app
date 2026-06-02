import 'package:flutter/material.dart';
import '../main.dart';

class OrderStatusBar extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const OrderStatusBar({super.key, required this.order, required this.onTap});

  static const _steps = [
    'pending', 'accepted', 'preparing', 'ready', 'delivering', 'completed',
  ];

  static const _statusMsg = {
    'pending':    'รอร้านอาหารยืนยัน...',
    'accepted':   'ร้านรับออเดอร์แล้ว',
    'preparing':  'กำลังทำอาหาร...',
    'ready':      'อาหารพร้อมส่ง',
    'delivering': 'ไรเดอร์กำลังนำมาส่ง',
    'completed':  'ส่งเรียบร้อยแล้ว!',
    'cancelled':  'ออเดอร์ถูกยกเลิก',
  };

  static const _statusIcon = {
    'pending':    Icons.access_time_rounded,
    'accepted':   Icons.check_circle_rounded,
    'preparing':  Icons.restaurant_rounded,
    'ready':      Icons.inventory_2_rounded,
    'delivering': Icons.delivery_dining_rounded,
    'completed':  Icons.sentiment_satisfied_alt_rounded,
    'cancelled':  Icons.cancel_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final status      = order['status']?.toString() ?? '';
    final storeName   = order['store_name']?.toString() ?? 'ร้านอาหาร';
    final isCancelled = status == 'cancelled';
    final isCompleted = status == 'completed';
    final color = isCancelled
        ? CColors.red
        : isCompleted
            ? const Color(0xFF16A34A)
            : CColors.orange;

    final stepIndex = _steps.indexOf(status);
    final msg  = _statusMsg[status] ?? status;
    final icon = _statusIcon[status] ?? Icons.receipt_long_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: context.card,
            border: Border(top: BorderSide(color: color, width: 2.5)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      storeName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.fg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      msg,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isCancelled && stepIndex >= 0)
                _OrderStepDots(
                  stepCount: _steps.length,
                  currentIndex: stepIndex,
                  color: color,
                ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, color: context.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStepDots extends StatelessWidget {
  final int stepCount;
  final int currentIndex;
  final Color color;

  const _OrderStepDots({
    required this.stepCount,
    required this.currentIndex,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(stepCount, (i) {
        final isDone    = i < currentIndex;
        final isCurrent = i == currentIndex;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 10 : 5,
              height: isCurrent ? 10 : 5,
              decoration: BoxDecoration(
                color: (isDone || isCurrent)
                    ? color
                    : Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                boxShadow: isCurrent
                    ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5)]
                    : null,
              ),
            ),
            if (i < stepCount - 1)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 8,
                height: 2,
                decoration: BoxDecoration(
                  color: isDone
                      ? color
                      : Colors.grey.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        );
      }),
    );
  }
}
