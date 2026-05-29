import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/socket_service.dart';
import 'payment_view.dart';

class CardWebViewScreen extends StatefulWidget {
  final String orderId;
  final int amount;
  final String formUrl;

  const CardWebViewScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.formUrl,
  });

  @override
  State<CardWebViewScreen> createState() => _CardWebViewScreenState();
}

class _CardWebViewScreenState extends State<CardWebViewScreen> {
  bool _isLoading = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _listenSocket();
  }

  void _listenSocket() {
    SocketService.instance.connect();
    SocketService.instance.joinOrder(widget.orderId);
    SocketService.instance.on('payment_status', (data) {
      if (!mounted) return;
      final result = (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final success = result['status'] == 'APPROVED';
      _handleComplete(success: success, reference: result['reference'] as String?);
    });
  }

  void _handleComplete({required bool success, String? reference}) {
    if (_completed || !mounted) return;
    _completed = true;
    Navigator.of(context).pop({
      'status': success ? 'APPROVED' : 'FAILED',
      'reference': reference,
    });
  }

  void _onPageStarted(String url) {
    if (url.contains('/payment/callback')) {
      final uri = Uri.parse(url);
      final success = uri.queryParameters['process_status'] == 'true';
      _handleComplete(success: success, reference: uri.queryParameters['reference']);
      return;
    }
    if (mounted) setState(() => _isLoading = true);
  }

  void _onPageFinished() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    SocketService.instance.off('payment_status');
    SocketService.instance.leaveOrder(widget.orderId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: CColors.text,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, size: 18, color: CColors.text),
          ),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: CColors.orangeLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_rounded, color: CColors.orange, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ชำระเงิน',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text('${widget.amount} THB',
                    style: const TextStyle(fontSize: 11, color: CColors.orange, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: CColors.orange,
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: PaymentWebView(
        formUrl: widget.formUrl,
        onPageStarted: _onPageStarted,
        onPageFinished: _onPageFinished,
      ),
    );
  }
}
