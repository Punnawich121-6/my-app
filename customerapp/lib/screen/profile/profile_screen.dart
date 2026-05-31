import 'dart:convert';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../l10n/strings.dart';
import '../../services/customer_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'address_book_screen.dart';
import '../home/notification_screen.dart';
import 'wallet_screen.dart';
import 'payment_method_screen.dart';
import 'faq_screen.dart';
import 'settings_screen.dart';
import 'user_reviews_screen.dart';
import '../cart/cart_screen.dart';
import '../chat/admin_chat_screen.dart';

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
  String? _profileImage;

  @override
  void initState() {
    super.initState();
    _name = widget.customerName;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await CustomerService.getProfile(widget.customerId);
    if (!mounted || data == null) return;
    setState(() {
      _name = (data['name'] as String?) ?? _name;
      _profileImage = data['profile_image'] as String?;
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(S.logoutQ, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(S.logoutMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.cancel, style: TextStyle(color: context.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CColors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(S.logout),
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
      backgroundColor: context.bg,
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
                      color: context.orangeLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.card, width: 4),
                      boxShadow: [BoxShadow(
                        color: CColors.orange.withValues(alpha: 0.2),
                        blurRadius: 20, offset: const Offset(0, 6),
                      )],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _profileImage != null && _profileImage!.startsWith('data:')
                        ? Image.memory(base64Decode(_profileImage!.split(',').last), fit: BoxFit.cover)
                        : const Icon(Icons.person_rounded, color: CColors.orange, size: 52),
                  ),
                  Positioned(
                    right: 2, bottom: 2,
                    child: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(builder: (_) => EditProfileScreen(
                            customerId: widget.customerId,
                            customerName: _name,
                            customerPhone: widget.customerPhone,
                            profileImage: _profileImage,
                          )),
                        );
                        if (result != null) {
                          setState(() {
                            _name = result['name'] as String;
                            _profileImage = result['profileImage'] as String?;
                          });
                        }
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: CColors.orange, shape: BoxShape.circle,
                          border: Border.all(color: context.card, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(_name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.fg)),
                const SizedBox(height: 4),
                Text('I love fast food 🍔', style: TextStyle(fontSize: 13, color: context.muted)),
              ]),
            ),
            const SizedBox(height: 32),

            // ── Section 1: Personal ───────────────────────────────────
            _SectionCard(children: [
              _MenuItem(
                icon: Icons.person_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: S.personalInfo,
                onTap: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(
                      customerId: widget.customerId,
                      customerName: _name,
                      customerPhone: widget.customerPhone,
                      profileImage: _profileImage,
                    )),
                  );
                  if (result != null) {
                    setState(() {
                      _name = result['name'] as String;
                      _profileImage = result['profileImage'] as String?;
                    });
                  }
                },
              ),
              const _Divider(),
              _MenuItem(
                icon: Icons.map_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: S.addresses,
                onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AddressBookScreen())),
              ),
            ]),
            const SizedBox(height: 12),

            // ── Section 2: Activity ───────────────────────────────────
            _SectionCard(children: [
              _MenuItem(
                icon: Icons.shopping_bag_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: S.cart,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CartScreen(
                    customerId: widget.customerId,
                    customerName: _name,
                    customerPhone: widget.customerPhone,
                  )),
                ),
              ),
              const _Divider(),
              _MenuItem(
                icon: Icons.favorite_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: S.favourite,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FavoritesScreen(
                    customerId: widget.customerId,
                    customerName: _name,
                    customerPhone: widget.customerPhone,
                  )),
                ),
              ),
              const _Divider(),
              _MenuItem(
                icon: Icons.notifications_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: S.notifications,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotificationScreen(customerId: widget.customerId))),
              ),
              const _Divider(),
              _MenuItem(
                icon: Icons.account_balance_wallet_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: S.wallet,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WalletScreen(customerId: widget.customerId)),
                ),
              ),
              const _Divider(),
              _MenuItem(
                icon: Icons.credit_card_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: S.paymentMethod,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // ── Section 3: Support ────────────────────────────────────
            _SectionCard(children: [
              _MenuItem(
                icon: Icons.support_agent_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: S.contactAdmin,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminChatScreen(
                    customerId: widget.customerId,
                    customerName: _name,
                  )),
                ),
              ),
              const _Divider(),
              _MenuItem(
                icon: Icons.help_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: S.faqs,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FaqScreen()),
                ),
              ),
              const _Divider(),
              _MenuItem(
                icon: Icons.rate_review_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: S.myReviews,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserReviewsScreen(customerId: widget.customerId)),
                ),
              ),
              const _Divider(),
              _MenuItem(
                icon: Icons.settings_rounded,
                iconBg: const Color(0xFFFFEDE5),
                iconColor: CColors.orange,
                label: S.settings,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
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
                  label: Text(S.logout, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(S.appVersion, style: TextStyle(color: context.muted, fontSize: 12))),
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
      color: context.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha: 0.10),
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
        Expanded(child: Text(label, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: context.fg))),
        Icon(Icons.chevron_right_rounded, color: context.muted, size: 20),
      ]),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 68, color: context.divider);
}
