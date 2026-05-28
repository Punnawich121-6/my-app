import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../services/customer_service.dart';
import '../store/store_screen.dart';

class FoodScanMatchScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;
  const FoodScanMatchScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<FoodScanMatchScreen> createState() => _FoodScanMatchScreenState();
}

class _FoodScanMatchScreenState extends State<FoodScanMatchScreen> {
  XFile? _image;
  Uint8List? _imageBytes;
  bool _scanning = false;
  String? _identified;
  List<Map<String, dynamic>> _matches = [];
  String? _error;
  String? _message;
  final _picker = ImagePicker();
  final _menuCtrl = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() { _image = picked; _imageBytes = bytes; _identified = null; _matches = []; _error = null; _message = null; });
    } catch (_) {
      _snack('ไม่สามารถเปิดกล้องได้ กรุณาตรวจสอบสิทธิ์');
    }
  }

  Future<void> _scan() async {
    if (_image == null || _imageBytes == null) return;
    setState(() { _scanning = true; _error = null; _message = null; _identified = null; _matches = []; });
    try {
      final result = await CustomerService.matchFood(base64Encode(_imageBytes!));
      if (!mounted) return;
      if (result == null) {
        setState(() { _error = 'เกิดข้อผิดพลาด กรุณาลองใหม่'; _scanning = false; });
        return;
      }
      if (result['error'] != null) {
        setState(() { _error = result['error']; _scanning = false; });
        return;
      }
      final matches = (result['matches'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() {
        _identified = result['identified'];
        _matches = matches;
        _message = result['message'];
        _scanning = false;
      });
    } catch (_) {
      if (mounted) setState(() { _error = 'เกิดข้อผิดพลาด กรุณาลองใหม่'; _scanning = false; });
    }
  }

  @override
  void dispose() { _menuCtrl.dispose(); super.dispose(); }

  void _reset() {
    _menuCtrl.clear();
    setState(() { _image = null; _imageBytes = null; _identified = null; _matches = []; _error = null; _message = null; });
  }

  Future<void> _searchByText() async {
    final name = _menuCtrl.text.trim();
    if (name.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _scanning = true; _error = null; _message = null; _identified = null; _matches = []; });
    try {
      final result = await CustomerService.matchFoodByText(name);
      if (!mounted) return;
      if (result == null || result['error'] != null) {
        setState(() { _error = result?['error'] ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่'; _scanning = false; });
        return;
      }
      final matches = (result['matches'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
      setState(() { _identified = result['identified'] ?? name; _matches = matches; _message = result['message']; _scanning = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'เกิดข้อผิดพลาด กรุณาลองใหม่'; _scanning = false; });
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
  );

  void _showPicker() => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('เลือกรูปภาพ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CColors.text)),
          const SizedBox(height: 14),
          _PickerTile(icon: Icons.camera_alt_rounded, label: 'ถ่ายภาพ', subtitle: 'เปิดกล้องถ่ายอาหาร',
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
          const SizedBox(height: 8),
          _PickerTile(icon: Icons.photo_library_rounded, label: 'เลือกจากแกลเลอรี', subtitle: 'เลือกจากคลังรูปภาพ',
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
        ]),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hasResult = _identified != null || _message != null;
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: CColors.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('สแกนหาร้าน', style: TextStyle(color: CColors.text, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        actions: [
          if (_image != null && !_scanning)
            TextButton(onPressed: _reset, child: const Text('รีเซ็ต', style: TextStyle(color: CColors.orange, fontWeight: FontWeight.w600))),
        ],
      ),
      body: Column(children: [
        // Top section: image + buttons
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(children: [
            if (!hasResult && !_scanning) ...[
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _menuCtrl,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _searchByText(),
                    style: const TextStyle(fontSize: 14, color: CColors.text),
                    decoration: InputDecoration(
                      hintText: 'พิมชื่อเมนู เช่น ผัดกะเพรา...',
                      hintStyle: const TextStyle(color: CColors.muted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: CColors.muted, size: 20),
                      suffixIcon: _menuCtrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () { _menuCtrl.clear(); setState(() {}); },
                              child: const Icon(Icons.close_rounded, color: CColors.muted, size: 18),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CColors.orange, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_menuCtrl.text.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _searchByText,
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: CColors.orange, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('ค้นหา', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 10),
              Row(children: [
                const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('หรือถ่ายรูปอาหาร', style: TextStyle(fontSize: 11, color: CColors.muted)),
                ),
                const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
              ]),
              const SizedBox(height: 10),
            ],
            _buildImageArea(),
            const SizedBox(height: 10),
            if (!hasResult && !_scanning)
              Row(children: [
                Expanded(child: _ActionBtn(icon: Icons.camera_alt_rounded, label: 'ถ่ายภาพ', onTap: () => _pickImage(ImageSource.camera))),
                const SizedBox(width: 10),
                Expanded(child: _ActionBtn(icon: Icons.photo_library_rounded, label: 'แกลเลอรี', onTap: () => _pickImage(ImageSource.gallery))),
              ]),
            if (_image != null && !hasResult && !_scanning) ...[
              const SizedBox(height: 10),
              _ScanButton(onTap: _scan),
            ],
          ]),
        ),

        // Bottom section: results
        Expanded(
          child: _scanning
              ? _buildScanning()
              : _error != null
                  ? _buildError()
                  : hasResult
                      ? _buildResults()
                      : _buildHint(),
        ),
      ]),
    );
  }

  Widget _buildImageArea() {
    return GestureDetector(
      onTap: _showPicker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: _image != null ? 200 : 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: CColors.orangeLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _image != null ? CColors.orange.withValues(alpha: 0.4) : const Color(0xFFE5E5E5),
            width: 1.5,
          ),
        ),
        child: _image != null && _imageBytes != null && _imageBytes!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
              )
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 60, height: 60,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.add_a_photo_rounded, color: CColors.orange, size: 28),
                ),
                const SizedBox(height: 10),
                const Text('แตะเพื่อถ่ายหรือเลือกรูปอาหาร', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.text)),
                const SizedBox(height: 3),
                const Text('AI จะค้นหาร้านที่มีเมนูนี้ให้', style: TextStyle(fontSize: 11, color: CColors.muted)),
              ]),
      ),
    );
  }

  Widget _buildScanning() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(color: CColors.orange.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: const Center(child: CircularProgressIndicator(color: CColors.orange, strokeWidth: 3)),
        ),
        const SizedBox(height: 20),
        const Text('AI กำลังวิเคราะห์รูปภาพ...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CColors.text)),
        const SizedBox(height: 6),
        const Text('กำลังค้นหาร้านที่มีเมนูนี้', style: TextStyle(fontSize: 13, color: CColors.muted)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.image_search_rounded, color: CColors.muted.withValues(alpha: 0.5), size: 56),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 14, color: CColors.muted), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _reset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(color: CColors.orange, borderRadius: BorderRadius.circular(12)),
              child: const Text('ลองใหม่', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHint() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 8),
        _HintStep(number: '1', text: 'ถ่ายหรือเลือกรูปอาหารที่อยากกิน'),
        _HintStep(number: '2', text: 'AI วิเคราะห์และระบุชื่ออาหาร'),
        _HintStep(number: '3', text: 'ค้นหาร้านในระบบที่มีเมนูนั้น'),
        _HintStep(number: '4', text: 'เลือกร้านและสั่งได้เลย!'),
      ]),
    );
  }

  Widget _buildResults() {
    final fmt = NumberFormat('#,##0');

    if (_message != null && _matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_off_rounded, color: CColors.muted.withValues(alpha: 0.5), size: 56),
            const SizedBox(height: 16),
            Text(_message!, style: const TextStyle(fontSize: 14, color: CColors.muted), textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Identified label
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: CColors.orange, size: 16),
            const SizedBox(width: 6),
            Text('AI ระบุว่านี่คือ', style: TextStyle(fontSize: 12, color: CColors.muted.withValues(alpha: 0.8))),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Text(_identified ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: CColors.text)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(20)),
              child: Text('พบ ${_matches.length} ร้าน', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CColors.orange)),
            ),
          ]),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFF0F0F0)),

      // Match list
      Expanded(
        child: _matches.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.storefront_rounded, color: CColors.muted.withValues(alpha: 0.4), size: 48),
                  const SizedBox(height: 12),
                  const Text('ไม่พบร้านที่มีเมนูนี้ในระบบ', style: TextStyle(color: CColors.muted, fontSize: 14)),
                ]),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _matches.length,
                itemBuilder: (_, i) {
                  final m = _matches[i];
                  final item = m['item'] as Map<String, dynamic>;
                  final store = m['store'] as Map<String, dynamic>;
                  final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
                  final rating = double.tryParse(store['rating']?.toString() ?? '0') ?? 0;
                  return _MatchCard(
                    item: item,
                    store: store,
                    price: price,
                    rating: rating,
                    fmt: fmt,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StoreScreen(
                        store: store,
                        customerId: widget.customerId,
                        customerName: widget.customerName,
                        customerPhone: widget.customerPhone,
                      ),
                    )),
                  );
                },
              ),
      ),
    ]);
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> store;
  final double price;
  final double rating;
  final NumberFormat fmt;
  final VoidCallback onTap;
  const _MatchCard({required this.item, required this.store, required this.price, required this.rating, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          // Food image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            child: SizedBox(
              width: 100, height: 100,
              child: item['image_url'] != null
                  ? Image.network(item['image_url'], fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder())
                  : _placeholder(),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Match badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_rounded, color: CColors.orange, size: 11),
                    const SizedBox(width: 4),
                    Text(item['name'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CColors.orange), overflow: TextOverflow.ellipsis),
                  ]),
                ),
                const SizedBox(height: 6),
                // Store name
                Text(store['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: CColors.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(store['type'] ?? '', style: const TextStyle(fontSize: 11, color: CColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 13, color: CColors.orange),
                  const SizedBox(width: 3),
                  Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: CColors.muted)),
                  const Spacer(),
                  Text('฿${fmt.format(price)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: CColors.orange)),
                ]),
              ]),
            ),
          ),
          // Arrow
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: CColors.orange, size: 16),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: CColors.orangeLight,
    child: const Center(child: Icon(Icons.fastfood_rounded, color: CColors.orange, size: 30)),
  );
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  const _PickerTile({required this.icon, required this.label, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 19)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CColors.text)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: CColors.muted)),
        ]),
        const Spacer(),
        const Icon(Icons.chevron_right_rounded, color: CColors.muted, size: 20),
      ]),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: CColors.orangeLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D5CC)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: CColors.orange, size: 17),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.text)),
      ]),
    ),
  );
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: CColors.orange,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: CColors.orange.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.image_search_rounded, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text('ค้นหาร้านอาหาร', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
      ]),
    ),
  );
}

class _HintStep extends StatelessWidget {
  final String number, text;
  const _HintStep({required this.number, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(
        width: 30, height: 30,
        decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
        child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: CColors.text, fontWeight: FontWeight.w500))),
    ]),
  );
}
