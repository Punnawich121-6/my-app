import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../merchant/home/merchant_main_screen.dart';
import 'login_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  final String phone;
  const PendingApprovalScreen({super.key, required this.phone});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  late AnimationController _anim;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
    _checkApproval();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkApproval());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _checkApproval() async {
    final store = await ApiService.getStoreByPhone(widget.phone);
    if (!mounted || store == null) return;
    final status = (store['status'] as String? ?? '').toLowerCase();
    if (status == 'active') {
      ApiService.storeId = store['id'].toString();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MerchantMainScreen()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: AppColors.orangeLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded,
                      color: AppColors.orange, size: 54),
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'รอการอนุมัติ',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'แอดมินกำลังตรวจสอบข้อมูลร้านของคุณ\nโดยปกติใช้เวลา 1–3 วันทำการ',
                style: TextStyle(
                    fontSize: 14, color: AppColors.muted, height: 1.65),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.orangeMid),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.orange, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'แอปจะเข้าสู่ระบบโดยอัตโนมัติทันทีที่ได้รับการอนุมัติ ไม่ต้องทำอะไรเพิ่มเติม',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.text, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.orangeMid),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                ),
                child: const Text('ออกจากระบบ',
                    style: TextStyle(color: AppColors.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
