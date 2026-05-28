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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: CColors.text,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ชำระเงินด้วยบัตร',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('${widget.amount} THB',
                style: const TextStyle(fontSize: 12, color: CColors.orange)),
          ],
        ),
      ),
      body: Stack(
        children: [
          PaymentWebView(
            formUrl: widget.formUrl,
            onPageStarted: _onPageStarted,
            onPageFinished: _onPageFinished,
          ),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(color: CColors.orange),
              ),
            ),
        ],
      ),
    );
  }
}
