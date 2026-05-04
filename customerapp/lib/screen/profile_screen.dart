import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'address_book_screen.dart';
import 'notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerPhone;
  const ProfileScreen({super.key, required this.customerId, required this.customerName, required this.customerPhone});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _name;

  @override
  void initState() { super.initState(); _name = widget.customerName; }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ออกจากระบบ?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('คุณต้องการออกจากระบบใช่ไหม?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก', style: TextStyle(color: CColors.muted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: CColors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const SizedBox(height: 8),

            // Avatar + edit button
            Stack(
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: CColors.orange, size: 48),
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: GestureDetector(
                    onTap: () async {
                      final newName = await Navigator.push<String>(context, MaterialPageRoute(
                        builder: (_) => EditProfileScreen(customerId: widget.customerId, customerName: _name, customerPhone: widget.customerPhone),
                      ));
                      if (newName != null) setState(() => _name = newName);
                    },
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: CColors.text)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(20)),
              child: const Text('ลูกค้า', style: TextStyle(color: CColors.orange, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(height: 24),

            // Info card
            _Card(children: [
              _InfoTile(icon: Icons.badge_rounded, label: 'รหัสสมาชิก', value: '#${widget.customerId}'),
              const Divider(height: 1, indent: 56),
              _InfoTile(icon: Icons.phone_rounded, label: 'เบอร์โทร', value: widget.customerPhone),
            ]),
            const SizedBox(height: 14),

            // Feature card
            _Card(children: [
              _ActionTile(
                icon: Icons.notifications_outlined,
                label: 'การแจ้งเตือน',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen(customerId: widget.customerId))),
              ),
              const Divider(height: 1, indent: 56),
              _ActionTile(
                icon: Icons.favorite_border_rounded,
                label: 'ร้านที่ชอบ',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FavoritesScreen(customerId: widget.customerId, customerName: _name, customerPhone: widget.customerPhone),
                )),
              ),
              const Divider(height: 1, indent: 56),
              _ActionTile(
                icon: Icons.location_on_outlined,
                label: 'สมุดที่อยู่',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookScreen())),
              ),
            ]),
            const SizedBox(height: 14),

            // Settings card
            _Card(children: [
              _ActionTile(icon: Icons.help_outline_rounded, label: 'ความช่วยเหลือ', onTap: () {}),
              const Divider(height: 1, indent: 56),
              _ActionTile(icon: Icons.policy_outlined, label: 'นโยบายและเงื่อนไข', onTap: () {}),
            ]),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: CColors.red), foregroundColor: CColors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('ออกจากระบบ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Zest & Savory v1.0.0', style: TextStyle(color: CColors.muted, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: CColors.orange.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Column(children: children),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: CColors.orange, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: CColors.text))),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CColors.muted)),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: CColors.orange, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: CColors.text))),
        const Icon(Icons.chevron_right_rounded, color: CColors.muted),
      ]),
    ),
  );
}
