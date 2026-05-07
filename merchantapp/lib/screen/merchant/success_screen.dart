import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../main.dart';

class SuccessScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onOk;

  const SuccessScreen({
    super.key,
    this.title = 'Withdraw Successful',
    this.subtitle,
    this.onOk,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Sparkles
                        ..._buildSparkles(),
                        // Main circle
                        ScaleTransition(
                          scale: _scale,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: widget.onOk ?? () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSparkles() {
    const sparkleData = [
      {'dx': -80.0, 'dy': -60.0, 'size': 20.0, 'color': 0xFFFFA623},
      {'dx': 72.0, 'dy': -70.0, 'size': 14.0, 'color': 0xFFFFA623},
      {'dx': -100.0, 'dy': 20.0, 'size': 10.0, 'color': 0xFFFFCB8E},
      {'dx': 90.0, 'dy': 30.0, 'size': 18.0, 'color': 0xFFFFCB8E},
      {'dx': -50.0, 'dy': 80.0, 'size': 12.0, 'color': 0xFFFFA623},
      {'dx': 60.0, 'dy': 75.0, 'size': 8.0, 'color': 0xFFFFCB8E},
      {'dx': 0.0, 'dy': -95.0, 'size': 10.0, 'color': 0xFFFFCB8E},
      {'dx': -30.0, 'dy': -85.0, 'size': 7.0, 'color': 0xFFFFA623},
    ];

    return sparkleData.map((s) {
      return Positioned(
        left: 100 + (s['dx'] as double),
        top: 100 + (s['dy'] as double),
        child: ScaleTransition(
          scale: _scale,
          child: _Sparkle(size: s['size'] as double, color: Color(s['color'] as int)),
        ),
      );
    }).toList();
  }
}

class _Sparkle extends StatelessWidget {
  final double size;
  final Color color;
  const _Sparkle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SparklePainter(color: color)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final ri = r * 0.4;

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final outerAngle = (i * 2 * math.pi / 4) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 4;
      if (i == 0) {
        path.moveTo(cx + r * math.cos(outerAngle), cy + r * math.sin(outerAngle));
      } else {
        path.lineTo(cx + r * math.cos(outerAngle), cy + r * math.sin(outerAngle));
      }
      path.lineTo(cx + ri * math.cos(innerAngle), cy + ri * math.sin(innerAngle));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}
