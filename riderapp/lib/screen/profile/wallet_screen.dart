import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../services/rider_service.dart';
import '../../services/socket_service.dart';

const _kOrange = Color(0xFFFF6B35);
const _kOrangeMid = Color(0xFFFFB299);
const _kOrangeLight = Color(0xFFFFF0EB);

class WalletScreen extends StatefulWidget {
  final String riderId;
  final String riderName;
  const WalletScreen({super.key, required this.riderId, required this.riderName});

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
      RiderService.getWallet(widget.riderId),
      RiderService.getWalletTransactions(widget.riderId),
    ]);
    if (!mounted) return;
    setState(() {
      _balance = ((results[0] as Map)['balance'] as num?)?.toDouble() ?? 0.0;
      _transactions = List<Map<String, dynamic>>.from(results[1] as List);
      _loading = false;
    });
  }

  void _showLoan() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LoanSheet(
        riderId: widget.riderId,
        onSubmitted: _load,
      ),
    );
  }

  void _showLoanHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LoanHistorySheet(riderId: widget.riderId),
    );
  }

  void _showTopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TopupSheet(
        riderId: widget.riderId,
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
    final isNegative = _balance < 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8FF),
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
                decoration: const BoxDecoration(color: Color(0xFFEEEEEE), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_left_rounded, color: RiderColors.text, size: 22),
              ),
            ),
            const Expanded(
              child: Text('วอลเล็ตของฉัน',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: RiderColors.text)),
            ),
            const SizedBox(width: 38),
          ]),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kOrange))
          : RefreshIndicator(
              color: _kOrange,
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
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _kOrange.withValues(alpha: 0.35),
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
                                const Text('Rider Wallet',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                const Spacer(),
                                if (isNegative)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('ติดหนี้', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                              ]),
                              const SizedBox(height: 20),
                              const Text('ยอดคงเหลือ',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(
                                '${isNegative ? '-' : ''}฿${fmt.format(_balance.abs())}',
                                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                              ),
                              if (isNegative) ...[
                                const SizedBox(height: 6),
                                const Text(
                                  'บริษัทออกเงินให้ล่วงหน้า — กรุณาเติมเงินชำระคืน',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ]),
                          ]),
                        ),

                        const SizedBox(height: 16),

                        // Topup button
                        SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _showTopup,
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('เติมเงิน', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kOrange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Loan buttons row
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showLoan,
                              icon: const Icon(Icons.handshake_rounded, size: 18),
                              label: const Text('ขอยืมเงิน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _kOrange,
                                side: const BorderSide(color: _kOrange, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _showLoanHistory,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: RiderColors.muted,
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Icon(Icons.history_rounded, size: 20),
                          ),
                        ]),

                        const SizedBox(height: 8),

                        // Info box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kOrangeLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kOrange.withValues(alpha: 0.2)),
                          ),
                          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(Icons.info_outline_rounded, color: _kOrange, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pre-Paid คือระบบที่บริษัทออกค่าส่งให้ล่วงหน้า เมื่อเติมเงินเข้าวอลเล็ต ยอดหนี้จะถูกหักคืนอัตโนมัติ',
                                style: TextStyle(color: _kOrange, fontSize: 12, height: 1.5),
                              ),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 24),

                        Row(children: [
                          const Text('ประวัติธุรกรรม',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: RiderColors.text)),
                          const Spacer(),
                          Text('${_transactions.length} รายการ',
                              style: const TextStyle(fontSize: 12, color: RiderColors.muted)),
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
                            decoration: BoxDecoration(color: _kOrangeLight, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.receipt_long_rounded, color: _kOrange, size: 36),
                          ),
                          const SizedBox(height: 14),
                          const Text('ยังไม่มีประวัติธุรกรรม',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RiderColors.text)),
                          const SizedBox(height: 4),
                          const Text('บริษัทยังไม่ได้ออกเงินล่วงหน้า',
                              style: TextStyle(fontSize: 13, color: RiderColors.muted)),
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
    final desc = tx['description'] as String? ?? '';
    final isTopup = type == 'topup';
    final isAdvance = type == 'advance';
    final color = isTopup ? const Color(0xFF2E7D32) : isAdvance ? const Color(0xFFD32F2F) : Colors.orange;
    final bgColor = isTopup ? const Color(0xFFE8F5E9) : isAdvance ? const Color(0xFFFFEBEE) : _kOrangeLight;
    final icon = isTopup ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final sign = isTopup ? '+' : '-';
    final label = isAdvance ? 'บริษัทออกเงิน' : isTopup ? 'เติมเงิน' : 'หัก';

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
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(color: RiderColors.muted, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 2),
              Text(dateFmt.format(createdAt.toLocal()),
                  style: const TextStyle(fontSize: 11, color: RiderColors.muted)),
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

