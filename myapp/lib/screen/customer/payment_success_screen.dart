import 'package:flutter/material.dart';
import '../../main.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _BackgroundPattern()),
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _WalletIllustration(),
                        const SizedBox(height: 40),
                        const Text(
                          'Congratulations!',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'You successfully maked a payment,\nenjoy our service!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        'TRACK ORDER',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundPattern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PatternPainter());
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    const spacing = 60.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _WalletIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ..._stars(),
          ..._confetti(),
          // Wallet body
          Positioned(
            bottom: 40,
            child: Container(
              width: 130, height: 95,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5A623), Color(0xFFE07B00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: AppColors.orange.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -22, right: -22,
                    child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle)),
                  ),
                  Positioned(
                    bottom: 8, left: 12,
                    child: Container(width: 80, height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(3))),
                  ),
                  Positioned(
                    bottom: 20, left: 12,
                    child: Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3))),
                  ),
                ],
              ),
            ),
          ),
          // Tilted card sticking out
          Positioned(
            top: 54, right: 36,
            child: Transform.rotate(
              angle: 0.35,
              child: Container(
                width: 56, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Large gold coin
          Positioned(
            top: 36, left: 60,
            child: _Coin(size: 52, color: const Color(0xFFFFD700)),
          ),
          // Small coin
          Positioned(
            top: 52, right: 44,
            child: _Coin(size: 36, color: const Color(0xFFFFC107)),
          ),
        ],
      ),
    );
  }

  List<Widget> _stars() {
    const items = [
      [28.0, 24.0, 18.0, Color(0xFFB39DDB)],
      [185.0, 35.0, 14.0, Color(0xFF64B5F6)],
      [16.0, 110.0, 12.0, Color(0xFFFF8A65)],
      [200.0, 95.0, 16.0, Color(0xFFB39DDB)],
      [55.0, 192.0, 10.0, Color(0xFF64B5F6)],
      [170.0, 185.0, 12.0, Color(0xFFFFE082)],
      [110.0, 205.0, 8.0, Color(0xFFFF8A65)],
      [220.0, 155.0, 10.0, Color(0xFFFFE082)],
    ];
    return [
      for (final s in items)
        Positioned(
          left: s[0] as double,
          top: s[1] as double,
          child: Icon(Icons.star_rounded, size: s[2] as double, color: s[3] as Color),
        ),
    ];
  }

  List<Widget> _confetti() {
    const dots = [
      [44.0, 64.0, Color(0xFFFF6B35)],
      [186.0, 72.0, Color(0xFF64B5F6)],
      [28.0, 158.0, Color(0xFFFFE082)],
      [202.0, 148.0, Color(0xFFB39DDB)],
      [130.0, 14.0, Color(0xFFFF8A65)],
      [78.0, 8.0, Color(0xFF80DEEA)],
    ];
    return [
      for (final d in dots)
        Positioned(
          left: d[0] as double,
          top: d[1] as double,
          child: Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: d[2] as Color, shape: BoxShape.circle),
          ),
        ),
    ];
  }
}

class _Coin extends StatelessWidget {
  final double size;
  final Color color;
  const _Coin({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)],
        ),
        child: Center(
          child: Text(
            '\$',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.44),
          ),
        ),
      );
}
