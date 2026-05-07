import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';

class CallScreen extends StatefulWidget {
  final String riderName;
  const CallScreen({super.key, this.riderName = 'Robert Fox'});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _muted = false;
  bool _speaker = false;
  String _status = 'Connecting.......';
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Simulate connecting then connected after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _status = 'Connected');
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _callDuration {
    if (_status != 'Connected') return _status;
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background: dark gradient simulating blurred photo ──────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Decorative blurred circles for depth
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                color: CColors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 200, left: -80,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Top: rider info centered on screen ──────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0, right: 0,
            child: Column(
              children: [
                // Pulsing avatar ring
                _PulsingAvatar(),
                const SizedBox(height: 20),
                Text(
                  widget.riderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _callDuration,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom white card with buttons ──────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  32, 32, 32, MediaQuery.of(context).padding.bottom + 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Small rider info in card
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: const BoxDecoration(
                          color: CColors.orangeLight, shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded,
                            color: CColors.orange, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.riderName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: CColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _callDuration,
                            style: const TextStyle(
                                fontSize: 13, color: CColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Call control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mute
                      _CallBtn(
                        icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _muted ? 'Unmute' : 'Mute',
                        color: _muted ? CColors.orange : const Color(0xFFF0F0F0),
                        iconColor: _muted ? Colors.white : CColors.text,
                        size: 58,
                        onTap: () => setState(() => _muted = !_muted),
                      ),
                      const SizedBox(width: 24),
                      // End call (large red)
                      _CallBtn(
                        icon: Icons.call_end_rounded,
                        label: 'End',
                        color: CColors.red,
                        iconColor: Colors.white,
                        size: 72,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 24),
                      // Speaker
                      _CallBtn(
                        icon: _speaker
                            ? Icons.volume_up_rounded
                            : Icons.volume_down_rounded,
                        label: 'Speaker',
                        color: _speaker
                            ? CColors.orange
                            : const Color(0xFFF0F0F0),
                        iconColor: _speaker ? Colors.white : CColors.text,
                        size: 58,
                        onTap: () => setState(() => _speaker = !_speaker),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final double size;
  final VoidCallback onTap;

  const _CallBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size, height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12, offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: iconColor, size: size * 0.4),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, color: CColors.muted)),
        ],
      ),
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 52),
      ),
    );
  }
}
