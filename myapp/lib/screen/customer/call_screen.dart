import 'package:flutter/material.dart';
import '../../main.dart';

class CallScreen extends StatefulWidget {
  final String name;
  final String? avatarUrl;
  final String? backgroundUrl;

  const CallScreen({
    super.key,
    this.name = 'Robert Fox',
    this.avatarUrl,
    this.backgroundUrl,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  bool _muted = false;
  bool _speakerOn = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgUrl = widget.backgroundUrl ??
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&h=900&fit=crop&crop=face';
    final avatarUrl = widget.avatarUrl ??
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(bgUrl, fit: BoxFit.cover, width: double.infinity),
          ),
          Positioned.fill(
            child: Container(color: const Color(0xFF3A5068).withValues(alpha: 0.62)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(40, 60, 40, 48),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
                      ),
                      const SizedBox(height: 6),
                      const Text('Connecting.......', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                      const SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ControlButton(
                            icon: _muted ? Icons.mic_off_rounded : Icons.mic_off_outlined,
                            active: _muted,
                            onTap: () => setState(() => _muted = !_muted),
                          ),
                          _HangUpButton(pulseAnim: _pulseAnim, onTap: () => Navigator.pop(context)),
                          _ControlButton(
                            icon: _speakerOn ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                            active: _speakerOn,
                            onTap: () => setState(() => _speakerOn = !_speakerOn),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -44,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: active ? AppColors.orangeLight : const Color(0xFFF3F3F3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: active ? AppColors.orange : const Color(0xFF616161), size: 24),
        ),
      );
}

class _HangUpButton extends StatelessWidget {
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _HangUpButton({required this.pulseAnim, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: pulseAnim,
          builder: (_, child) => Container(
            width: 72 * pulseAnim.value,
            height: 72 * pulseAnim.value,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2 / pulseAnim.value),
              shape: BoxShape.circle,
            ),
            child: child,
          ),
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call, color: Colors.white, size: 30),
          ),
        ),
      );
}
