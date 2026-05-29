import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../../main.dart';

class PaymentWebView extends StatefulWidget {
  final String formUrl;
  final void Function(String url) onPageStarted;
  final VoidCallback onPageFinished;

  const PaymentWebView({
    super.key,
    required this.formUrl,
    required this.onPageStarted,
    required this.onPageFinished,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  @override
  void initState() {
    super.initState();
    // Open payment page in new tab — DigiPay blocks iframe (X-Frame-Options: deny)
    html.window.open(widget.formUrl, '_blank');
    widget.onPageStarted(widget.formUrl);
    widget.onPageFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
              child: const Icon(Icons.open_in_new_rounded, color: CColors.orange, size: 38),
            ),
            const SizedBox(height: 24),
            const Text(
              'เปิดหน้าชำระเงินในแท็บใหม่แล้ว',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CColors.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'กรุณาชำระเงินในแท็บที่เปิดขึ้น\nระบบจะอัปเดตอัตโนมัติเมื่อชำระสำเร็จ',
              style: TextStyle(fontSize: 13, color: CColors.muted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(color: CColors.orange, strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'รอการยืนยันจากระบบ...',
              style: TextStyle(fontSize: 12, color: CColors.muted),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => html.window.open(widget.formUrl, '_blank'),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('เปิดหน้าชำระเงินอีกครั้ง'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CColors.orange,
                side: const BorderSide(color: CColors.orange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
