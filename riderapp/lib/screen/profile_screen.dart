import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final int riderId;
  final String riderName;
  const ProfileScreen({super.key, required this.riderId, required this.riderName});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ออกจากระบบ?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('คุณต้องการออกจากระบบใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก', style: TextStyle(color: RiderColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: RiderColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Avatar
          Container(
            width: 90, height: 90,
            decoration: const BoxDecoration(color: RiderColors.blueLight, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: RiderColors.blue, size: 48),
          ),
          const SizedBox(height: 12),
          Text(riderName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: RiderColors.text)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: RiderColors.blueLight, borderRadius: BorderRadius.circular(20)),
            child: const Text('Rider Partner', style: TextStyle(color: RiderColors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(height: 24),

          // Info card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: RiderColors.blue.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                _ProfileTile(icon: Icons.badge_rounded, label: 'Rider ID', value: '#$riderId'),
                const Divider(height: 1, indent: 56),
                _ProfileTile(icon: Icons.star_rounded, label: 'สถานะ', value: 'ใช้งาน', valueColor: RiderColors.blue),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settings card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: RiderColors.blue.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.help_outline_rounded,
                  label: 'ความช่วยเหลือ',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _ActionTile(
                  icon: Icons.policy_outlined,
                  label: 'นโยบายและเงื่อนไข',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: RiderColors.red),
                foregroundColor: RiderColors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('ออกจากระบบ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Zest & Savory Rider v1.0.0', style: TextStyle(color: RiderColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _ProfileTile({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: RiderColors.blueLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: RiderColors.blue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: RiderColors.text))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? RiderColors.muted)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: RiderColors.blueLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: RiderColors.blue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: RiderColors.text))),
            const Icon(Icons.chevron_right_rounded, color: RiderColors.muted),
          ],
        ),
      ),
    );
  }
}
