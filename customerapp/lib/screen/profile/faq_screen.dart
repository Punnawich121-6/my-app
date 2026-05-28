import 'package:flutter/material.dart';
import '../../../main.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  static const _faqs = [
    {
      'q': 'จะยกเลิกออเดอร์ได้ไหม?',
      'a': 'สามารถยกเลิกได้ก่อนร้านยืนยัน หลังจากร้านรับออเดอร์แล้วไม่สามารถยกเลิกได้',
    },
    {
      'q': 'อาหารจะมาถึงนานแค่ไหน?',
      'a': 'โดยเฉลี่ยประมาณ 30-45 นาที ขึ้นอยู่กับระยะทางและความยุ่งของร้าน',
    },
    {
      'q': 'ถ้าอาหารไม่ถูกต้องทำยังไง?',
      'a': 'กรุณาติดต่อฝ่ายบริการลูกค้าผ่านหน้า Support หรือโทรหาร้านค้าโดยตรง',
    },
    {
      'q': 'ชำระเงินด้วยวิธีไหนได้บ้าง?',
      'a': 'รองรับ Cash, PromptPay QR และ Mastercard',
    },
    {
      'q': 'ค่าจัดส่งคำนวณยังไง?',
      'a': 'ค่าจัดส่งคำนวณตามระยะทางจากร้านถึงที่อยู่ของคุณ',
    },
    {
      'q': 'จะเปลี่ยนที่อยู่จัดส่งได้ไหม?',
      'a': 'สามารถเปลี่ยนได้ก่อนกดยืนยันออเดอร์ หลังจากยืนยันแล้วไม่สามารถเปลี่ยนได้',
    },
    {
      'q': 'แอพรองรับกี่ร้าน?',
      'a': 'รองรับร้านอาหารในเครือข่าย Food Delivery ทั้งหมด',
    },
    {
      'q': 'สมัครเป็นร้านอาหารได้ไหม?',
      'a': 'ได้ กรุณาติดต่อทีมงานที่ admin@zestandsavory.com',
    },
  ];

  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: CColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('FAQs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (_, i) {
          final open = _expanded.contains(i);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => open ? _expanded.remove(i) : _expanded.add(i)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Text(_faqs[i]['q']!,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: open ? CColors.orange : CColors.text)),
                        ),
                        Icon(open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: open ? CColors.orange : CColors.muted, size: 22),
                      ]),
                      if (open) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 10),
                        Text(_faqs[i]['a']!,
                            style: const TextStyle(fontSize: 13, color: CColors.muted, height: 1.5)),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
