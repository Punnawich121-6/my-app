import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../main.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});
  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  static const _methods = [
    {
      'id': 'Cash',
      'icon': Icons.payments_rounded,
      'label': 'Cash',
      'desc': 'ชำระเงินสดเมื่อได้รับอาหาร',
      'color': Color(0xFF43A047),
      'bg': Color(0xFFE8F5E9),
    },
    {
      'id': 'PromptPay',
      'icon': Icons.qr_code_rounded,
      'label': 'PromptPay',
      'desc': 'สแกน QR ผ่านแอปธนาคาร',
      'color': Color(0xFF1565C0),
      'bg': Color(0xFFE3F2FD),
    },
    {
      'id': 'Mastercard',
      'icon': Icons.credit_card_rounded,
      'label': 'Mastercard',
      'desc': 'ชำระด้วยบัตรเครดิต/เดบิต',
      'color': Color(0xFFEB001B),
      'bg': Color(0xFFFFEBEE),
    },
    {
      'id': 'Wallet',
      'icon': Icons.account_balance_wallet_rounded,
      'label': 'Wallet',
      'desc': 'ชำระด้วยยอดเงินใน Wallet',
      'color': Color(0xFF6A1B9A),
      'bg': Color(0xFFF3E5F5),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final selected = settings.defaultPaymentMethod;

    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: CColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Payment Method',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('เลือกวิธีชำระเงินเริ่มต้น',
              style: TextStyle(
                  fontSize: 13, color: CColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: Column(
              children: List.generate(_methods.length, (i) {
                final m = _methods[i];
                final isLast = i == _methods.length - 1;
                final isSelected = m['id'] == selected;
                return Column(children: [
                  InkWell(
                    borderRadius: BorderRadius.vertical(
                      top: i == 0 ? const Radius.circular(16) : Radius.zero,
                      bottom: isLast ? const Radius.circular(16) : Radius.zero,
                    ),
                    onTap: () {
                      settings.setDefaultPaymentMethod(m['id'] as String);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'ตั้ง ${m['label']} เป็นวิธีชำระเงินเริ่มต้นแล้ว'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? CColors.orangeLight
                                : m['bg'] as Color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(m['icon'] as IconData,
                              color: isSelected
                                  ? CColors.orange
                                  : m['color'] as Color,
                              size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(m['label'] as String,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? CColors.orange
                                          : CColors.text)),
                              const SizedBox(height: 2),
                              Text(m['desc'] as String,
                                  style: const TextStyle(
                                      fontSize: 12, color: CColors.muted)),
                            ])),
                        if (isSelected)
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: CColors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16),
                          )
                        else
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFE0E0E0), width: 2),
                            ),
                          ),
                      ]),
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, indent: 76, color: Color(0xFFF5F5F5)),
                ]);
              }),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CColors.orangeLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: CColors.orange, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text('วิธีที่เลือกจะถูกใช้เป็นค่าเริ่มต้นในหน้าชำระเงิน',
                    style: TextStyle(
                        fontSize: 12,
                        color: CColors.orange,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
