import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _launched = false;

  Future<void> _openPayment() async {
    final uri = Uri.parse(widget.formUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() => _launched = true);
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
              child: Icon(
                _launched ? Icons.open_in_new_rounded : Icons.credit_card_rounded,
                color: CColors.orange, size: 38,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _launched ? 'เปิดหน้าชำระเงินในแท็บใหม่แล้ว' : 'กดปุ่มด้านล่างเพื่อชำระเงิน',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CColors.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _launched
                  ? 'กรุณาชำระเงินในแท็บที่เปิดขึ้น\nระบบจะอัปเดตอัตโนมัติเมื่อชำระสำเร็จ'
                  : 'ระบบจะเปิดหน้าชำระเงินในแท็บใหม่\nกรุณาอนุญาต popup หากถูกบล็อก',
              style: const TextStyle(fontSize: 13, color: CColors.muted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_launched) ...[
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
                onPressed: _openPayment,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('เปิดหน้าชำระเงินอีกครั้ง'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CColors.orange,
                  side: const BorderSide(color: CColors.orange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _openPayment,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('ชำระเงิน', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
