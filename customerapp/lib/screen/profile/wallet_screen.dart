import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../services/customer_service.dart';
import '../../services/socket_service.dart';
import '../order/card_webview_screen.dart';

class WalletScreen extends StatefulWidget {
  final String customerId;
  const WalletScreen({super.key, required this.customerId});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      CustomerService.getWalletBalance(widget.customerId),
      CustomerService.getWalletTransactions(widget.customerId),
    ]);
    if (!mounted) return;
    setState(() {
      _balance = results[0] as double;
      _transactions = results[1] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  void _showTopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TopupSheet(
        customerId: widget.customerId,
        onSuccess: (newBalance) {
          setState(() => _balance = newBalance);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
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
                decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_left_rounded, color: CColors.text, size: 22),
              ),
            ),
            const Expanded(
              child: Text('กระเป๋าเงิน',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: CColors.text)),
            ),
            const SizedBox(width: 38),
          ]),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: CColors.orange))
          : RefreshIndicator(
              color: CColors.orange,
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(children: [
                        // Balance card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF9A62)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: CColors.orange.withValues(alpha: 0.35),
                                blurRadius: 20, offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(clipBehavior: Clip.none, children: [
                            Positioned(
                              right: -20, top: -20,
                              child: Container(
                                width: 130, height: 130,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text('Digio Wallet',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                              ]),
                              const SizedBox(height: 20),
                              const Text('ยอดคงเหลือ',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('฿${fmt.format(_balance)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                            ]),
                          ]),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _showTopup,
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('เติมเงิน', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CColors.orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Row(children: [
                          const Text('ประวัติธุรกรรม',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CColors.text)),
                          const Spacer(),
                          Text('${_transactions.length} รายการ',
                              style: const TextStyle(fontSize: 12, color: CColors.muted)),
                        ]),
                        const SizedBox(height: 12),
                      ]),
                    ),
                  ),

                  if (_transactions.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.receipt_long_rounded, color: CColors.orange, size: 36),
                          ),
                          const SizedBox(height: 14),
                          const Text('ยังไม่มีประวัติธุรกรรม',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CColors.text)),
                          const SizedBox(height: 4),
                          const Text('เติมเงินเพื่อเริ่มใช้งาน Digio Wallet',
                              style: TextStyle(fontSize: 13, color: CColors.muted)),
                        ]),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _TxRow(tx: _transactions[i]),
                          childCount: _transactions.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ─── Transaction row ──────────────────────────────────────────────────────────