// ─── Topup Sheet ──────────────────────────────────────────────────────────────

class _TopupSheet extends StatefulWidget {
  final String riderId;
  final void Function(double newBalance) onSuccess;
  const _TopupSheet({required this.riderId, required this.onSuccess});

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

    final topupId = 'rdr${DateTime.now().millisecondsSinceEpoch}';

    Map<String, dynamic>? payResult;
    if (_method == 'PromptPay') {
      payResult = await RiderService.createQrPayment(
        orderId: topupId, amount: amt,
        description: 'ไรเดอร์เติมเงิน Wallet ฿$amt',
      );
    } else {
      payResult = await RiderService.createCardPayment(
        orderId: topupId, amount: amt,
        description: 'ไรเดอร์เติมเงิน Wallet ฿$amt',
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
      final result = await RiderService.topupRiderWallet(
        riderId: widget.riderId,
        amount: amt.toDouble(),
      );
      if (!mounted) return;
      if (result != null) {
        final newBal = (result['balance'] as num?)?.toDouble() ?? 0.0;
        widget.onSuccess(newBal);
        if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('เติมเงิน ฿$amt สำเร็จ'),
          backgroundColor: _kOrange,
        ));
      }
    }

    if (_method == 'PromptPay') {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _QrSheet(
          topupId: topupId, amount: amt,
          qrResult: payResult!,
          onPaid: handlePaid,
        ),
      );
    } else {
      final formUrl = payResult['form_url'] as String?;
      if (formUrl == null || !mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (_) => _CardSheet(
          topupId: topupId, amount: amt,
          formUrl: formUrl,
          onPaid: handlePaid,
        ),
      );
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: RiderColors.text)),
            const SizedBox(height: 6),
            const Text('กรอกจำนวนเงินที่ต้องการเติม',
                style: TextStyle(fontSize: 13, color: RiderColors.muted)),
            const SizedBox(height: 20),

            // Amount input
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: RiderColors.text),
              textAlign: TextAlign.center,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: '฿  ',
                prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kOrange),
                hintText: '0',
                hintStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _kOrangeMid),
                filled: true,
                fillColor: _kOrangeLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _kOrange, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
            const SizedBox(height: 12),

            // Presets
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
                          color: selected ? _kOrange : _kOrangeLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? _kOrange : _kOrangeMid),
                        ),
                        child: Center(
                          child: Text('฿$amt',
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : _kOrange,
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RiderColors.text)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _MethodCard(
                label: 'PromptPay', subtitle: 'สแกน QR Code',
                icon: Icons.qr_code_rounded,
                selected: _method == 'PromptPay',
                onTap: () => setState(() => _method = 'PromptPay'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _MethodCard(
                label: 'Mastercard', subtitle: 'บัตรเครดิต/เดบิต',
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
                  backgroundColor: _kOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kOrangeMid,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        hasAmount ? 'ชำระเงิน ฿${_amountCtrl.text}' : 'กรอกจำนวนเงิน',
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? _kOrangeLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? _kOrange : const Color(0xFFE8E8E8), width: selected ? 2 : 1),
      ),
      child: Row(children: [
        Icon(icon, color: selected ? _kOrange : RiderColors.muted, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: selected ? _kOrange : RiderColors.text)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: RiderColors.muted)),
        ])),
        if (selected)
          Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(color: _kOrange, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
          ),
      ]),
    ),
  );
}

// ─── QR Payment Sheet ─────────────────────────────────────────────────────────

class _QrSheet extends StatefulWidget {
  final String topupId;
  final int amount;
  final Map<String, dynamic> qrResult;
  final Future<void> Function(bool) onPaid;
  const _QrSheet({required this.topupId, required this.amount, required this.qrResult, required this.onPaid});

