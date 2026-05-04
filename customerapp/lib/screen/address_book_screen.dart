import 'package:flutter/material.dart';
import '../main.dart';

// In-memory address store (session-only)
class AddressManager {
  static final List<Map<String, String>> _addresses = [
    {'label': 'บ้าน', 'address': '123 ถ.สุขุมวิท แขวงคลองเตย เขตคลองเตย กทม.', 'icon': 'home'},
    {'label': 'ที่ทำงาน', 'address': '88 ถ.รัชดาภิเษก แขวงห้วยขวาง เขตห้วยขวาง กทม.', 'icon': 'work'},
  ];

  static List<Map<String, String>> get addresses => List.from(_addresses);
  static void add(Map<String, String> addr) => _addresses.add(addr);
  static void remove(int idx) => _addresses.removeAt(idx);
  static void update(int idx, Map<String, String> addr) => _addresses[idx] = addr;
}

class AddressBookScreen extends StatefulWidget {
  final bool pickMode; // true = selecting address, false = managing
  const AddressBookScreen({super.key, this.pickMode = false});
  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  List<Map<String, String>> get _addresses => AddressManager.addresses;

  static const _icons = {
    'home': Icons.home_rounded,
    'work': Icons.work_rounded,
    'other': Icons.location_on_rounded,
  };

  void _addOrEdit({int? index}) {
    final editing = index != null;
    final labelCtrl = TextEditingController(text: editing ? _addresses[index]['label'] : '');
    final addrCtrl = TextEditingController(text: editing ? _addresses[index]['address'] : '');
    String iconKey = editing ? (_addresses[index]['icon'] ?? 'other') : 'other';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: CColors.orangeMid, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(editing ? 'แก้ไขที่อยู่' : 'เพิ่มที่อยู่', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: CColors.text)),
              const SizedBox(height: 20),
              // Icon picker
              Row(children: ['home', 'work', 'other'].map((k) => GestureDetector(
                onTap: () => setSheetState(() => iconKey = k),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconKey == k ? CColors.orange : CColors.orangeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icons[k], color: iconKey == k ? Colors.white : CColors.orange, size: 22),
                ),
              )).toList()),
              const SizedBox(height: 16),
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  labelText: 'ชื่อที่อยู่ เช่น บ้าน, ที่ทำงาน',
                  filled: true, fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CColors.orange)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addrCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'ที่อยู่เต็ม',
                  filled: true, fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CColors.orange)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (addrCtrl.text.trim().isEmpty) return;
                    final entry = {'label': labelCtrl.text.trim().isEmpty ? 'ที่อยู่ใหม่' : labelCtrl.text.trim(), 'address': addrCtrl.text.trim(), 'icon': iconKey};
                    if (editing) {
                      AddressManager.update(index, entry);
                    } else {
                      AddressManager.add(entry);
                    }
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: CColors.orange, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
          ),
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
        title: Text(widget.pickMode ? 'เลือกที่อยู่' : 'สมุดที่อยู่', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: CColors.text)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: CColors.text),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        backgroundColor: CColors.orange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: _addresses.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 80, height: 80, decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
                    child: const Icon(Icons.location_on_rounded, color: CColors.orange, size: 40)),
                const SizedBox(height: 16),
                const Text('ยังไม่มีที่อยู่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CColors.text)),
                const SizedBox(height: 8),
                const Text('กด + เพื่อเพิ่มที่อยู่ใหม่', style: TextStyle(color: CColors.muted)),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _addresses.length,
              itemBuilder: (_, i) {
                final addr = _addresses[i];
                return GestureDetector(
                  onTap: widget.pickMode ? () => Navigator.pop(context, addr['address']) : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(12)),
                        child: Icon(_icons[addr['icon']] ?? Icons.location_on_rounded, color: CColors.orange, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(addr['label'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: CColors.text)),
                        const SizedBox(height: 3),
                        Text(addr['address'] ?? '', style: const TextStyle(fontSize: 12, color: CColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                      if (!widget.pickMode) Row(children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: CColors.muted), onPressed: () => _addOrEdit(index: i)),
                        IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: CColors.red), onPressed: () {
                          AddressManager.remove(i);
                          setState(() {});
                        }),
                      ]) else const Icon(Icons.chevron_right_rounded, color: CColors.muted),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
