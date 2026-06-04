import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../config.dart';
import '../../main.dart';
import 'order_tracking_screen.dart';

class PaymentResultScreen extends StatefulWidget {
  final String orderId;
  final bool success;
  final String? reference;
  final int amount;
  final String paymentMethod;

  const PaymentResultScreen({
    super.key,
    required this.orderId,
    required this.success,
    this.reference,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    if (widget.success) {
      _player.play(UrlSource('$kBackendUrl/public/audio/sound-payment.mp3'));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final success = widget.success;
    final iconColor = success ? CColors.orange : const Color(0xFFF44336);
    final bgColor =
        success ? CColors.orangeLight : const Color(0xFFF44336).withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: CColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: iconColor,
                      size: 72,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      success ? 'ชำระเงินสำเร็จ' : 'ชำระเงินไม่สำเร็จ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      success
                          ? 'คำสั่งซื้อของคุณได้รับการยืนยันแล้ว'
                          : 'ไม่สามารถดำเนินการชำระเงินได้\nกรุณาลองใหม่อีกครั้ง',
                      style: const TextStyle(
                          fontSize: 14, color: CColors.muted, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Detail card
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _Row(label: 'Order ID', value: '#${widget.orderId}'),
                      const _Divider(),
                      _Row(label: 'จำนวนเงิน', value: '${widget.amount} THB'),
                      const _Divider(),
                      _Row(label: 'วิธีชำระเงิน', value: widget.paymentMethod),
                      if (widget.reference != null) ...[
                        const _Divider(),
                        _Row(
                          label: 'Reference',
                          value: widget.reference!,
                          small: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              if (success)
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              OrderTrackingScreen(orderId: widget.orderId)),
                      (route) => route.isFirst,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('TRACK ORDER',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('ลองใหม่',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),

              const SizedBox(height: 14),

              GestureDetector(
                onTap: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                      fontSize: 14,
                      color: CColors.orange,
                      fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool small;
  const _Row({required this.label, required this.value, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: CColors.muted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: small ? 11 : 13,
                fontWeight: FontWeight.w700,
                color: CColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Color(0xFFF0F0F0));
}
