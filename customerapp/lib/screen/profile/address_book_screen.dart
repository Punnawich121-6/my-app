import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../location/location_picker_screen.dart';

// ─── Persistent AddressManager ────────────────────────────────────────────────
class AddressManager {
  static const _key = 'saved_addresses';
  static List<Map<String, String>> _addresses = [];
  static bool _loaded = false;

  static List<Map<String, String>> get addresses => List.from(_addresses);

  static Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _addresses = list.map((e) => Map<String, String>.from(e as Map)).toList();
    } else {
      _addresses = [
        {'label': 'บ้าน', 'address': '123 ถ.สุขุมวิท แขวงคลองเตย เขตคลองเตย กทม.', 'icon': 'home'},
        {'label': 'ที่ทำงาน', 'address': '88 ถ.รัชดาภิเษก แขวงห้วยขวาง เขตห้วยขวาง กทม.', 'icon': 'work'},
      ];
    }
    _loaded = true;
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_addresses));
  }

  static Future<void> add(Map<String, String> addr) async {
    _addresses.add(addr);
    await _save();
  }

  static Future<void> remove(int idx) async {
    _addresses.removeAt(idx);
    await _save();
  }

  static Future<void> update(int idx, Map<String, String> addr) async {
    _addresses[idx] = addr;
    await _save();
  }
}

class AddressBookScreen extends StatefulWidget {
  final bool pickMode;
  const AddressBookScreen({super.key, this.pickMode = false});
  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  bool _loadingData = true;

  static const _icons = {
    'home':  Icons.home_rounded,
    'work':  Icons.work_rounded,
    'other': Icons.location_on_rounded,
  };

  @override
  void initState() {
    super.initState();
    AddressManager.load().then((_) {
      if (mounted) setState(() => _loadingData = false);
    });
  }

  void _addOrEdit({int? index}) {
    final editing = index != null;
    final addresses = AddressManager.addresses;
    final labelCtrl = TextEditingController(text: editing ? addresses[index]['label'] : '');
    final addrCtrl  = TextEditingController(text: editing ? addresses[index]['address'] : '');
    String iconKey  = editing ? (addresses[index]['icon'] ?? 'other') : 'other';
    double? lat = editing ? double.tryParse(addresses[index]['lat'] ?? '') : null;
    double? lng = editing ? double.tryParse(addresses[index]['lng'] ?? '') : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: CColors.orangeMid, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(editing ? 'แก้ไขที่อยู่' : 'เพิ่มที่อยู่',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: CColors.text)),
              const SizedBox(height: 20),

              // Icon picker
              Row(children: ['home', 'work', 'other'].map((k) => GestureDetector(
                onTap: () => setSheet(() => iconKey = k),
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

              // Label field
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

              // Address field + map button
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextField(
                    controller: addrCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'ที่อยู่เต็ม',
                      filled: true, fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CColors.orange)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => LocationPickerScreen(
                          initial: lat != null && lng != null ? LatLng(lat!, lng!) : null,
                        ),
                      ),
                    );
                    if (result != null) {
                      setSheet(() {
                        addrCtrl.text = result['address'] as String;
                        lat = result['lat'] as double;
                        lng = result['lng'] as double;
                      });
                    }
                  },
                  child: Container(
                    width: 52, height: 56,
                    decoration: BoxDecoration(
                      color: CColors.orangeLight,
                      borderRadius: BorderRadius.circular(12),
                      border: lat != null ? Border.all(color: CColors.orange, width: 2) : null,
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.location_on_rounded, color: CColors.orange, size: 22),
                      Text('ปักหมุด', style: TextStyle(fontSize: 9, color: CColors.orange, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),

              if (lat != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, color: CColors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text('ปักหมุดแล้ว (${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)})',
                      style: const TextStyle(fontSize: 11, color: CColors.orange)),
                  ]),
                ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (addrCtrl.text.trim().isEmpty) return;
                    final entry = <String, String>{
                      'label': labelCtrl.text.trim().isEmpty ? 'ที่อยู่ใหม่' : labelCtrl.text.trim(),
                      'address': addrCtrl.text.trim(),
                      'icon': iconKey,
                      if (lat != null) 'lat': lat.toString(),
                      if (lng != null) 'lng': lng.toString(),
                    };
                    if (editing) {
                      await AddressManager.update(index, entry);
                    } else {
                      await AddressManager.add(entry);
                    }
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CColors.orange, foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
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
    if (_loadingData) {
      return Scaffold(
        backgroundColor: CColors.bg,
        body: const Center(child: CircularProgressIndicator(color: CColors.orange)),
      );
    }
    final addresses = AddressManager.addresses;
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: CColors.bg,
        elevation: 0,
        title: Text(widget.pickMode ? 'เลือกที่อยู่' : 'สมุดที่อยู่',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: CColors.text)),
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
        backgroundColor: CColors.orange, foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: addresses.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 80, height: 80, decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
                  child: const Icon(Icons.location_on_rounded, color: CColors.orange, size: 40)),
              const SizedBox(height: 16),
              const Text('ยังไม่มีที่อยู่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CColors.text)),
              const SizedBox(height: 8),
              const Text('กด + เพื่อเพิ่มที่อยู่ใหม่', style: TextStyle(color: CColors.muted)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: addresses.length,
              itemBuilder: (_, i) {
                final addr = addresses[i];
                final hasPin = addr['lat'] != null;
                return GestureDetector(
                  onTap: widget.pickMode ? () => Navigator.pop(context, addr) : null,
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
                        Row(children: [
                          Text(addr['label'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: CColors.text)),
                          if (hasPin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(6)),
                              child: const Text('📍 ปักหมุด', style: TextStyle(fontSize: 10, color: CColors.orange, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 3),
                        Text(addr['address'] ?? '', style: const TextStyle(fontSize: 12, color: CColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                      if (!widget.pickMode) Row(children: [
                        IconButton(icon: const Icon(Icons.edit_rounded, size: 18, color: CColors.muted), onPressed: () => _addOrEdit(index: i)),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, size: 18, color: CColors.red),
                          onPressed: () async { await AddressManager.remove(i); setState(() {}); },
                        ),
                      ]) else const Icon(Icons.chevron_right_rounded, color: CColors.muted),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
