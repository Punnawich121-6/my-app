import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../main.dart';
import 'order_tracking_screen.dart';

class SuccessScreen extends StatefulWidget {
  final String? orderId;
  const SuccessScreen({super.key, this.orderId});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _player.play(AssetSource('audio/sound-payment.mp3'));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                          color: CColors.orangeLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: CColors.orange.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            )
                          ],
                        ),
                      ),
                      Container(
                        width: 130, height: 130,
                        decoration: const BoxDecoration(
                          color: CColors.orange, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 64),
                      ),
                      Positioned(top: 10, right: 20, child: _ConfettiDot(color: CColors.orange, size: 12)),
                      Positioned(top: 20, left: 15, child: _ConfettiDot(color: const Color(0xFFFFB300), size: 8)),
                      Positioned(bottom: 15, right: 15, child: _ConfettiDot(color: CColors.green, size: 10)),
                      Positioned(bottom: 20, left: 20, child: _ConfettiDot(color: const Color(0xFFAB47BC), size: 8)),
                      Positioned(top: 50, right: 5, child: _ConfettiStar()),
                      Positioned(bottom: 50, left: 5, child: _ConfettiStar()),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 1),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text(
                      'Congratulations!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: CColors.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'You successfully made a payment,\nenjoy our service!',
                      style: TextStyle(
                        fontSize: 15,
                        color: CColors.muted,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.orderId != null) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderTrackingScreen(orderId: widget.orderId!),
                        ),
                        (route) => route.isFirst,
                      );
                    } else {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
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
              ),

              const SizedBox(height: 16),

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

class _ConfettiDot extends StatelessWidget {
  final Color color;
  final double size;
  const _ConfettiDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _ConfettiStar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Icon(
        Icons.star_rounded,
        color: CColors.orange,
        size: 16,
      );
}
