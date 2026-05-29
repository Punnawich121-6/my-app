import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: widget.onPageStarted,
        onPageFinished: (_) => widget.onPageFinished(),
        onWebResourceError: (_) => widget.onPageFinished(),
        onNavigationRequest: (req) => NavigationDecision.navigate,
      ))
      ..loadRequest(Uri.parse(widget.formUrl));
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
