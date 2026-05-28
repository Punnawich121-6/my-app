import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

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
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'payment-iframe-${DateTime.now().millisecondsSinceEpoch}';

    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = widget.formUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'payment';
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
