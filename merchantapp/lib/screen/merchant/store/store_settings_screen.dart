import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img_lib;
import '../../../app_settings.dart';
import '../../../l10n.dart';
import '../../../main.dart';
import '../../../models/store_model.dart';
import '../../../services/api_service.dart';
import '../../auth/login_screen.dart';
import '../chat/support_chat_screen.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});
  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  Store? _store;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    AppSettings.instance.addListener(_onSettings);
    _load();
  }

  void _onSettings() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_store == null) setState(() => _loading = true);
    try {
      final store = await ApiService.getStore();
      if (!mounted) return;
      setState(() { _store = store; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(t('ออกจากระบบ', 'Sign Out'), style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(t('ต้องการออกจากระบบใช่ไหม?', 'Are you sure you want to sign out?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('ยกเลิก', 'Cancel'), style: const TextStyle(color: AppColors.muted))),
          ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(t('ออกจากระบบ', 'Sign Out')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings.instance.isDark;
    return Scaffold(
    backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF4F4F4),
    appBar: AppBar(
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(t('โปรไฟล์ร้าน', 'Store Profile'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: Colors.red),
          onPressed: _showSignOutDialog,
        ),
      ],
      bottom: TabBar(
        controller: _tab,
        indicatorColor: AppColors.orange,
        indicatorWeight: 2.5,
        labelColor: AppColors.orange,
        unselectedLabelColor: const Color(0xFF9E9E9E),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: [Tab(text: t('ข้อมูลร้าน', 'Store Info')), Tab(text: t('รีวิว', 'Reviews'))],
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
        : _store == null
            ? Center(child: Text(t('เชื่อมต่อ server ไม่ได้', 'Cannot connect to server'), style: const TextStyle(color: AppColors.muted)))
            : TabBarView(controller: _tab, children: [
                _StoreInfoTab(store: _store!, onSaved: _load),
                _ReviewsTab(),
              ]),
  );
  }
}

// ─── Section Widget (customer-settings style) ─────────────────────────────────

class _MSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _MSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings.instance.isDark;
    final cardColor = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
      ),
      Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.10), blurRadius: 8)],
        ),
        child: Column(children: children),
      ),
    ]);
  }
}

// ─── Store Info Tab ───────────────────────────────────────────────────────────

class _StoreInfoTab extends StatefulWidget {
  final Store store;
  final VoidCallback onSaved;
  const _StoreInfoTab({required this.store, required this.onSaved});
  @override
  State<_StoreInfoTab> createState() => _StoreInfoTabState();
}

