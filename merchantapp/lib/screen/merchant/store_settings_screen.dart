import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../models/store_model.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

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
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final store = await ApiService.getStore();
      if (!mounted) return;
      setState(() {
        _store = store;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          title: const Text('Store', style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tab,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [Tab(text: 'Store Info'), Tab(text: 'Reviews')],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
            : _store == null
                ? const Center(child: Text('Connection failed', style: TextStyle(color: AppColors.muted)))
                : TabBarView(controller: _tab, children: [
                    _StoreInfoTab(store: _store!, onSaved: _load),
                    _ReviewsTab(),
                  ]),
      );
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
  late final TextEditingController _name, _type, _address, _openTime, _closeTime;
  bool _saving = false;
  bool _uploadingImage = false;
  String? _previewImageUrl;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.store.name);
    _type = TextEditingController(text: widget.store.type);
    _address = TextEditingController(text: widget.store.address);
    _openTime = TextEditingController(text: widget.store.openTime);
    _closeTime = TextEditingController(text: widget.store.closeTime);
    _previewImageUrl = widget.store.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _address.dispose();
    _openTime.dispose();
    _closeTime.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (picked == null || !mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final base64Str = base64Encode(bytes);
      final ext = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      final dataUri = 'data:image/$ext;base64,$base64Str';
      final url = await ApiService.uploadStoreImage(dataUri);
      if (!mounted) return;
      if (url != null) {
        setState(() => _previewImageUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปร้านสำเร็จ'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ'), backgroundColor: Colors.red),
      );
    }
    setState(() => _uploadingImage = false);
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
        'type': _type.text.trim(),
        'address': _address.text.trim(),
        'open_time': _openTime.text.trim(),
        'close_time': _closeTime.text.trim(),
        'lat': widget.store.lat,
        'lng': widget.store.lng,
      });
      if (!mounted) return;
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully'), backgroundColor: Colors.green));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save failed'), backgroundColor: Colors.red));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildStatusBadge(),
            const SizedBox(height: 16),
            _buildImageCard(),
            const SizedBox(height: 16),
            _buildInfoCard(children: [
              _label('Store Name *'),
              const SizedBox(height: 8),
              _field(_name, hint: 'Store name', validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter store name' : null),
              const SizedBox(height: 14),
              _label('Store Type'),
              const SizedBox(height: 8),
              _field(_type, hint: 'e.g. Thai Food, Coffee'),
              const SizedBox(height: 14),
              _label('Address'),
              const SizedBox(height: 8),
              _field(_address, hint: 'Store address', maxLines: 2),
            ]),
            const SizedBox(height: 14),
            _buildInfoCard(children: [
              _label('Opening Hours'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Open', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 6),
                  _timeField(_openTime, 'Open time'),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Close', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 6),
                  _timeField(_closeTime, 'Close time'),
                ])),
              ]),
            ]),
            const SizedBox(height: 14),
            _buildInfoCard(children: [
              _label('Bank Account'),
              const SizedBox(height: 10),
              if (widget.store.bankName != null) _infoRow('Bank', widget.store.bankName!),
              if (widget.store.accountName != null) _infoRow('Account Name', widget.store.accountName!),
              if (widget.store.accountNo != null) _infoRow('Account No', widget.store.accountNo!),
            ]),
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
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      );

  Widget _buildImageCard() {
    return GestureDetector(
      onTap: _uploadingImage ? null : _pickAndUploadImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.orangeLight,
          border: Border.all(color: AppColors.orangeMid),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_previewImageUrl != null && _previewImageUrl!.isNotEmpty)
              Image.network(_previewImageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder())
            else
              _imagePlaceholder(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
                ),
              ),
            ),
            if (_uploadingImage)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('เปลี่ยนรูปร้าน', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate_outlined, color: AppColors.orange, size: 40),
          SizedBox(height: 8),
          Text('แตะเพื่ออัปโหลดรูปร้าน', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      );

  Widget _buildStatusBadge() {
    const colors = {'pending': const Color(0xFFFF6B35), 'approved': Colors.green, 'rejected': Colors.red};
    const labels = {'pending': 'Under Review', 'approved': 'Approved', 'rejected': 'Rejected'};
    final color = colors[widget.store.status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.verified_outlined, color: color, size: 18),
        const SizedBox(width: 8),
        Text('Status: ${labels[widget.store.status] ?? widget.store.status}', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        const Spacer(),
        Row(children: [
          Icon(Icons.star_rounded, color: const Color(0xFFFF6B35), size: 16),
          const SizedBox(width: 3),
          Text('${widget.store.rating} (${widget.store.reviewCount})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text)),
        ]),
      ]),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _label(String t) => Text(t, style: AppTextStyles.label);

  Widget _field(TextEditingController ctrl, {required String hint, String? Function(String?)? validator, int maxLines = 1}) => TextFormField(
        controller: ctrl,
        validator: validator,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.muted),
          filled: true,
          fillColor: AppColors.orangeLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.orange, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      );

  Widget _timeField(TextEditingController ctrl, String hint) => GestureDetector(
        onTap: () => _pickTime(ctrl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.access_time, size: 16, color: AppColors.muted),
            const SizedBox(width: 8),
            Text(ctrl.text.isEmpty ? hint : ctrl.text, style: TextStyle(fontSize: 14, color: ctrl.text.isEmpty ? AppColors.muted : AppColors.text)),
          ]),
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500)),
        ]),
      );
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
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getReviews();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    if (_data == null) return const Center(child: Text('Connection failed'));
    final reviews = (_data!['reviews'] as List?) ?? [];
    final avg = double.parse((_data!['average'] ?? 0).toString());
    final count = _data!['count'] ?? 0;
    return ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Row(children: [
            Column(children: [
              Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.orange)),
              Row(children: List.generate(5, (i) => Icon(i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFFF6B35), size: 18))),
              Text('$count reviews', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        if (reviews.isEmpty)
          const Center(child: Text('No reviews yet', style: TextStyle(color: AppColors.muted)))
        else
          ...reviews.map((r) => _ReviewCard(review: r)),
      ]);
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] as int;
    final date = DateTime.parse(review['created_at']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: AppColors.orangeLight,
            radius: 16,
            child: Text(
              (review['customer_name'] as String? ?? 'C')[0],
              style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(review['customer_name'] ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ])),
          Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFFF6B35), size: 14))),
        ]),
        if (review['comment'] != null && (review['comment'] as String).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(review['comment'], style: const TextStyle(fontSize: 13, color: AppColors.text)),
        ],
      ]),
    );
  }
}
