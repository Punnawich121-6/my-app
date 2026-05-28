import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../l10n/strings.dart';
import '../../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotif = true;
  bool _orderUpdates = true;
  bool _promoNotif = false;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(S.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ───────────────────────────────────────────────
          _Section(title: S.appearance, children: [
            _SwitchTile(
              icon: Icons.dark_mode_rounded,
              iconBg: const Color(0xFF2D2D44),
              iconColor: const Color(0xFFB39DDB),
              label: S.darkMode,
              desc: S.darkModeDesc,
              value: context.isDark,
              onChanged: (_) => settings.toggleTheme(),
            ),
            Divider(height: 1, indent: 60, color: context.divider),
            _SwitchTile(
              icon: Icons.language_rounded,
              iconBg: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1976D2),
              label: S.language,
              desc: S.languageDesc,
              value: settings.isEnglish,
              onChanged: (v) => settings.setEnglish(v),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Notifications ────────────────────────────────────────────
          _Section(title: S.notifSection, children: [
            _SwitchTile(
              icon: Icons.notifications_rounded,
              iconBg: context.orangeLight,
              iconColor: CColors.orange,
              label: S.pushNotif,
              desc: S.pushNotifDesc,
              value: _pushNotif,
              onChanged: (v) => setState(() => _pushNotif = v),
            ),
            Divider(height: 1, indent: 60, color: context.divider),
            _SwitchTile(
              icon: Icons.receipt_long_rounded,
              iconBg: context.orangeLight,
              iconColor: CColors.orange,
              label: S.orderUpdates,
              desc: S.orderUpdatesDesc,
              value: _orderUpdates,
              onChanged: (v) => setState(() => _orderUpdates = v),
            ),
            Divider(height: 1, indent: 60, color: context.divider),
            _SwitchTile(
              icon: Icons.local_offer_rounded,
              iconBg: context.orangeLight,
              iconColor: CColors.orange,
              label: S.promotions,
              desc: S.promotionsDesc,
              value: _promoNotif,
              onChanged: (v) => setState(() => _promoNotif = v),
            ),
          ]),
          const SizedBox(height: 16),

          // ── About ────────────────────────────────────────────────────
          _Section(title: S.about, children: [
            _InfoTile(icon: Icons.info_outline_rounded, label: S.version, value: '1.0.0'),
            Divider(height: 1, indent: 60, color: context.divider),
            _InfoTile(icon: Icons.description_rounded, label: S.privacyPolicy, value: ''),
            Divider(height: 1, indent: 60, color: context.divider),
            _InfoTile(icon: Icons.gavel_rounded, label: S.terms, value: ''),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 13, color: context.muted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(children: children),
      ),
    ]);
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, desc;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.iconBg, required this.iconColor,
      required this.label, required this.desc, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.fg)),
          Text(desc, style: TextStyle(fontSize: 11, color: context.muted)),
        ])),
        Switch(value: value, onChanged: onChanged, activeThumbColor: CColors.orange),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: context.muted, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.fg))),
        if (value.isNotEmpty)
          Text(value, style: TextStyle(fontSize: 13, color: context.muted))
        else
          Icon(Icons.chevron_right_rounded, color: context.muted, size: 20),
      ]),
    );
  }
}
