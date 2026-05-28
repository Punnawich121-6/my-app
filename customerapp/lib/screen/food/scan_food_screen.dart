import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../services/customer_service.dart';

class ScanFoodScreen extends StatefulWidget {
  const ScanFoodScreen({super.key});

  @override
  State<ScanFoodScreen> createState() => _ScanFoodScreenState();
}

class _ScanFoodScreenState extends State<ScanFoodScreen> {
  XFile? _image;
  Uint8List? _imageBytes;
  bool _analyzing = false;
  Map<String, dynamic>? _result;
  String? _error;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _image = picked;
        _imageBytes = bytes;
        _result = null;
        _error = null;
      });
    } catch (e) {
      _showError('ไม่สามารถเปิดกล้อง/แกลเลอรีได้ กรุณาตรวจสอบสิทธิ์การใช้งาน');
    }
  }

  Future<void> _analyze() async {
    if (_image == null || _imageBytes == null) return;
    setState(() { _analyzing = true; _error = null; _result = null; });
    try {
      final result = await CustomerService.scanFood(base64Encode(_imageBytes!));
      if (!mounted) return;
      setState(() { _result = result; _analyzing = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'เกิดข้อผิดพลาด กรุณาลองใหม่'; _analyzing = false; });
    }
  }

  void _reset() => setState(() { _image = null; _imageBytes = null; _result = null; _error = null; });

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
  );

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('เลือกรูปภาพ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CColors.text)),
            const SizedBox(height: 16),
            _PickerOption(
              icon: Icons.camera_alt_rounded,
              label: 'ถ่ายภาพ',
              subtitle: 'เปิดกล้องถ่ายอาหาร',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            const SizedBox(height: 10),
            _PickerOption(
              icon: Icons.photo_library_rounded,
              label: 'เลือกจากแกลเลอรี',
              subtitle: 'เลือกภาพจากคลังรูปภาพ',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
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
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: CColors.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan Food', style: TextStyle(color: CColors.text, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildImageArea(),
            const SizedBox(height: 12),
            _buildPickerButtons(),
            if (_image != null && _result == null && !_analyzing) ...[
              const SizedBox(height: 16),
              _buildAnalyzeButton(),
            ],
            if (_analyzing) ...[
              const SizedBox(height: 32),
              _buildLoadingState(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(),
            ],
            if (_result != null && _result!['error'] != null) ...[
              const SizedBox(height: 16),
              _buildResultError(_result!['error']),
            ],
            if (_result != null && _result!['error'] == null) ...[
              const SizedBox(height: 24),
              _buildResult(),
              const SizedBox(height: 16),
              _buildRescanButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3EC), Color(0xFFFFE0CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: CColors.orange.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: const Icon(Icons.document_scanner_rounded, color: CColors.orange, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('วิเคราะห์โภชนาการด้วย AI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: CColors.text)),
            SizedBox(height: 2),
            Text('ถ่ายหรือเลือกภาพอาหาร เพื่อดูข้อมูล\nแคลอรี่ โปรตีน คาร์บ และไขมัน', style: TextStyle(fontSize: 12, color: CColors.muted, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildImageArea() {
    return GestureDetector(
      onTap: _showPickerSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _image != null ? CColors.orange.withValues(alpha: 0.4) : const Color(0xFFE5E5E5),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: _image != null && _imageBytes != null && _imageBytes!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
              )
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
                  child: const Icon(Icons.add_a_photo_rounded, color: CColors.orange, size: 32),
                ),
                const SizedBox(height: 14),
                const Text('แตะเพื่อเลือกรูปภาพอาหาร', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CColors.text)),
                const SizedBox(height: 4),
                const Text('รองรับ JPG, PNG — แนะนำถ่ายให้เห็นอาหารชัดเจน', style: TextStyle(fontSize: 11, color: CColors.muted)),
              ]),
      ),
    );
  }

  Widget _buildPickerButtons() {
    return Row(children: [
      Expanded(
        child: _OutlineBtn(
          icon: Icons.camera_alt_rounded,
          label: 'ถ่ายภาพ',
          onTap: () => _pickImage(ImageSource.camera),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _OutlineBtn(
          icon: Icons.photo_library_rounded,
          label: 'แกลเลอรี',
          onTap: () => _pickImage(ImageSource.gallery),
        ),
      ),
    ]);
  }

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _analyze,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CColors.orange,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: CColors.orange.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('วิเคราะห์อาหาร', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: CColors.orange.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: const Center(child: CircularProgressIndicator(color: CColors.orange, strokeWidth: 3)),
      ),
      const SizedBox(height: 16),
      const Text('AI กำลังวิเคราะห์อาหาร...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CColors.text)),
      const SizedBox(height: 4),
      const Text('รอสักครู่ กำลังประเมินคุณค่าโภชนาการ', style: TextStyle(fontSize: 12, color: CColors.muted)),
    ]);
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(children: [
        Icon(Icons.error_rounded, color: Colors.red.shade600, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildResultError(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(children: [
        Icon(Icons.image_search_rounded, color: Colors.amber.shade700, size: 40),
        const SizedBox(height: 12),
        Text(msg, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.amber.shade800), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _reset,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(10)),
            child: const Text('ลองใหม่', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final calories = (r['calories'] as num?)?.toInt() ?? 0;
    final protein = (r['protein'] as num?)?.toDouble() ?? 0;
    final carbs = (r['carbs'] as num?)?.toDouble() ?? 0;
    final fat = (r['fat'] as num?)?.toDouble() ?? 0;
    final fiber = (r['fiber'] as num?)?.toDouble() ?? 0;
    final sugar = (r['sugar'] as num?)?.toDouble() ?? 0;
    final sodium = (r['sodium'] as num?)?.toInt() ?? 0;
    final score = (r['healthScore'] as num?)?.toInt() ?? 0;
    final total = protein + carbs + fat;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Food name card
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [CColors.orange, Color(0xFFFF8C5A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: CColors.orange.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r['foodName'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          if ((r['foodNameEn'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(r['foodNameEn'], style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
          ],
          if ((r['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r['description'], style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.4)),
          ],
          if ((r['servingSize'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(r['servingSize'], style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 14),

      // Calories + health score row
      Row(children: [
        Expanded(
          child: _InfoBox(
            label: 'แคลอรี่',
            value: '$calories',
            unit: 'kcal',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF5722),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoBox(
            label: 'Health Score',
            value: '$score',
            unit: '/ 10',
            icon: Icons.favorite_rounded,
            color: _scoreColor(score),
          ),
        ),
      ]),
      const SizedBox(height: 14),

      // Macro grid
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('สารอาหารหลัก', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: CColors.text)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _MacroBar(label: 'โปรตีน', value: protein, total: total, color: const Color(0xFF2196F3), unit: 'g')),
            const SizedBox(width: 10),
            Expanded(child: _MacroBar(label: 'คาร์บ', value: carbs, total: total, color: CColors.orange, unit: 'g')),
            const SizedBox(width: 10),
            Expanded(child: _MacroBar(label: 'ไขมัน', value: fat, total: total, color: const Color(0xFFFFC107), unit: 'g')),
          ]),
        ]),
      ),
      const SizedBox(height: 14),

      // Additional info
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ข้อมูลเพิ่มเติม', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: CColors.text)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ExtraRow(icon: Icons.grass_rounded, label: 'ใยอาหาร', value: '${fiber.toStringAsFixed(1)}g', color: const Color(0xFF4CAF50))),
            Expanded(child: _ExtraRow(icon: Icons.water_drop_rounded, label: 'น้ำตาล', value: '${sugar.toStringAsFixed(1)}g', color: const Color(0xFFE91E63))),
          ]),
          const SizedBox(height: 8),
          _ExtraRow(icon: Icons.science_rounded, label: 'โซเดียม', value: '${sodium}mg', color: const Color(0xFF9C27B0)),
        ]),
      ),

      if ((r['healthNote'] ?? '').toString().isNotEmpty) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _scoreColor(score).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _scoreColor(score).withValues(alpha: 0.25)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.tips_and_updates_rounded, color: _scoreColor(score), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(r['healthNote'], style: TextStyle(fontSize: 13, color: _scoreColor(score).withValues(alpha: 0.85), fontWeight: FontWeight.w500, height: 1.4)),
            ),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildRescanButton() {
    return GestureDetector(
      onTap: _reset,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CColors.orange, width: 1.5),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.refresh_rounded, color: CColors.orange, size: 20),
          SizedBox(width: 8),
          Text('สแกนอาหารใหม่', style: TextStyle(color: CColors.orange, fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 7) return const Color(0xFF4CAF50);
    if (score >= 4) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _PickerOption({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: CColors.orangeLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
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

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: CColors.orange, size: 18),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.text)),
      ]),
    ),
  );
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  const _InfoBox({required this.label, required this.value, required this.unit, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: CColors.muted, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 8),
      RichText(
        text: TextSpan(
          children: [
            TextSpan(text: value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
            TextSpan(text: ' $unit', style: const TextStyle(fontSize: 12, color: CColors.muted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ]),
  );
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final Color color;
  final String unit;
  const _MacroBar({required this.label, required this.value, required this.total, required this.color, required this.unit});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value.toStringAsFixed(1) + unit, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: CColors.muted)),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: color.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
        ),
      ),
    ]);
  }
}

class _ExtraRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ExtraRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16),
    ),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: CColors.muted)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CColors.text)),
    ]),
  ]);
}
