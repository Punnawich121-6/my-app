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
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'payment-iframe-${DateTime.now().microsecondsSinceEpoch}';

    final iframe = html.IFrameElement()
      ..src = widget.formUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'payment'
      ..setAttribute('allowfullscreen', 'true');

    iframe.onLoad.listen((_) {
      if (!mounted) return;
      setState(() => _loaded = true);
      widget.onPageFinished();
    });

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (_) => iframe);

    widget.onPageStarted(widget.formUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HtmlElementView(viewType: _viewType),
        if (!_loaded)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
          ),
      ],
    );
  }
}
