import 'package:flutter/material.dart';
import '../../main.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double total;

  const PaymentScreen({super.key, this.total = 96});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selected = 2;

  static const _methods = [
    {'label': 'Cash'},
    {'label': 'Visa'},
    {'label': 'Mastercard'},
    {'label': 'PayPal'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFF3F3F3), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppColors.text),
          ),
        ),
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.text)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMethods(),
                  const SizedBox(height: 24),
                  _buildCardSection(),
                  const SizedBox(height: 20),
                  _buildAddNew(),
                ],
              ),
            ),
          ),
          _buildBottom(),
        ],
      ),
    );
  }

  Widget _buildMethods() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _methods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final sel = _selected == i;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 82,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? AppColors.orange : const Color(0xFFE0E0E0), width: sel ? 2 : 1),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _methodIcon(i),
                        const SizedBox(height: 8),
                        Text(
                          _methods[i]['label']!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text),
                        ),
                      ],
                    ),
                  ),
                  if (sel)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _methodIcon(int i) {
    switch (i) {
      case 0:
        return const Icon(Icons.account_balance_wallet_outlined, color: AppColors.orange, size: 26);
      case 1:
        return const Text(
          'VISA',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1A1F71), letterSpacing: 1.5),
        );
      case 2:
        return SizedBox(
          width: 36, height: 22,
          child: Stack(children: [
            Positioned(
              left: 0,
              child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle)),
            ),
            Positioned(
              left: 14,
              child: Container(width: 22, height: 22, decoration: BoxDecoration(color: const Color(0xFFF79E1B).withValues(alpha: 0.9), shape: BoxShape.circle)),
            ),
          ]),
        );
      case 3:
        return RichText(
          text: const TextSpan(
            children: [
              TextSpan(text: 'Pay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF003087))),
              TextSpan(text: 'Pal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF009CDE))),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildCardGraphic(),
          const SizedBox(height: 22),
          const Text(
            'No master card added',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          const SizedBox(height: 6),
          const Text(
            'You can add a mastercard and\nsave it for later',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGraphic() {
    return SizedBox(
      width: 180,
      height: 110,
      child: Stack(
        children: [
          // Background card (tilted)
          Positioned(
            right: 0, top: 8,
            child: Transform.rotate(
              angle: 0.18,
              child: Container(
                width: 140, height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C42), Color(0xFFFF6B35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          // Main card
          Positioned(
            left: 0, bottom: 0,
            child: Container(
              width: 140, height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5A623), Color(0xFFFF8C42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.orange.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -18, right: -18,
                    child: Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 30, height: 20, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4))),
                        const Spacer(),
                        Container(width: 100, height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(3))),
                        const SizedBox(height: 5),
                        Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(3))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNew() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.orange, size: 20),
            SizedBox(width: 8),
            Text(
              'ADD NEW',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.orange, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Text('TOTAL:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 1)),
              const SizedBox(width: 10),
              Text(
                '\$${widget.total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text),
              ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'PAY & CONFIRM',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
