import 'package:flutter/material.dart';
import '../main.dart';
import 'success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int totalAmount;
  final Future<String?> Function()? onConfirm;
  final VoidCallback? onSuccess;
  const PaymentScreen({super.key, required this.totalAmount, this.onConfirm, this.onSuccess});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selected = 'Cash';
  bool _processing = false;

  static const _methods = [
    {'id': 'Cash',       'label': 'Cash',       'icon': Icons.payments_rounded},
    {'id': 'Visa',       'label': 'Visa',        'icon': Icons.credit_card_rounded},
    {'id': 'Mastercard', 'label': 'Mastercard',  'icon': Icons.credit_card_rounded},
    {'id': 'PayPal',     'label': 'PayPal',      'icon': Icons.account_balance_wallet_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: CColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_left_rounded,
                    color: CColors.text, size: 22),
              ),
            ),
            const Expanded(
              child: Text('Payment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: CColors.text)),
            ),
            const SizedBox(width: 38),
          ]),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Payment method horizontal scroll ─────────────────
                  const Text('Payment Method',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: CColors.text)),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _methods.length,
                      itemBuilder: (_, i) {
                        final m = _methods[i];
                        final id = m['id'] as String;
                        final selected = id == _selected;
                        return GestureDetector(
                          onTap: () => setState(() => _selected = id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            width: 90,
                            decoration: BoxDecoration(
                              color: selected
                                  ? CColors.orangeLight
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? CColors.orange
                                    : const Color(0xFFE8E8E8),
                                width: selected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(m['icon'] as IconData,
                                          color: selected
                                              ? CColors.orange
                                              : CColors.muted,
                                          size: 28),
                                      const SizedBox(height: 6),
                                      Text(
                                        m['label'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? CColors.orange
                                              : CColors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  Positioned(
                                    top: 6, right: 6,
                                    child: Container(
                                      width: 18, height: 18,
                                      decoration: const BoxDecoration(
                                          color: CColors.orange,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Card display area ─────────────────────────────────
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: _selected == 'Cash'
                          ? const LinearGradient(
                              colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : _selected == 'Visa'
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF1A237E),
                                    Color(0xFF283593)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : _selected == 'Mastercard'
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFEB001B),
                                        Color(0xFFF79E1B)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF003087),
                                        Color(0xFF009CDE)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: CColors.orange.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          right: -30, top: -30,
                          child: Container(
                            width: 150, height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20, bottom: -20,
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(
                                  _methods.firstWhere((m) =>
                                          m['id'] == _selected)['icon']
                                      as IconData,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const Spacer(),
                                Text(
                                  _selected,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ]),
                              const Spacer(),
                              if (_selected == 'Cash')
                                const Text('Pay with Cash on Delivery',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13))
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '**** **** **** ****',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                            alpha: 0.7),
                                        fontSize: 16,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No $_selected added',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Add new button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CColors.orange,
                        side: const BorderSide(color: CColors.orange, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('ADD NEW',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom: total + pay button ─────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CColors.muted)),
                    const Spacer(),
                    Text(
                      '\$${widget.totalAmount}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: CColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _processing ? null : () async {
                      if (widget.onConfirm != null) {
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);
                        setState(() => _processing = true);
                        final orderId = await widget.onConfirm!();
                        if (!mounted) return;
                        setState(() => _processing = false);
                        if (orderId == null) {
                          messenger.showSnackBar(const SnackBar(
                            content: Text('สั่งอาหารไม่สำเร็จ กรุณาลองใหม่')));
                          return;
                        }
                        widget.onSuccess?.call();
                        nav.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => SuccessScreen(orderId: orderId)),
                          (route) => route.isFirst,
                        );
                        return;
                      }
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const SuccessScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('PAY & CONFIRM',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
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