class _StoreInfoTabState extends State<_StoreInfoTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _address, _openTime, _closeTime;
  late String _selectedType;
  bool _saving = false;
  bool _uploadingImage = false;
  bool _aiProcessing = false;
  String? _previewImageUrl;
  bool _generatingName = false;

  static const _categories = [
    'อาหารไทย', 'อาหารจีน', 'อาหารญี่ปุ่น', 'อาหารเกาหลี',
    'อาหารอิตาเลียน', 'อาหารฝรั่ง', 'อาหารอินเดีย', 'อาหารเวียดนาม',
    'ก๋วยเตี๋ยว / ข้าวต้ม', 'ข้าวแกง / ข้าวกล่อง', 'ส้มตำ / อีสาน',
    'ชาบู / ปิ้งย่าง', 'พิซซ่า / เบอร์เกอร์', 'ซูชิ / ซาซิมิ',
    'กาแฟ / เครื่องดื่ม', 'เบเกอรี่ / ของหวาน', 'ผลไม้ / สลัด',
    'อาหารทะเล', 'มังสวิรัติ / เจ', 'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.store.name);
    _selectedType = _categories.contains(widget.store.type) ? widget.store.type : (_categories.first);
    _address = TextEditingController(text: widget.store.address);
    _openTime = TextEditingController(text: widget.store.openTime);
    _closeTime = TextEditingController(text: widget.store.closeTime);
    _previewImageUrl = widget.store.imageUrl;
    AppSettings.instance.addListener(_onSettings);
  }

  void _onSettings() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _name.dispose(); _address.dispose();
    _openTime.dispose(); _closeTime.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (picked == null || !mounted) return;

    setState(() { _uploadingImage = true; _aiProcessing = true; });

    Uint8List originalBytes = Uint8List(0);
    Uint8List? aiCroppedBytes;

    try {
      originalBytes = await picked.readAsBytes();
      final ext = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      final dataUri = 'data:image/$ext;base64,${base64Encode(originalBytes)}';

      final cropData = await ApiService.autoCropImage(dataUri);
      if (cropData != null) {
        final srcImg = img_lib.decodeImage(originalBytes);
        if (srcImg != null) {
          final cx = ((cropData['x'] as num? ?? 0).toDouble() * srcImg.width).round().clamp(0, srcImg.width - 1);
          final cy = ((cropData['y'] as num? ?? 0).toDouble() * srcImg.height).round().clamp(0, srcImg.height - 1);
          final cw = ((cropData['w'] as num? ?? 1).toDouble() * srcImg.width).round().clamp(1, srcImg.width - cx);
          final ch = ((cropData['h'] as num? ?? 1).toDouble() * srcImg.height).round().clamp(1, srcImg.height - cy);
          final cropped = img_lib.copyCrop(srcImg, x: cx, y: cy, width: cw, height: ch);
          aiCroppedBytes = Uint8List.fromList(img_lib.encodeJpg(cropped, quality: 85));
        }
      }
    } catch (_) {}

    if (!mounted) { setState(() { _uploadingImage = false; _aiProcessing = false; }); return; }
    setState(() { _uploadingImage = false; _aiProcessing = false; });

    final result = await _showCropSheet(aiCroppedBytes: aiCroppedBytes, originalBytes: originalBytes);
    if (result == null || !mounted) return;

    setState(() => _uploadingImage = true);
    try {
      final url = await ApiService.uploadStoreImage('data:image/jpeg;base64,${base64Encode(result)}');
      if (!mounted) return;
      if (url != null) {
        setState(() => _previewImageUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('อัปโหลดรูปร้านสำเร็จ', 'Photo uploaded successfully')), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('อัปโหลดรูปไม่สำเร็จ', 'Upload failed')), backgroundColor: Colors.red));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('อัปโหลดรูปไม่สำเร็จ', 'Upload failed')), backgroundColor: Colors.red));
    }
    if (!mounted) return;
    setState(() => _uploadingImage = false);
  }

  Future<Uint8List?> _showCropSheet({required Uint8List? aiCroppedBytes, required Uint8List originalBytes}) {
    return showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CropChoiceSheet(aiCroppedBytes: aiCroppedBytes, originalBytes: originalBytes),
    );
  }

  Future<void> _generateStoreName() async {
    final type = _selectedType;
    setState(() => _generatingName = true);
    final result = await ApiService.generateDescription(storeName: type.isEmpty ? 'ร้านอาหาร' : type, context: 'store_name');
    if (!mounted) return;
    if (result != null && result['description'] != null) setState(() => _name.text = result['description']);
    setState(() => _generatingName = false);
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = parts.length == 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0)
        : TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.orange)),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => ctrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.updateStore({
        'name': _name.text.trim(),
        'type': _selectedType,
        'address': _address.text.trim(),
        'open_time': _openTime.text.trim(),
        'close_time': _closeTime.text.trim(),
        'lat': widget.store.lat,
        'lng': widget.store.lng,
      });
      if (!mounted) return;
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('บันทึกสำเร็จ', 'Saved successfully')), backgroundColor: Colors.green));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('บันทึกไม่สำเร็จ', 'Save failed')), backgroundColor: Colors.red));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings.instance.isDark;
    final fg = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final dividerColor = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE0E0E0);
    return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
    child: Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildProfileHeader(isDark: isDark, fg: fg),
        const SizedBox(height: 20),
        _MSection(title: t('ข้อมูลร้าน', 'Store Info'), children: [
          _buildNameRow(fg: fg),
          Divider(height: 1, indent: 64, endIndent: 0, color: dividerColor),
          _buildFieldRow(
            icon: Icons.category_outlined,
            label: t('ประเภทร้าน', 'Store Type'),
            fg: fg,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9E9E9E), size: 20),
                style: TextStyle(fontSize: 14, color: fg, fontFamily: 'Prompt'),
                onChanged: (v) { if (v != null) setState(() => _selectedType = v); },
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              ),
            ),
          ),
          Divider(height: 1, indent: 64, endIndent: 0, color: dividerColor),
          _buildFieldRow(
            icon: Icons.location_on_outlined,
            label: t('ที่อยู่', 'Address'),
            fg: fg,
            child: _field(_address, hint: t('ที่อยู่ร้าน', 'Store address'), maxLines: 2, isDark: isDark),
          ),
        ]),
        const SizedBox(height: 16),
        _MSection(title: t('เวลาทำการ', 'Business Hours'), children: [
          _buildTimeRow(icon: Icons.wb_sunny_outlined, label: t('เปิด', 'Open'), ctrl: _openTime, fg: fg),
          Divider(height: 1, indent: 64, endIndent: 0, color: dividerColor),
          _buildTimeRow(icon: Icons.nights_stay_outlined, label: t('ปิด', 'Close'), ctrl: _closeTime, fg: fg),
        ]),
        if (widget.store.bankName != null || widget.store.accountName != null || widget.store.accountNo != null) ...[
          const SizedBox(height: 16),
          _MSection(title: t('บัญชีธนาคาร', 'Bank Account'), children: [
            if (widget.store.bankName != null)
              _buildInfoTile(icon: Icons.account_balance_outlined, label: t('ธนาคาร', 'Bank'), value: widget.store.bankName!, fg: fg),
            if (widget.store.accountName != null) ...[
              Divider(height: 1, indent: 64, endIndent: 0, color: dividerColor),
              _buildInfoTile(icon: Icons.person_outline_rounded, label: t('ชื่อบัญชี', 'Account Name'), value: widget.store.accountName!, fg: fg),
            ],
            if (widget.store.accountNo != null) ...[
              Divider(height: 1, indent: 64, endIndent: 0, color: dividerColor),
              _buildInfoTile(icon: Icons.credit_card_rounded, label: t('เลขบัญชี', 'Account No.'), value: widget.store.accountNo!, fg: fg),
            ],
          ]),
        ],
        const SizedBox(height: 16),
        _MSection(title: t('การแสดงผล', 'Display'), children: [
          _buildSwitchTile(
            icon: Icons.dark_mode_rounded,
            iconBg: const Color(0xFF2D2D44),
            iconColor: const Color(0xFFB39DDB),
            label: t('โหมดมืด', 'Dark Mode'),
            desc: t('เปลี่ยนธีมเป็นสีเข้ม', 'Switch to dark theme'),
            value: AppSettings.instance.isDark,
            onChanged: (_) => AppSettings.instance.toggleTheme(),
            fg: fg,
          ),
          Divider(height: 1, indent: 64, endIndent: 0, color: dividerColor),
          _buildSwitchTile(
            icon: Icons.language_rounded,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1976D2),
            label: 'English',
            desc: t('สลับภาษาอังกฤษ / ไทย', 'Switch language EN / TH'),
            value: AppSettings.instance.isEnglish,
            onChanged: (v) => AppSettings.instance.setEnglish(v),
            fg: fg,
          ),
        ]),
        const SizedBox(height: 16),
        _MSection(title: t('ช่วยเหลือ', 'Help'), children: [_buildSupportTile(fg: fg)]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(t('บันทึกการเปลี่ยนแปลง', 'Save Changes'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ),
  );
  }

  // ── Profile Header ────────────────────────────────────────────────────────

  Widget _buildProfileHeader({required bool isDark, required Color fg}) {
    final status = widget.store.status;
    final statusColor = <String, Color>{
      'pending': AppColors.orange,
      'active': Colors.green,
      'inactive': Colors.grey,
      'approved': Colors.green,
      'rejected': Colors.red,
    }[status] ?? Colors.grey;
    final statusLabel = {
      'pending': t('รอการอนุมัติ', 'Pending Approval'),
      'active': t('เปิดใช้งาน', 'Active'),
      'inactive': t('ปิดใช้งาน', 'Inactive'),
      'approved': t('อนุมัติแล้ว', 'Approved'),
      'rejected': t('ถูกปฏิเสธ', 'Rejected'),
    }[status] ?? status;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? null : Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.10), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        SizedBox(
          height: 160,
          width: double.infinity,
          child: Stack(fit: StackFit.expand, children: [
            if (_previewImageUrl != null && _previewImageUrl!.isNotEmpty)
              Image.network(_previewImageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder())
            else
              _imagePlaceholder(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                ),
              ),
            ),
            if (_uploadingImage)
              Container(
                color: Colors.black38,
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    _aiProcessing ? t('AI กำลังวิเคราะห์รูป...', 'AI analyzing photo...') : t('กำลังอัปโหลด...', 'Uploading...'),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ])),
              ),
            if (!_uploadingImage)
              Positioned(
                top: 12, right: 12,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(t('เปลี่ยนรูป', 'Change Photo'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                widget.store.name.isNotEmpty ? widget.store.name : t('ร้านของฉัน', 'My Store'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: fg),
              ),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, color: AppColors.orange, size: 14),
                const SizedBox(width: 3),
                Text(
                  '${widget.store.rating} (${widget.store.reviewCount} ${t('รีวิว', 'reviews')})',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ]),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: AppColors.orangeLight,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.add_photo_alternate_outlined, color: AppColors.orange, size: 40),
      const SizedBox(height: 8),
      Text(t('แตะเพื่ออัปโหลดรูปร้าน', 'Tap to upload store photo'), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
    ]),
  );

  // ── Section Tiles ─────────────────────────────────────────────────────────

  Widget _buildNameRow({required Color fg}) {
    final isDark = AppSettings.instance.isDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.store_rounded, color: AppColors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(t('ชื่อร้าน', 'Store Name'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg))),
          GestureDetector(
            onTap: _generatingName ? null : _generateStoreName,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(20)),
              child: _generatingName
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 1.5)),
                      const SizedBox(width: 5),
                      Text(t('กำลังสร้าง...', 'Generating...'), style: const TextStyle(fontSize: 11, color: AppColors.orange)),
                    ])
                  : const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.auto_awesome_rounded, color: AppColors.orange, size: 12),
                      SizedBox(width: 4),
                      Text('AI Generate', style: TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w700)),
                    ]),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        _field(_name, hint: t('ชื่อร้าน', 'Store name'), isDark: isDark, validator: (v) => (v == null || v.trim().isEmpty) ? t('กรุณากรอกชื่อร้าน', 'Please enter store name') : null),
      ]),
    );
  }

  Widget _buildFieldRow({required IconData icon, required String label, required Color fg, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }

  Widget _buildTimeRow({required IconData icon, required String label, required TextEditingController ctrl, required Color fg}) {
    return GestureDetector(
      onTap: () => _pickTime(ctrl),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg))),
          Text(
            ctrl.text.isEmpty ? '--:--' : ctrl.text,
            style: const TextStyle(fontSize: 14, color: AppColors.orange, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD), size: 20),
        ]),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String label, required String value, required Color fg}) {
    final isDark = AppSettings.instance.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg))),
        Text(value, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      ]),
    );
  }

  Widget _buildSupportTile({required Color fg}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportChatScreen())),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.support_agent_rounded, color: AppColors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t('ติดต่อ Admin', 'Contact Admin'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
            Text(t('สอบถามหรือขอความช่วยเหลือ', 'Ask questions or get help'), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD), size: 20),
        ]),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color fg,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
          Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ])),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.orange, activeTrackColor: AppColors.orangeMid),
      ]),
    );
  }

  // ── Field ─────────────────────────────────────────────────────────────────

  Widget _field(TextEditingController ctrl, {required String hint, required bool isDark, String? Function(String?)? validator, int maxLines = 1}) => TextFormField(
    controller: ctrl,
    validator: validator,
    maxLines: maxLines,
    style: TextStyle(fontSize: 15, color: isDark ? const Color(0xFFF0F0F0) : AppColors.text),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.muted),
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF6F6F6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orange, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