class _TxRow extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('d MMM yyyy  HH:mm');
    final type = tx['type'] as String? ?? '';
    final amount = double.tryParse(tx['amount']?.toString() ?? '') ?? 0;
    final isTopup = type == 'topup' || type == 'refund';
    final color = isTopup ? const Color(0xFF2E7D32) : CColors.red;
    final bgColor = isTopup ? const Color(0xFFE8F5E9) : CColors.redLight;
    final icon = isTopup ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final sign = isTopup ? '+' : '-';

    DateTime? createdAt;
    try { createdAt = DateTime.parse(tx['created_at'] as String? ?? ''); } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx['description'] as String? ?? type,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.text),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (createdAt != null) ...[
              const SizedBox(height: 2),
              Text(dateFmt.format(createdAt.toLocal()),
                  style: const TextStyle(fontSize: 11, color: CColors.muted)),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Text('$sign฿${fmt.format(amount)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

// ─── Topup sheet ──────────────────────────────────────────────────────────────

class _TopupSheet extends StatefulWidget {
  final String customerId;
  final void Function(double newBalance) onSuccess;
  const _TopupSheet({required this.customerId, required this.onSuccess});

  @override
  State<_TopupSheet> createState() => _TopupSheetState();
}

class _TopupSheetState extends State<_TopupSheet> {
  static const _presets = [100, 200, 500, 1000];
  final _amountCtrl = TextEditingController();
  String _method = 'PromptPay';
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  int? get _parsedAmount {
    final v = int.tryParse(_amountCtrl.text);
    return (v != null && v > 0) ? v : null;
  }

  void _setPreset(int amt) {
    _amountCtrl.text = amt.toString();
    setState(() {});
  }

  Future<void> _confirm() async {
    final amt = _parsedAmount;
    if (amt == null) return;
    setState(() => _loading = true);

    final topupId = 'wlt${DateTime.now().millisecondsSinceEpoch}';

    Map<String, dynamic>? payResult;
    if (_method == 'PromptPay') {
      payResult = await CustomerService.createQrPayment(
        orderId: topupId,
        amount: amt,
        description: 'เติมเงิน Wallet ฿$amt',
      );
    } else {
      payResult = await CustomerService.createCardPayment(
        orderId: topupId,
        amount: amt,
        description: 'เติมเงิน Wallet ฿$amt',
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (payResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถสร้างการชำระเงินได้ กรุณาลองใหม่')));
      return;
    }

    Future<void> handlePaid(bool success) async {
      if (!success || !mounted) return;
      final result = await CustomerService.topupWallet(
        customerId: widget.customerId,
        amount: amt.toDouble(),
      );
      if (!mounted) return;
      if (result != null && result['success'] == true) {
        widget.onSuccess((result['balance'] as num).toDouble());
        if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('เติมเงิน ฿$amt สำเร็จ'),
          backgroundColor: const Color(0xFF2E7D32),
        ));
      }
    }

    if (_method == 'PromptPay') {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _WalletQrSheet(
          topupId: topupId,
          amount: amt,
          qrResult: payResult!,
          onPaid: handlePaid,
        ),
      );
    } else {
      final formUrl = payResult['form_url'] as String?;
      if (formUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถสร้างการชำระเงินได้')));
        return;
      }
      if (!mounted) return;
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => CardWebViewScreen(
            orderId: topupId,
            amount: amt,
            formUrl: formUrl,
          ),
        ),
      );
      if (result != null) {
        await handlePaid(result['status'] == 'APPROVED');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAmount = _parsedAmount != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),

            const Text('เติมเงินเข้า Wallet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: CColors.text)),
            const SizedBox(height: 6),
            const Text('กรอกจำนวนเงินที่ต้องการเติม',
                style: TextStyle(fontSize: 13, color: CColors.muted)),
            const SizedBox(height: 20),

            // Amount input
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: CColors.text),
              textAlign: TextAlign.center,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: '฿  ',
                prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: CColors.orange),
                hintText: '0',
                hintStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: CColors.orangeMid),
                filled: true,
                fillColor: CColors.orangeLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: CColors.orange, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
            const SizedBox(height: 12),

            // Quick presets
            Row(
              children: _presets.asMap().entries.map((e) {
                final isLast = e.key == _presets.length - 1;
                final amt = e.value;
                final selected = _amountCtrl.text == amt.toString();
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => _setPreset(amt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 36,
                        decoration: BoxDecoration(
                          color: selected ? CColors.orange : CColors.orangeLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? CColors.orange : CColors.orangeMid,
                          ),
                        ),
                        child: Center(
                          child: Text('฿$amt',
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : CColors.orange,
                              )),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Payment method
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('วิธีชำระเงิน',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CColors.text)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _MethodCard(
                label: 'PromptPay',
                subtitle: 'สแกน QR Code',
                icon: Icons.qr_code_rounded,
                selected: _method == 'PromptPay',
                onTap: () => setState(() => _method = 'PromptPay'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _MethodCard(
                label: 'Mastercard',
                subtitle: 'บัตรเครดิต/เดบิต',
                icon: Icons.credit_card_rounded,
                selected: _method == 'Mastercard',
                onTap: () => setState(() => _method = 'Mastercard'),
              )),
            ]),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: (hasAmount && !_loading) ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CColors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: CColors.orangeMid,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        hasAmount
                            ? 'ชำระเงิน ฿${_amountCtrl.text}'
                            : 'กรอกจำนวนเงิน',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _MethodCard({required this.label, required this.subtitle, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? CColors.orangeLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? CColors.orange : const Color(0xFFE8E8E8),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? CColors.orange : CColors.muted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: selected ? CColors.orange : CColors.text)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: CColors.muted)),
            ]),
          ),
          if (selected)
            Container(
              width: 18, height: 18,
              decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
            ),
        ]),
      ),
    );
  }
}

// ─── Wallet QR Payment Sheet ──────────────────────────────────────────────────

class _WalletQrSheet extends StatefulWidget {
  final String topupId;
  final int amount;
  final Map<String, dynamic> qrResult;
  final Future<void> Function(bool success) onPaid;
  const _WalletQrSheet({required this.topupId, required this.amount, required this.qrResult, required this.onPaid});

  @override
  State<_WalletQrSheet> createState() => _WalletQrSheetState();
}

class _WalletQrSheetState extends State<_WalletQrSheet> {
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
    if (rawUrl == null || rawUrl.isEmpty) return;
    final url = Uri.parse(rawUrl);
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) { _timer?.cancel(); if (mounted) Navigator.pop(context); }
    });
  }

  void _listenSocket() {
    SocketService.instance.connect();
    SocketService.instance.joinOrder(widget.topupId);
    SocketService.instance.on('payment_status', (data) async {
      if (!mounted) return;
      final result = (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      Navigator.pop(context);
      await widget.onPaid(result['status'] == 'APPROVED');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    SocketService.instance.off('payment_status');
    SocketService.instance.leaveOrder(widget.topupId);
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
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(width: 64, height: 64,
            decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.qr_code_rounded, color: CColors.orange, size: 32)),
        const SizedBox(height: 14),
        const Text('ชำระเงินด้วย PromptPay', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: CColors.text)),
        const SizedBox(height: 4),
        Text('${widget.amount} THB', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: CColors.orange)),
        const SizedBox(height: 16),

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
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: CColors.orange.withValues(alpha: 0.8))),
                const SizedBox(width: 10),
                const Text('รอการยืนยันการชำระเงิน...',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.text)),
              ]),
              const SizedBox(height: 8),
              const Text('กรุณาสแกน QR ในเบราว์เซอร์\nแล้วชำระผ่านแอปธนาคารของคุณ',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: CColors.muted)),
            ]),
          ),
        ],

        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.timer_rounded, size: 14, color: CColors.muted),
          const SizedBox(width: 4),
          Text('หมดอายุใน $_timeLabel', style: const TextStyle(fontSize: 12, color: CColors.muted)),
        ]),
        const SizedBox(height: 16),
        if (_qrCode == null)
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: _openPaymentUrl,
              icon: const Icon(Icons.open_in_browser_rounded, size: 18),
              label: const Text('เปิดหน้าชำระเงิน PromptPay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: CColors.orange, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
      ]),
    );
  }
}