  @override
  State<_QrSheet> createState() => _QrSheetState();
}

class _QrSheetState extends State<_QrSheet> {
  Timer? _timer;
  Timer? _fallbackTimer;
  int _secondsLeft = 15 * 60;
  bool _showManualBtn = false;
  bool _confirming = false;

  String? get _qrCode =>
      (widget.qrResult['qr_code'] ?? widget.qrResult['qr_data'] ?? widget.qrResult['qr_image']) as String?;
  String? get _redirectUrl => widget.qrResult['redirect_url'] as String?;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startFallbackTimer();
    _listenSocket();
    if (_qrCode == null) Future.microtask(_openUrl);
  }

  void _startFallbackTimer() {
    // Show manual confirm button after 30s if socket hasn't fired
    _fallbackTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _showManualBtn = true);
    });
  }

  Future<void> _openUrl() async {
    final raw = _redirectUrl;
    if (raw == null || raw.isEmpty) return;
    final url = Uri.parse(raw);
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
    // Small delay to ensure socket is connected before joining room
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      SocketService.instance.joinOrder(widget.topupId);
    });
    SocketService.instance.on('payment_status', (data) async {
      if (!mounted) return;
      _fallbackTimer?.cancel();
      final result = (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      Navigator.pop(context);
      await widget.onPaid(result['status'] == 'APPROVED');
    });
  }

  Future<void> _manualConfirm() async {
    setState(() => _confirming = true);
    _fallbackTimer?.cancel();
    _timer?.cancel();
    SocketService.instance.off('payment_status');
    SocketService.instance.leaveOrder(widget.topupId);
    Navigator.pop(context);
    await widget.onPaid(true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fallbackTimer?.cancel();
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
            decoration: BoxDecoration(color: _kOrangeLight, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.qr_code_rounded, color: _kOrange, size: 32)),
        const SizedBox(height: 14),
        const Text('ชำระเงินด้วย PromptPay',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: RiderColors.text)),
        const SizedBox(height: 4),
        Text('${widget.amount} THB',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kOrange)),
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
            child: QrImageView(data: _qrCode!, version: QrVersions.auto, size: 220, backgroundColor: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text('สแกน QR ด้านบนด้วยแอปธนาคารของคุณ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RiderColors.text)),
        ] else ...[
          Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kOrange.withValues(alpha: 0.8))),
                const SizedBox(width: 10),
                const Text('รอการยืนยันการชำระเงิน...',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RiderColors.text)),
              ]),
              const SizedBox(height: 8),
              const Text('กรุณาสแกน QR ในเบราว์เซอร์\nแล้วชำระผ่านแอปธนาคารของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: RiderColors.muted)),
            ]),
          ),
        ],

        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.timer_outlined, size: 14, color: RiderColors.muted),
          const SizedBox(width: 4),
          Text('หมดอายุใน $_timeLabel', style: const TextStyle(fontSize: 12, color: RiderColors.muted)),
        ]),

        if (_qrCode == null) ...[
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: _openUrl,
              icon: const Icon(Icons.open_in_browser_rounded, size: 18),
              label: const Text('เปิดหน้าชำระเงิน PromptPay',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: _kOrange, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],

        // Manual confirm fallback — appears after 30s
        if (_showManualBtn) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: _confirming ? null : _manualConfirm,
              icon: _confirming
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(_confirming ? 'กำลังบันทึก...' : 'ฉันโอนแล้ว',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('กดหลังจากโอนเงินสำเร็จแล้ว',
              style: TextStyle(fontSize: 11, color: RiderColors.muted)),
        ],
      ]),
    );
  }
}

// ─── Card Payment Sheet ───────────────────────────────────────────────────────

class _CardSheet extends StatefulWidget {
  final String topupId;
  final int amount;
  final String formUrl;
  final Future<void> Function(bool) onPaid;
  const _CardSheet({required this.topupId, required this.amount, required this.formUrl, required this.onPaid});

  @override
  State<_CardSheet> createState() => _CardSheetState();
}

