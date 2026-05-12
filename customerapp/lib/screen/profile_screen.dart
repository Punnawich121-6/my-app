import 'package:flutter/material.dart';
import '../main.dart';
import 'auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'address_book_screen.dart';
import 'notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;
  const ProfileScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
  });
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก', style: TextStyle(color: CColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CColors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),

            // ── Avatar + Name ─────────────────────────────────────────
            Center(
              child: Column(children: [
                Stack(children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: CColors.orangeLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(
                        color: CColors.orange.withValues(alpha: 0.2),
                        blurRadius: 20, offset: const Offset(0, 6),
                      )],
                    ),
                    child: const Icon(Icons.person_rounded, color: CColors.orange, size: 52),
                  ),
                  Positioned(
                    right: 2, bottom: 2,
                    child: GestureDetector(
                      onTap: () async {
                        final newName = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(builder: (_) => EditProfileScreen(
                            customerId: widget.customerId,
                            customerName: _name,
                            customerPhone: widget.customerPhone,
                          )),
                        );
                        if (newName != null) setState(() => _name = newName);
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: CColors.orange, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(_name,
                    style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: CColors.text)),
                const SizedBox(height: 4),
                const Text('I love fast food 🍔',
                    style: TextStyle(fontSize: 13, color: CColors.muted)),
              ]),
            ),
            const SizedBox(height: 32),

            // ── Section 1: Personal ───────────────────────────────────
            _SectionCard(children: [
              _MenuItem(
                icon: Icons.person_outline_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: 'Personal Info',
                onTap: () async {
                  final newName = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(
                      customerId: widget.customerId,
                      customerName: _name,
                      customerPhone: widget.customerPhone,
                    )),
                  );
                  if (newName != null) setState(() => _name = newName);
                },
              ),
              _Divider(),
              _MenuItem(
                icon: Icons.map_outlined,
                iconBg: const Color(0xFFE8F0FF),
                iconColor: const Color(0xFF4A6CF7),
                label: 'Addresses',
                onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AddressBookScreen())),
              ),
            ]),
            const SizedBox(height: 12),

            // ── Section 2: Activity ───────────────────────────────────
            _SectionCard(children: [
              _MenuItem(
                icon: Icons.shopping_bag_outlined,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF43A047),
                label: 'Cart',
                onTap: () {},
              ),
              _Divider(),
              _MenuItem(
                icon: Icons.favorite_border_rounded,
                iconBg: const Color(0xFFFFE4E4),
                iconColor: const Color(0xFFE53935),
                label: 'Favourite',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FavoritesScreen(
                    customerId: widget.customerId,
                    customerName: _name,
                    customerPhone: widget.customerPhone,
                  )),
                ),
              ),
              _Divider(),
              _MenuItem(
                icon: Icons.notifications_outlined,
                iconBg: const Color(0xFFFFF8E1),
                iconColor: const Color(0xFFFFB300),
                label: 'Notifications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotificationScreen(customerId: widget.customerId))),
              ),
              _Divider(),
              _MenuItem(
                icon: Icons.credit_card_outlined,
                iconBg: const Color(0xFFE8F0FF),
                iconColor: const Color(0xFF4A6CF7),
                label: 'Payment Method',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 12),

            // ── Section 3: Support ────────────────────────────────────
            _SectionCard(children: [
              _MenuItem(
                icon: Icons.help_outline_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: 'FAQs',
                onTap: () {},
              ),
              _Divider(),
              _MenuItem(
                icon: Icons.star_border_rounded,
                iconBg: const Color(0xFFFFF8E1),
                iconColor: const Color(0xFFFFB300),
                label: 'User Reviews',
                onTap: () {},
              ),
              _Divider(),
              _MenuItem(
                icon: Icons.settings_outlined,
                iconBg: const Color(0xFFF5F5F5),
                iconColor: CColors.muted,
                label: 'Settings',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),

            // ── Logout ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CColors.red),
                    foregroundColor: CColors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('ออกจากระบบ',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('Zest & Savory v1.0.0',
                  style: TextStyle(color: CColors.muted, fontSize: 12)),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16, offset: const Offset(0, 4),
      )],
    ),
    child: Column(children: children),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: CColors.text)),
        ),
        const Icon(Icons.chevron_right_rounded, color: CColors.muted, size: 20),
      ]),
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 68, color: Color(0xFFF0F0F0));
}
