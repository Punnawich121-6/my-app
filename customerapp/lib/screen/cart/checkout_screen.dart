import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../main.dart';
import '../../l10n/strings.dart';
import '../../cart_manager.dart';
import '../../services/customer_service.dart';
import '../../utils/responsive.dart';
import '../location/location_picker_screen.dart';
import '../order/payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String customerId, customerName, customerPhone;
  final List<Map<String, dynamic>> items;
  final int subtotal, deliveryFee, discountAmount, total;
  final String discountLabel;
  final dynamic promoId;
  final VoidCallback onSuccess;

  const CheckoutScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.discountLabel,
    required this.total,
    required this.promoId,
    required this.onSuccess,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _noteCtrl = TextEditingController();
  double? _deliveryLat, _deliveryLng;
  String? _deliveryAddress;
  bool _locationError = false;
  bool _splitEnabled = false;
  int _splitPeople = 2;

  int get _perPerson => (widget.total / _splitPeople).ceil();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: _deliveryLat != null ? LatLng(_deliveryLat!, _deliveryLng!) : null,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      setState(() {
        _deliveryLat = result['lat'] as double;
        _deliveryLng = result['lng'] as double;
        _deliveryAddress = result['address'] as String;
        _locationError = false;
      });
    }
  }

  void _goToPayment() {
    if (_deliveryLat == null) {
      setState(() => _locationError = true);
      return;
    }
    final store = CartManager.instance.store;
    if (store == null) return;
    final orderItems = widget.items.map((i) => {
      'menu_item_id': i['id'],
      'name': i['name'],
      'price': i['price'],
      'quantity': i['qty'],
    }).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: widget.total,
          customerId: widget.customerId,
          onConfirm: () async {
            final result = await CustomerService.placeOrder(
              customerId: widget.customerId,
              customerName: widget.customerName,
              customerPhone: widget.customerPhone,
              storeId: store['id'],
              items: orderItems,
              address: _deliveryAddress ?? '',
              latitude: _deliveryLat,
              longitude: _deliveryLng,
              note: _noteCtrl.text.trim(),
              promoId: widget.promoId,
            );
            if (result != null && result['success'] == true) {
              return result['order_id'] as String?;
            }
            return null;
          },
          onSuccess: widget.onSuccess,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: context.wp(20), color: context.fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(S.checkoutTitle, style: TextStyle(fontSize: context.sp(17), fontWeight: FontWeight.w700, color: context.fg)),
        centerTitle: true,
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.wp(20), context.wp(16), context.wp(20), 0),
            children: [
              // Delivery address
              Text(S.deliveryAddress, style: TextStyle(fontSize: context.sp(13), fontWeight: FontWeight.w500, color: context.fg)),
              SizedBox(height: context.wp(8)),
              GestureDetector(
                onTap: _pickLocation,
                child: Container(
                  padding: EdgeInsets.all(context.wp(14)),
                  decoration: BoxDecoration(
                    color: _locationError ? const Color(0xFFFFEEEE) : context.orangeLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _locationError
                          ? Colors.red
                          : _deliveryLat != null
                              ? CColors.orange
                              : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: _deliveryLat == null
                      ? Row(children: [
                          Icon(Icons.add_location_alt_rounded, color: CColors.orange, size: context.wp(20)),
                          SizedBox(width: context.wp(10)),
                          Expanded(
                            child: Text(
                              _locationError ? S.addressRequired : S.tapToSetAddress,
                              style: TextStyle(fontSize: context.sp(14), color: _locationError ? Colors.red : context.muted),
                            ),
                          ),
                        ])
                      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(
                            padding: EdgeInsets.only(top: context.wp(2)),
                            child: Icon(Icons.location_on_rounded, color: CColors.orange, size: context.wp(18)),
                          ),
                          SizedBox(width: context.wp(8)),
                          Expanded(
                            child: Text(
                              _deliveryAddress ?? '',
                              style: TextStyle(fontSize: context.sp(13), color: context.fg, height: 1.5),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: context.wp(8)),
                          Text(S.change, style: TextStyle(fontSize: context.sp(12), color: CColors.orange, fontWeight: FontWeight.w600)),
                        ]),
                ),
              ),
              SizedBox(height: context.wp(12)),

              // Note
              Text(S.noteLabel, style: TextStyle(fontSize: context.sp(13), fontWeight: FontWeight.w500, color: context.fg)),
              SizedBox(height: context.wp(8)),
              TextField(
                controller: _noteCtrl,
                style: TextStyle(fontSize: context.sp(14), color: context.fg),
                decoration: InputDecoration(
                  hintText: S.noteHint,
                  hintStyle: TextStyle(color: context.muted, fontSize: context.sp(14)),
                ),
              ),
              SizedBox(height: context.wp(20)),

              // Summary
              Container(
                padding: EdgeInsets.all(context.wp(16)),
                decoration: BoxDecoration(color: context.orangeLight, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  _SummaryRow(label: S.foodCost, value: '฿${fmt.format(widget.subtotal)}'),
                  if (widget.discountAmount > 0) ...[
                    SizedBox(height: context.wp(6)),
                    _SummaryRow(label: widget.discountLabel, value: '-฿${fmt.format(widget.discountAmount)}', isDiscount: true),
                  ],
                  SizedBox(height: context.wp(6)),
                  _SummaryRow(label: S.deliveryFee, value: widget.deliveryFee == 0 ? S.free : '฿${widget.deliveryFee}'),
                  Divider(height: context.wp(16), color: CColors.orangeMid),
                  _SummaryRow(label: S.totalLabel, value: '฿${fmt.format(widget.total)}', bold: true),
                ]),
              ),
              SizedBox(height: context.wp(12)),

              // Split bill
              Container(
                decoration: BoxDecoration(color: context.orangeLight, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.wp(16), vertical: context.wp(12)),
                    child: Row(children: [
                      Icon(Icons.group_rounded, color: CColors.orange, size: context.wp(20)),
                      SizedBox(width: context.wp(8)),
                      Text(S.splitBill, style: TextStyle(fontSize: context.sp(14), fontWeight: FontWeight.w700, color: context.fg)),
                      const Spacer(),
                      Switch.adaptive(
                        value: _splitEnabled,
                        onChanged: (v) => setState(() => _splitEnabled = v),
                        activeThumbColor: CColors.orange,
                        activeTrackColor: context.orangeLight,
                      ),
                    ]),
                  ),
                  if (_splitEnabled) ...[
                    Divider(height: 1, color: CColors.orangeMid),
                    Padding(
                      padding: EdgeInsets.fromLTRB(context.wp(16), context.wp(14), context.wp(16), context.wp(16)),
                      child: Column(children: [
                        Row(children: [
                          Text(S.peopleCount, style: TextStyle(fontSize: context.sp(13), color: context.muted, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () { if (_splitPeople > 2) setState(() => _splitPeople--); },
                            child: Container(
                              width: context.wp(32), height: context.wp(32),
                              decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.remove_rounded, color: CColors.orange, size: context.wp(16)),
                            ),
                          ),
                          SizedBox(
                            width: context.wp(40),
                            child: Center(
                              child: Text('$_splitPeople', style: TextStyle(fontSize: context.sp(16), fontWeight: FontWeight.w800, color: context.fg)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _splitPeople++),
                            child: Container(
                              width: context.wp(32), height: context.wp(32),
                              decoration: BoxDecoration(color: CColors.orange, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.add_rounded, color: Colors.white, size: context.wp(16)),
                            ),
                          ),
                        ]),
                        SizedBox(height: context.wp(12)),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: context.wp(16), vertical: context.wp(12)),
                          decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Text(S.perPerson, style: TextStyle(fontSize: context.sp(14), fontWeight: FontWeight.w600, color: context.fg)),
                            const Spacer(),
                            Text('฿${fmt.format(_perPerson)}',
                                style: TextStyle(fontSize: context.sp(22), fontWeight: FontWeight.w800, color: CColors.orange)),
                          ]),
                        ),
                      ]),
                    ),
                  ],
                ]),
              ),
              SizedBox(height: context.wp(100)),
            ],
          ),
        ),

        // Pay button
        Container(
          padding: EdgeInsets.fromLTRB(context.wp(20), context.wp(12), context.wp(20), MediaQuery.of(context).padding.bottom + context.wp(16)),
          decoration: const BoxDecoration(
            color: Colors.transparent,
            boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, -4))],
          ),
          child: SizedBox(
            width: double.infinity,
            height: context.wp(54),
            child: ElevatedButton(
              onPressed: _goToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: CColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(S.selectPaymentBtn(fmt.format(widget.total)),
                  style: TextStyle(fontSize: context.sp(16), fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold, isDiscount;
  const _SummaryRow({required this.label, required this.value, this.bold = false, this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    final baseColor = bold ? context.fg : context.muted;
    final style = TextStyle(
        fontSize: bold ? context.sp(15) : context.sp(13),
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: baseColor);
    final valueColor = isDiscount ? const Color(0xFFD32F2F) : (bold ? CColors.orange : context.muted);
    return Row(children: [
      Text(label, style: style),
      const Spacer(),
      Text(value, style: style.copyWith(color: valueColor)),
    ]);
  }
}