// ─── Crop Choice Sheet ────────────────────────────────────────────────────────

class _CropChoiceSheet extends StatefulWidget {
  final Uint8List? aiCroppedBytes;
  final Uint8List originalBytes;
  const _CropChoiceSheet({this.aiCroppedBytes, required this.originalBytes});
  @override
  State<_CropChoiceSheet> createState() => _CropChoiceSheetState();
}

class _CropChoiceSheetState extends State<_CropChoiceSheet> {
  Future<void> _openManualCrop() async {
    if (widget.originalBytes.isEmpty) return;
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => _ManualCropScreen(imageBytes: widget.originalBytes)),
    );
    if (result != null && mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final previewBytes = widget.aiCroppedBytes ?? (widget.originalBytes.isNotEmpty ? widget.originalBytes : null);
    final hasAI = widget.aiCroppedBytes != null;

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.orange, size: 18),
            const SizedBox(width: 8),
            Text(hasAI ? 'AI ตัดรูปให้อัตโนมัติแล้ว' : 'เลือกการตัดรูป',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
          ]),
          const SizedBox(height: 4),
          Text(
            hasAI ? 'ต้องการใช้ผลลัพธ์นี้ หรือต้องการ Crop เองแทน?' : 'AI วิเคราะห์ไม่สำเร็จ — กรุณา Crop เองหรือใช้รูปเต็ม',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          if (previewBytes != null)
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(previewBytes, height: 200, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openManualCrop,
                icon: const Icon(Icons.crop, size: 16),
                label: const Text('Crop เอง'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.orange,
                  side: const BorderSide(color: AppColors.orange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: previewBytes != null ? () => Navigator.pop(context, previewBytes) : null,
                icon: const Icon(Icons.check, size: 16, color: Colors.white),
                label: Text(hasAI ? 'ใช้รูปนี้' : 'ใช้รูปเต็ม', style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ]),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ─── Manual Crop Screen ───────────────────────────────────────────────────────

class _ManualCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const _ManualCropScreen({required this.imageBytes});
  @override
  State<_ManualCropScreen> createState() => _ManualCropScreenState();
}

class _ManualCropScreenState extends State<_ManualCropScreen> {
  double _l = 0.05, _t = 0.05, _r = 0.95, _b = 0.95;
  img_lib.Image? _srcImg;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _srcImg = img_lib.decodeImage(widget.imageBytes);
  }

  Rect _imageBounds(Size size) {
    if (_srcImg == null) return Rect.fromLTWH(0, 0, size.width, size.height);
    final imgA = _srcImg!.width / _srcImg!.height;
    final cA = size.width / size.height;
    double w, h;
    if (imgA > cA) { w = size.width; h = size.width / imgA; }
    else            { h = size.height; w = size.height * imgA; }
    return Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
  }

  void _updateL(double dx, double bw) => setState(() { _l = (_l + dx / bw).clamp(0.0, _r - 0.05); });
  void _updateT(double dy, double bh) => setState(() { _t = (_t + dy / bh).clamp(0.0, _b - 0.05); });
  void _updateR(double dx, double bw) => setState(() { _r = (_r + dx / bw).clamp(_l + 0.05, 1.0); });
  void _updateB(double dy, double bh) => setState(() { _b = (_b + dy / bh).clamp(_t + 0.05, 1.0); });

  Future<void> _applyCrop() async {
    if (_srcImg == null) { Navigator.pop(context); return; }
    setState(() => _applying = true);
    final x = (_l * _srcImg!.width).round().clamp(0, _srcImg!.width - 1);
    final y = (_t * _srcImg!.height).round().clamp(0, _srcImg!.height - 1);
    final w = ((_r - _l) * _srcImg!.width).round().clamp(1, _srcImg!.width - x);
    final h = ((_b - _t) * _srcImg!.height).round().clamp(1, _srcImg!.height - y);
    final cropped = img_lib.copyCrop(_srcImg!, x: x, y: y, width: w, height: h);
    final bytes = Uint8List.fromList(img_lib.encodeJpg(cropped, quality: 85));
    if (mounted) Navigator.pop(context, bytes);
  }

  Widget _handle(Offset pos, void Function(DragUpdateDetails, double, double) onDrag, Rect bounds) {
    const r = 22.0;
    return Positioned(
      left: pos.dx - r, top: pos.dy - r, width: r * 2, height: r * 2,
      child: GestureDetector(
        onPanUpdate: (d) => onDrag(d, bounds.width, bounds.height),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.orange, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop รูปร้าน', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          _applying
              ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2)))
              : TextButton(onPressed: _applyCrop, child: const Text('ยืนยัน', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 15))),
        ],
      ),
      body: LayoutBuilder(builder: (ctx, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final bounds = _imageBounds(size);
        final tl = Offset(bounds.left + _l * bounds.width, bounds.top + _t * bounds.height);
        final br = Offset(bounds.left + _r * bounds.width, bounds.top + _b * bounds.height);
        final tr = Offset(br.dx, tl.dy);
        final bl = Offset(tl.dx, br.dy);

        return Stack(children: [
          Positioned.fill(child: Image.memory(widget.imageBytes, fit: BoxFit.contain)),
          Positioned.fill(child: CustomPaint(painter: _CropOverlayPainter(cropRect: Rect.fromPoints(tl, br)))),
          _handle(tl, (d, bw, bh) { _updateL(d.delta.dx, bw); _updateT(d.delta.dy, bh); }, bounds),
          _handle(tr, (d, bw, bh) { _updateR(d.delta.dx, bw); _updateT(d.delta.dy, bh); }, bounds),
          _handle(bl, (d, bw, bh) { _updateL(d.delta.dx, bw); _updateB(d.delta.dy, bh); }, bounds),
          _handle(br, (d, bw, bh) { _updateR(d.delta.dx, bw); _updateB(d.delta.dy, bh); }, bounds),
          Positioned(
            bottom: 20, left: 0, right: 0,
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: const Text('ลากมุมสีส้มเพื่อปรับขนาด', style: TextStyle(color: Colors.white, fontSize: 12)),
            )),
          ),
        ]);
      }),
    );
  }
}