class _CardSheetState extends State<_CardSheet> {
  Timer? _timer;
  Timer? _fallbackTimer;
  int _secondsLeft = 15 * 60;
  bool _showManualBtn = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startFallbackTimer();
    _listenSocket();
    Future.microtask(_openUrl);
  }

  void _startFallbackTimer() {
    _fallbackTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _showManualBtn = true);
    });
  }

  Future<void> _openUrl() async {
    final url = Uri.parse(widget.formUrl);
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
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      SocketService.instance.joinOrder(widget.topupId);
    });
    SocketService.instance.on('payment_status', (data) async {
      if (!mounted) return;
      _fallbackTimer?.cancel();
      final result = (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      Navigator.pop(context);
      await widget.onPaid(result['status'] == 'APPROVED');
    });
  }

  Future<void> _manualConfirm() async {
    setState(() => _confirming = true);
    _fallbackTimer?.cancel();
    _timer?.cancel();
    SocketService.instance.off('payment_status');
    SocketService.instance.leaveOrder(widget.topupId);
    Navigator.pop(context);
    await widget.onPaid(true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fallbackTimer?.cancel();
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
            decoration: BoxDecoration(color: _kOrangeLight, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.credit_card_rounded, color: _kOrange, size: 32)),
        const SizedBox(height: 14),
        const Text('ชำระเงินด้วยบัตรเครดิต',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: RiderColors.text)),
        const SizedBox(height: 4),
        Text('${widget.amount} THB',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kOrange)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kOrange.withValues(alpha: 0.8))),
              const SizedBox(width: 10),
              const Text('รอการยืนยันการชำระเงิน...',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RiderColors.text)),
            ]),
            const SizedBox(height: 8),
            const Text('กรุณากรอกข้อมูลบัตรเครดิตในเบราว์เซอร์\nและยืนยัน OTP ให้เสร็จสิ้น',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: RiderColors.muted)),
          ]),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.timer_outlined, size: 14, color: RiderColors.muted),
          const SizedBox(width: 4),
          Text('หมดอายุใน $_timeLabel', style: const TextStyle(fontSize: 12, color: RiderColors.muted)),
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: _openUrl,
            icon: const Icon(Icons.open_in_browser_rounded, size: 18),
            label: const Text('เปิดหน้าชำระเงิน',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: _kOrange, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),

        // Manual confirm fallback — appears after 30s
        if (_showManualBtn) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: _confirming ? null : _manualConfirm,
              icon: _confirming
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(_confirming ? 'กำลังบันทึก...' : 'ฉันชำระแล้ว',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('กดหลังจากชำระบัตรสำเร็จแล้ว',
              style: TextStyle(fontSize: 11, color: RiderColors.muted)),
        ],
      ]),
    );
  }
}

// ─── Loan Request Sheet ───────────────────────────────────────────────────────

class _LoanSheet extends StatefulWidget {
  final String riderId;
  final VoidCallback onSubmitted;
  const _LoanSheet({required this.riderId, required this.onSubmitted});

  @override
  State<_LoanSheet> createState() => _LoanSheetState();
}

class _LoanSheetState extends State<_LoanSheet> {
  static const _presets = [500, 1000, 2000, 5000];
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  int? get _parsedAmount {
    final v = int.tryParse(_amountCtrl.text);
    return (v != null && v > 0) ? v : null;
  }

