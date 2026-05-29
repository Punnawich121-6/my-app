import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_settings.dart';
import '../../main.dart';
import '../../services/card_storage_service.dart';
import '../../services/customer_service.dart';
import '../../services/socket_service.dart';
import 'card_webview_screen.dart';
import 'payment_result_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int totalAmount;
  final String? customerId;
  final Future<String?> Function()? onConfirm;
  final VoidCallback? onSuccess;
  const PaymentScreen({super.key, required this.totalAmount, this.customerId, this.onConfirm, this.onSuccess});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selected = AppSettings.instance.defaultPaymentMethod;
  bool _processing = false;
  double _walletBalance = 0;
  SavedCard? _savedCard;

  final _nameCtrl   = TextEditingController();
  final _last4Ctrl  = TextEditingController();
  final _expiryCtrl = TextEditingController();

  static const _methods = [
    {'id': 'Cash',       'label': 'Cash',       'icon': Icons.payments_rounded},
    {'id': 'PromptPay',  'label': 'PromptPay',  'icon': Icons.qr_code_rounded},
    {'id': 'Mastercard', 'label': 'Mastercard',  'icon': Icons.credit_card_rounded},
    {'id': 'Wallet',     'label': 'Wallet',      'icon': Icons.account_balance_wallet_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
    _loadSavedCard();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _last4Ctrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCard() async {
    final card = await CardStorageService.load();
    if (mounted) setState(() => _savedCard = card);
  }

  Future<void> _loadWalletBalance() async {
    if (widget.customerId == null) return;
    final bal = await CustomerService.getWalletBalance(widget.customerId!);
    if (mounted) setState(() => _walletBalance = bal);
  }

  Future<void> _handlePay() async {
    if (_selected == 'Wallet') {
      if (_walletBalance < widget.totalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยอดเงินใน Wallet ไม่เพียงพอ กรุณาเติมเงินก่อน')));
        return;
      }
    }

    if (widget.onConfirm == null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PaymentResultScreen(
            orderId: '-', success: true, amount: 0, paymentMethod: 'Cash')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _processing = true);

    final orderId = await widget.onConfirm!();
    if (!mounted) return;

    if (orderId == null) {
      setState(() => _processing = false);
      messenger.showSnackBar(
          const SnackBar(content: Text('สั่งอาหารไม่สำเร็จ กรุณาลองใหม่')));
      return;
    }

    if (_selected == 'Wallet') {
      final result = await CustomerService.payWithWallet(
        customerId: widget.customerId!,
        amount: widget.totalAmount.toDouble(),
        orderId: orderId,
        description: 'ชำระค่าอาหาร ฿${widget.totalAmount}',
      );
      if (!mounted) return;
      setState(() => _processing = false);
      if (result == null || result['success'] != true) {
        messenger.showSnackBar(
            const SnackBar(content: Text('ชำระเงินด้วย Wallet ไม่สำเร็จ')));
        return;
      }
      widget.onSuccess?.call();
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PaymentResultScreen(
          orderId: orderId, success: true,
          amount: widget.totalAmount, paymentMethod: 'Wallet',
        )),
        (route) => route.isFirst,
      );
      return;
    }

    if (_selected == 'PromptPay') {
      final qrResult = await CustomerService.createQrPayment(
        orderId: orderId,
        amount: widget.totalAmount,
      );
      if (!mounted) return;
      setState(() => _processing = false);

      if (qrResult == null) {
        messenger.showSnackBar(
            const SnackBar(content: Text('ไม่สามารถสร้าง QR ได้ กรุณาลองใหม่')));
        return;
      }

      _showQrSheet(orderId, qrResult, nav);
    } else if (_selected == 'Visa' || _selected == 'Mastercard') {
      final cardResult = await CustomerService.createCardPayment(
        orderId: orderId,
        amount: widget.totalAmount,
      );
      if (!mounted) return;
      setState(() => _processing = false);

      if (cardResult == null || cardResult['form_url'] == null) {
        messenger.showSnackBar(
            const SnackBar(content: Text('ไม่สามารถสร้างการชำระเงินได้ กรุณาลองใหม่')));
        return;
      }

      await _showCardSheet(orderId, cardResult['form_url'] as String, nav);
    } else {
      setState(() => _processing = false);
      widget.onSuccess?.call();
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PaymentResultScreen(
          orderId: orderId,
          success: true,
          amount: widget.totalAmount,
          paymentMethod: 'Cash',
        )),
        (route) => route.isFirst,
      );
    }
  }

  void _showQrSheet(String orderId, Map<String, dynamic> qrResult, NavigatorState nav) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrSheet(
        orderId: orderId,
        amount: widget.totalAmount,
        qrResult: qrResult,
        onPaid: (result) {
          widget.onSuccess?.call();
          nav.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => PaymentResultScreen(
              orderId: orderId,
              success: result['status'] == 'APPROVED',
              reference: result['reference'] as String?,
              amount: widget.totalAmount,
              paymentMethod: 'PromptPay',
            )),
            (route) => route.isFirst,
          );
        },
      ),
    );
  }

  Future<void> _showCardSheet(String orderId, String formUrl, NavigatorState nav) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => CardWebViewScreen(
          orderId: orderId,
          amount: widget.totalAmount,
          formUrl: formUrl,
        ),
      ),
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _processing = false);
      return;
    }
    final approved = result['status'] == 'APPROVED';
    if (approved) await _loadSavedCard();
    if (!mounted) return;
    widget.onSuccess?.call();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PaymentResultScreen(
          orderId: orderId,
          success: approved,
          reference: result['reference'] as String?,
          amount: widget.totalAmount,
          paymentMethod: 'Mastercard',
        ),
      ),
      (route) => route.isFirst,
    );
  }


  Future<void> _showAddCardSheet() async {
    _nameCtrl.clear();
    _last4Ctrl.clear();
    _expiryCtrl.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_card_rounded, color: CColors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('เพิ่มบัตร', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: CColors.text)),
                Text('เก็บเฉพาะ 4 ตัวท้าย • เข้ารหัสใน Keychain/Keystore', style: TextStyle(fontSize: 11, color: CColors.muted)),
              ])),
            ]),
            const SizedBox(height: 20),
            _CardInput(controller: _nameCtrl, hint: 'ชื่อผู้ถือบัตร', icon: Icons.person_rounded),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _CardInput(
                controller: _last4Ctrl,
                hint: 'เลข 4 ตัวท้าย',
                icon: Icons.dialpad_rounded,
                keyboardType: TextInputType.number,
                maxLength: 4,
              )),
              const SizedBox(width: 10),
              Expanded(child: _CardInput(
                controller: _expiryCtrl,
                hint: 'MM/YY',
                icon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.number,
                maxLength: 5,
              )),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ยกเลิก', style: TextStyle(color: CColors.muted, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    final name  = _nameCtrl.text.trim();
                    final last4 = _last4Ctrl.text.trim();
                    final exp   = _expiryCtrl.text.trim();
                    if (name.isEmpty || last4.length != 4) return;
                    await CardStorageService.save(SavedCard(
                      holderName: name,
                      lastFour: last4,
                      expiry: exp,
                      brand: 'Mastercard',
                    ));
                    await _loadSavedCard();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

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
                              color: selected ? CColors.orangeLight : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected ? CColors.orange : const Color(0xFFE8E8E8),
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
                                          color: selected ? CColors.orange : CColors.muted,
                                          size: 28),
                                      const SizedBox(height: 6),
                                      Text(
                                        m['label'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: selected ? CColors.orange : CColors.text,
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
                                          color: CColors.orange, shape: BoxShape.circle),
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

                  // Card / info display
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: _selected == 'Cash'
                          ? const LinearGradient(
                              colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : _selected == 'PromptPay'
                              ? const LinearGradient(
                                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight)
                              : _selected == 'Wallet'
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFF6B35), Color(0xFFFF9A62)],
                                      begin: Alignment.topLeft, end: Alignment.bottomRight)
                                  : _selected == 'Visa'
                                      ? const LinearGradient(
                                          colors: [Color(0xFF1A237E), Color(0xFF283593)],
                                          begin: Alignment.topLeft, end: Alignment.bottomRight)
                                      : const LinearGradient(
                                          colors: [Color(0xFFEB001B), Color(0xFFF79E1B)],
                                          begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                                  _methods.firstWhere((m) => m['id'] == _selected)['icon'] as IconData,
                                  color: Colors.white, size: 32,
                                ),
                                const Spacer(),
                                Text(_selected,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2)),
                              ]),
                              const Spacer(),
                              if (_selected == 'Cash')
                                const Text('Pay with Cash on Delivery',
                                    style: TextStyle(color: Colors.white, fontSize: 13))
                              else if (_selected == 'PromptPay')
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 36),
                                    SizedBox(height: 6),
                                    Text('Scan QR to pay via PromptPay',
                                        style: TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                )
                              else if (_selected == 'Wallet')
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ยอดคงเหลือ ฿${NumberFormat('#,##0.00').format(_walletBalance)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 6),
                                    if (_walletBalance < widget.totalAmount)
                                      const Text('ยอดไม่เพียงพอ กรุณาเติมเงิน',
                                          style: TextStyle(color: Color(0xFFFFCDD2), fontSize: 12))
                                    else
                                      const Text('พร้อมชำระ',
                                          style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _savedCard != null
                                          ? _savedCard!.maskedNumber
                                          : '•••• •••• •••• ••••',
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.75),
                                          fontSize: 15, letterSpacing: 3),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_savedCard != null) ...[
                                      Text(
                                        _savedCard!.holderName.toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Text(
                                          'EXP ${_savedCard!.expiry}',
                                          style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              fontSize: 11),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () async {
                                            await CardStorageService.delete();
                                            setState(() => _savedCard = null);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.delete_rounded, color: Colors.white, size: 12),
                                              SizedBox(width: 4),
                                              Text('ลบบัตร', style: TextStyle(color: Colors.white, fontSize: 11)),
                                            ]),
                                          ),
                                        ),
                                      ]),
                                    ] else
                                      Text(
                                        'กรอกข้อมูลด้านล่างเพื่อบันทึก',
                                        style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 12),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add card button (Mastercard, no saved card yet)
                  if (_selected == 'Mastercard' && _savedCard == null) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _showAddCardSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.add_card_rounded, color: CColors.orange, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('เพิ่มบัตร', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CColors.text)),
                              Text('บันทึกเลข 4 ตัวท้าย • เข้ารหัสใน Keychain/Keystore', style: TextStyle(fontSize: 11, color: CColors.muted)),
                            ]),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: CColors.muted, size: 20),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom: total + pay button
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
                    Text('\$${widget.totalAmount}',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: CColors.text)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _processing ? null : _handlePay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _processing
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            _selected == 'PromptPay'
                                ? 'GET QR CODE'
                                : _selected == 'Wallet'
                                    ? 'ชำระด้วย WALLET'
                                    : 'PAY & CONFIRM',
                            style: const TextStyle(
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

class _QrSheet extends StatefulWidget {
  final String orderId;
  final int amount;
  final Map<String, dynamic> qrResult;
  final void Function(Map<String, dynamic>) onPaid;
  const _QrSheet({
    required this.orderId,
    required this.amount,
    required this.qrResult,
    required this.onPaid,
  });

  @override
  State<_QrSheet> createState() => _QrSheetState();
}

class _QrSheetState extends State<_QrSheet> {
  Timer? _timer;
  int _secondsLeft = 15 * 60;

  String? get _redirectUrl => widget.qrResult['redirect_url'] as String?;
  String? get _qrCode =>
      (widget.qrResult['qr_code'] ?? widget.qrResult['qr_data'] ?? widget.qrResult['qr_image']) as String?;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _listenSocket();
    if (_qrCode == null) Future.microtask(_openPaymentUrl);
  }

  Future<void> _openPaymentUrl() async {
    final rawUrl = _redirectUrl;
    if (rawUrl == null || rawUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบ URL สำหรับชำระเงิน')));
      }
      return;
    }
    final url = Uri.parse(rawUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิดหน้าชำระเงินได้')));
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  void _listenSocket() {
    SocketService.instance.connect();
    SocketService.instance.joinOrder(widget.orderId);
    SocketService.instance.on('payment_status', (data) {
      if (!mounted) return;
      final result = (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      Navigator.pop(context);
      widget.onPaid(result);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    SocketService.instance.off('payment_status');
    SocketService.instance.leaveOrder(widget.orderId);
    super.dispose();
  }

  String get _timeLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: CColors.orangeLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.qr_code_rounded, color: CColors.orange, size: 32),
          ),
          const SizedBox(height: 14),
          const Text('ชำระเงินด้วย PromptPay',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: CColors.text)),
          const SizedBox(height: 4),
          Text('${widget.amount} THB',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: CColors.orange)),
          const SizedBox(height: 20),

          // QR code image (in-app) if available, otherwise browser fallback
          if (_qrCode != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: QrImageView(
                data: _qrCode!,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'สแกน QR ด้านบนด้วยแอปธนาคารของคุณ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.text),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: CColors.orange.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(width: 10),
                  const Text('รอการยืนยันการชำระเงิน...',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.text)),
                ]),
                const SizedBox(height: 10),
                const Text(
                  'กรุณาสแกน QR ในเบราว์เซอร์\nแล้วชำระผ่านแอปธนาคารของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: CColors.muted),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_rounded, size: 15, color: CColors.muted),
              const SizedBox(width: 4),
              Text('หมดอายุใน $_timeLabel',
                  style: const TextStyle(fontSize: 12, color: CColors.muted)),
            ],
          ),
          const SizedBox(height: 16),
          if (_qrCode == null)
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _openPaymentUrl,
                icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                label: const Text('เปิดหน้าชำระเงิน PromptPay',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Card Input Field ─────────────────────────────────────────────────────────

class _CardInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int? maxLength;

  const _CardInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 14, color: CColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: CColors.muted, fontSize: 13),
        prefixIcon: Icon(icon, color: CColors.muted, size: 18),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CColors.orange, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