// ─── Crop Overlay Painter ─────────────────────────────────────────────────────

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  const _CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black54);
    canvas.drawRect(cropRect, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

    final grid = Paint()..color = Colors.white.withValues(alpha: 0.35)..strokeWidth = 0.7;
    final w3 = cropRect.width / 3;
    final h3 = cropRect.height / 3;
    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(Offset(cropRect.left + w3 * i, cropRect.top), Offset(cropRect.left + w3 * i, cropRect.bottom), grid);
      canvas.drawLine(Offset(cropRect.left, cropRect.top + h3 * i), Offset(cropRect.right, cropRect.top + h3 * i), grid);
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) => old.cropRect != cropRect;
}

// ─── Reviews Tab ──────────────────────────────────────────────────────────────

class _ReviewsTab extends StatefulWidget {
  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onSettings);
    _load();
  }

  void _onSettings() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getReviews();
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    if (_data == null) return Center(child: Text(t('เชื่อมต่อไม่ได้', 'Cannot connect'), style: const TextStyle(color: AppColors.muted)));
    final reviews = (_data!['reviews'] as List?) ?? [];
    final avg = double.tryParse((_data!['average'] ?? 0).toString()) ?? 0.0;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: [
      _MSection(title: t('ภาพรวม', 'Overview'), children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [
              Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.orange)),
              Row(children: List.generate(5, (i) => Icon(
                i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppColors.orange, size: 18,
              ))),
              const SizedBox(height: 4),
              Text('${_data!['total'] ?? _data!['count'] ?? 0} ${t('รีวิว', 'reviews')}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ]),
        ),
      ]),
      const SizedBox(height: 16),
      if (reviews.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(t('รีวิวทั้งหมด', 'All Reviews'), style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ),
        ...reviews.map((r) => _ReviewCard(review: r, onReplied: _load)),
      ] else
        Center(child: Text(t('ยังไม่มีรีวิว', 'No reviews yet'), style: const TextStyle(color: AppColors.muted))),
    ]);
  }
}

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  final VoidCallback onReplied;
  const _ReviewCard({required this.review, required this.onReplied});
  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _showReplyBox = false;
  final _replyCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _replyCtrl.text = widget.review['reply'] ?? '';
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  List<String> _parseImages(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return List<String>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try { return List<String>.from(jsonDecode(raw)); } catch (_) {}
    }
    return [];
  }

  Widget _buildReviewImages(dynamic raw) {
    final urls = _parseImages(raw);
    if (urls.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 76,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.black,
                insetPadding: EdgeInsets.zero,
                child: Stack(children: [
                  InteractiveViewer(child: Image.network(urls[i], fit: BoxFit.contain)),
                  Positioned(
                    top: 8, right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ]),
              ),
            ),
            child: Container(
              width: 72, height: 72,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF0F0F0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  urls[i], fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image_rounded, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveReply() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ApiService.replyToReview(widget.review['id'].toString(), _replyCtrl.text.trim());
      if (!mounted) return;
      setState(() { _showReplyBox = false; _saving = false; });
      widget.onReplied();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = (widget.review['rating'] as num?)?.toInt() ?? 0;
    final name = widget.review['customer_name']?.toString() ?? 'Customer';
    final comment = widget.review['comment']?.toString() ?? '';
    final existingReply = widget.review['reply']?.toString() ?? '';
    DateTime? date;
    try { date = DateTime.parse(widget.review['created_at'].toString()); } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: AppColors.orangeLight, radius: 18,
            child: Text(name[0], style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (date != null) Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ])),
          Row(children: List.generate(5, (i) => Icon(
            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppColors.orange, size: 14,
          ))),
        ]),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(fontSize: 13, color: AppColors.text)),
        ],
        _buildReviewImages(widget.review['images']),
        if (existingReply.isNotEmpty && !_showReplyBox) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.orangeMid)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.store_rounded, size: 14, color: AppColors.orange),
              const SizedBox(width: 6),
              Expanded(child: Text(existingReply, style: const TextStyle(fontSize: 12, color: AppColors.text))),
            ]),
          ),
        ],
        if (_showReplyBox) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _replyCtrl, maxLines: 2, autofocus: true,
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            decoration: InputDecoration(
              hintText: t('ตอบกลับรีวิว...', 'Reply to review...'), hintStyle: const TextStyle(color: AppColors.muted, fontSize: 12),
              filled: true, fillColor: const Color(0xFFF6F6F6), contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.orange, width: 1.5)),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: _saving ? null : () => setState(() => _showReplyBox = false),
              child: Text(t('ยกเลิก', 'Cancel'), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saving ? null : _saveReply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange, foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(t('ส่ง', 'Send'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
        if (!_showReplyBox) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showReplyBox = true),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.reply_rounded, size: 14, color: AppColors.orange),
              const SizedBox(width: 4),
              Text(
                existingReply.isNotEmpty ? t('แก้ไขการตอบ', 'Edit Reply') : t('ตอบกลับ', 'Reply'),
                style: const TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}