  Future<void> _submit() async {
    final amt = _parsedAmount;
    if (amt == null) return;
    setState(() => _loading = true);
    final ok = await RiderService.requestLoan(
      riderId: widget.riderId,
      amount: amt.toDouble(),
      reason: _reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      widget.onSubmitted();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ส่งคำขอยืมเงินแล้ว รอ Admin อนุมัติ'),
        backgroundColor: _kOrange,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่'),
        backgroundColor: _kOrange,
      ));
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
            Container(width: 56, height: 56,
                decoration: BoxDecoration(color: _kOrangeLight, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.handshake_rounded, color: _kOrange, size: 28)),
            const SizedBox(height: 14),
            const Text('ขอยืมเงินจากบริษัท',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: RiderColors.text)),
            const SizedBox(height: 6),
            const Text('Admin จะตรวจสอบและอนุมัติภายใน 24 ชั่วโมง',
                style: TextStyle(fontSize: 13, color: RiderColors.muted)),
            const SizedBox(height: 20),

            // Amount input
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: RiderColors.text),
              textAlign: TextAlign.center,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: '฿  ',
                prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kOrange),
                hintText: '0',
                hintStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _kOrangeMid),
                filled: true,
                fillColor: _kOrangeLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kOrange, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
            const SizedBox(height: 12),

            // Presets
            Row(
              children: _presets.asMap().entries.map((e) {
                final isLast = e.key == _presets.length - 1;
                final amt = e.value;
                final selected = _amountCtrl.text == amt.toString();
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: GestureDetector(
                      onTap: () { _amountCtrl.text = amt.toString(); setState(() {}); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 36,
                        decoration: BoxDecoration(
                          color: selected ? _kOrange : _kOrangeLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? _kOrange : _kOrangeMid),
                        ),
                        child: Center(child: Text('฿$amt',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : _kOrange))),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Reason
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: RiderColors.text),
              decoration: InputDecoration(
                hintText: 'เหตุผลในการขอยืม (ไม่บังคับ) เช่น ค่าน้ำมัน ค่าซ่อมรถ...',
                hintStyle: const TextStyle(color: RiderColors.muted, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kOrange, width: 1.5)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFF57F17), size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'เงินที่ยืมจะถูกบันทึกเป็นยอดหนี้ในวอลเล็ต และหักคืนเมื่อเติมเงิน',
                  style: TextStyle(color: Color(0xFFF57F17), fontSize: 12, height: 1.5),
                )),
              ]),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: (hasAmount && !_loading) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kOrangeMid,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(hasAmount ? 'ส่งคำขอยืม ฿${_amountCtrl.text}' : 'กรอกจำนวนเงิน',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Loan History Sheet ───────────────────────────────────────────────────────

class _LoanHistorySheet extends StatefulWidget {
  final String riderId;
  const _LoanHistorySheet({required this.riderId});

  @override
  State<_LoanHistorySheet> createState() => _LoanHistorySheetState();
}

class _LoanHistorySheetState extends State<_LoanHistorySheet> {
  List<Map<String, dynamic>>? _loans;

  @override
  void initState() {
    super.initState();
    RiderService.getLoanHistory(widget.riderId).then((v) {
      if (mounted) setState(() => _loans = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('ประวัติการขอยืมเงิน',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: RiderColors.text)),
        const SizedBox(height: 16),
        if (_loans == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(color: _kOrange),
          )
        else if (_loans!.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Column(children: [
              Icon(Icons.handshake_rounded, color: RiderColors.muted, size: 40),
              SizedBox(height: 8),
              Text('ยังไม่มีประวัติการขอยืมเงิน', style: TextStyle(color: RiderColors.muted)),
            ]),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _loans!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final loan = _loans![i];
                final status = loan['status'] as String? ?? 'pending';
                final amount = double.tryParse(loan['amount']?.toString() ?? '0') ?? 0;
                final reason = loan['reason'] as String?;
                final adminNote = loan['admin_note'] as String?;
                DateTime? date;
                try { date = DateTime.parse(loan['created_at'].toString()); } catch (_) {}

                final statusColor = status == 'approved'
                    ? const Color(0xFF2E7D32)
                    : status == 'rejected' ? const Color(0xFFD32F2F) : const Color(0xFFF57F17);
                final statusBg = status == 'approved'
                    ? const Color(0xFFE8F5E9)
                    : status == 'rejected' ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1);
                final statusLabel = status == 'approved' ? 'อนุมัติแล้ว' : status == 'rejected' ? 'ปฏิเสธ' : 'รออนุมัติ';
                final statusIcon = status == 'approved'
                    ? Icons.check_circle_rounded
                    : status == 'rejected' ? Icons.cancel_rounded : Icons.schedule_rounded;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('฿${fmt.format(amount)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: RiderColors.text)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(statusIcon, color: statusColor, size: 13),
                          const SizedBox(width: 4),
                          Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(reason, style: const TextStyle(fontSize: 13, color: RiderColors.muted)),
                    ],
                    if (adminNote != null && adminNote.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('หมายเหตุ Admin: $adminNote',
                          style: const TextStyle(fontSize: 12, color: _kOrange)),
                    ],
                    if (date != null) ...[
                      const SizedBox(height: 4),
                      Text(DateFormat('d MMM yyyy  HH:mm').format(date.toLocal()),
                          style: const TextStyle(fontSize: 11, color: RiderColors.muted)),
                    ],
                  ]),
                );
              },
            ),
          ),
      ]),
    );
  }
}
