import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../merchant/merchant_main_screen.dart';
import 'pending_approval_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String phone;

  const RegisterScreen({super.key, required this.phone});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _contactFormKey = GlobalKey<FormState>();
  final _businessFormKey = GlobalKey<FormState>();
  final _bankFormKey = GlobalKey<FormState>();
  final _documentFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _lineIdController = TextEditingController();

  final _storeNameController = TextEditingController();
  final _storeTypeController = TextEditingController();
  final _addressController = TextEditingController();
  final _openTimeController = TextEditingController();
  final _closeTimeController = TextEditingController();
  double? _storeLat;
  double? _storeLng;

  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNoController = TextEditingController();

  final _idCardController = TextEditingController();
  final _businessLicenseController = TextEditingController();

  int _currentStep = 0;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _storeImageBase64;
  String? _storeImageExt;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _lineIdController.dispose();
    _storeNameController.dispose();
    _storeTypeController.dispose();
    _addressController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNoController.dispose();
    _idCardController.dispose();
    _businessLicenseController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _contactFormKey.currentState?.validate() ?? false;
    }
    if (_currentStep == 1) {
      final isValid = _businessFormKey.currentState?.validate() ?? false;
      if (!isValid) return false;
      if (_storeLat == null || _storeLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาปักหมุดตำแหน่งร้านก่อนดำเนินการต่อ'),
          ),
        );
        return false;
      }
      return true;
    }
    if (_currentStep == 2) {
      return _bankFormKey.currentState?.validate() ?? false;
    }

    final isValid = _documentFormKey.currentState?.validate() ?? false;
    if (!isValid) return false;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณายอมรับข้อกำหนดการใช้งาน')),
      );
      return false;
    }
    return true;
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep == 3) {
      _submit();
      return;
    }

    setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _currentStep--);
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final storeId = await ApiService.registerStore({
        'phone': widget.phone,
        'name': _storeNameController.text.trim(),
        'category': _storeTypeController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'owner_name': _nameController.text.trim(),
        'line_id': _lineIdController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'account_name': _accountNameController.text.trim(),
        'account_no': _accountNoController.text.trim(),
        'id_card': _idCardController.text.trim(),
        'business_license': _businessLicenseController.text.trim(),
        'open_time': _openTimeController.text.trim(),
        'close_time': _closeTimeController.text.trim(),
        if (_storeLat != null) 'lat': _storeLat,
        if (_storeLng != null) 'lng': _storeLng,
      });
      if (storeId.isEmpty) throw Exception('ไม่ได้รับ store ID จากเซิร์ฟเวอร์');
      ApiService.storeId = storeId;
      if (_storeImageBase64 != null) {
        final dataUri = 'data:image/$_storeImageExt;base64,$_storeImageBase64';
        await ApiService.uploadStoreImage(dataUri);
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PendingApprovalScreen(phone: widget.phone),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สมัครไม่สำเร็จ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickStoreLocation() async {
    final selected = await Navigator.push<(double, double)>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialLat: _storeLat,
          initialLng: _storeLng,
        ),
      ),
    );

    if (selected == null) return;
    setState(() {
      _storeLat = selected.$1;
      _storeLng = selected.$2;
    });
    _fetchAddressFromCoords(selected.$1, selected.$2);
  }

  Future<void> _pickStoreImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    setState(() {
      _storeImageBase64 = base64Encode(bytes);
      _storeImageExt = ext;
    });
  }

  Future<void> _fetchAddressFromCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=th',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'DigioMerchantApp/1.0'},
      );
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final displayName = data['display_name'] as String? ?? '';
      final address = displayName.replaceAll(RegExp(r',\s*ประเทศไทย$'), '').replaceAll(RegExp(r',\s*Thailand$'), '').trim();
      if (address.isNotEmpty && mounted) {
        setState(() => _addressController.text = address);
      }
    } catch (_) {
      // silently fail — user can fill in manually
    }
  }

  Future<void> _pickBusinessTime({
    required TextEditingController controller,
    required FormFieldState<String> fieldState,
  }) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.orange),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;
    if (!mounted) return;
    final formattedTime = pickedTime.format(context);
    setState(() {
      controller.text = formattedTime;
    });
    fieldState.didChange(formattedTime);
  }

  Widget _buildStepHeader() {
    const titles = ['ผู้ติดต่อ', 'ข้อมูลร้าน', 'บัญชีรับเงิน', 'เอกสาร'];

    return Row(
      children: List.generate(titles.length, (index) {
        final isActive = index == _currentStep;
        final isDone = index < _currentStep;

        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: isDone || isActive
                    ? AppColors.orange
                    : AppColors.orangeMid,
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titles[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.text : AppColors.muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (index != titles.length - 1)
                Container(width: 8, height: 1.5, color: AppColors.orangeMid),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) {
      return Form(
        key: _contactFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('ชื่อ-นามสกุล *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'สมชาย ใจดี',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'กรุณากรอกชื่อ-นามสกุล'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildLabel('เบอร์โทรศัพท์'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.orangeLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.orangeMid),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+66 ${widget.phone}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('อีเมล *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _emailController,
              hint: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'กรุณากรอกอีเมลให้ถูกต้อง'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildLabel('Line ID (ไม่บังคับ)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _lineIdController,
              hint: 'line id สำหรับติดต่อเพิ่มเติม',
            ),
          ],
        ),
      );
    }

    if (_currentStep == 1) {
      return Form(
        key: _businessFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('รูปร้าน (ไม่บังคับ)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickStoreImage,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.orangeMid),
                ),
                clipBehavior: Clip.antiAlias,
                child: _storeImageBase64 != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(base64Decode(_storeImageBase64!), fit: BoxFit.cover),
                          Positioned(
                            bottom: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('เปลี่ยนรูป', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_photo_alternate_outlined, color: AppColors.orange, size: 36),
                          SizedBox(height: 8),
                          Text('แตะเพื่อเพิ่มรูปร้าน', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('ปักหมุดตำแหน่งร้าน *'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickStoreLocation,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (_storeLat != null && _storeLng != null)
                        ? AppColors.orange
                        : AppColors.orangeMid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: (_storeLat != null && _storeLng != null)
                          ? AppColors.orange
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (_storeLat != null && _storeLng != null)
                            ? 'Lat ${_storeLat!.toStringAsFixed(6)}, Lng ${_storeLng!.toStringAsFixed(6)}'
                            : 'แตะเพื่อปักหมุดตำแหน่งร้าน',
                        style: TextStyle(
                          fontSize: 14,
                          color: (_storeLat != null && _storeLng != null)
                              ? AppColors.text
                              : AppColors.muted,
                          fontWeight: (_storeLat != null && _storeLng != null)
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (_storeLat != null && _storeLng != null)
                          ? 'แก้ไข'
                          : 'ปักหมุด',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('ชื่อร้าน *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _storeNameController,
              hint: 'เช่น ร้านอร่อยริมทาง',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อร้าน' : null,
            ),
            const SizedBox(height: 16),
            _buildLabel('ประเภทร้าน *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _storeTypeController,
              hint: 'เช่น อาหารตามสั่ง, ชาไข่มุก',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'กรุณากรอกประเภทร้าน'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildLabel('ที่อยู่ร้าน (ปักหมุดแล้วจะดึงให้อัตโนมัติ)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _addressController,
              hint: 'บ้านเลขที่ / ถนน / แขวง-เขต',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('เวลาเปิด *'),
                      const SizedBox(height: 8),
                      _buildTimePickerField(
                        controller: _openTimeController,
                        hint: 'เลือกเวลาเปิด',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'กรุณากรอกเวลาเปิด'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('เวลาปิด *'),
                      const SizedBox(height: 8),
                      _buildTimePickerField(
                        controller: _closeTimeController,
                        hint: 'เลือกเวลาปิด',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'กรุณากรอกเวลาปิด'
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_currentStep == 2) {
      return Form(
        key: _bankFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('ธนาคาร *'),
            const SizedBox(height: 8),
            _buildBankPickerField(),
            const SizedBox(height: 16),
            _buildLabel('ชื่อบัญชี *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _accountNameController,
              hint: 'ชื่อบัญชีที่รับเงิน',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อบัญชี' : null,
            ),
            const SizedBox(height: 16),
            _buildLabel('เลขบัญชี *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _accountNoController,
              hint: 'อย่างน้อย 10 หลัก',
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'กรุณากรอกเลขบัญชีอย่างน้อย 10 หลัก'
                  : null,
            ),
          ],
        ),
      );
    }

    return Form(
      key: _documentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('เลขบัตรประชาชนเจ้าของร้าน *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _idCardController,
            hint: 'x-xxxx-xxxxx-xx-x',
            keyboardType: TextInputType.number,
            validator: (v) => (v == null || v.trim().length < 13)
                ? 'กรอกเลขบัตรอย่างน้อย 13 หลัก'
                : null,
          ),
          const SizedBox(height: 16),
          _buildLabel('เลขทะเบียนพาณิชย์/เลขนิติบุคคล (ถ้ามี)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _businessLicenseController,
            hint: 'เช่น 010xxxxxxxxx',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.orangeLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'หลังส่งคำขอ แอดมินจะตรวจสอบเอกสาร เช่น บัตรประชาชน เอกสารร้านค้า และบัญชีธนาคารภายใน 1-3 วันทำการ',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildSummaryCard(),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _acceptedTerms
                        ? AppColors.orange
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _acceptedTerms
                          ? AppColors.orange
                          : AppColors.orangeMid,
                      width: 1.5,
                    ),
                  ),
                  child: _acceptedTerms
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ยอมรับข้อกำหนดการใช้งาน และนโยบายความเป็นส่วนตัว',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orangeMid),
        color: Colors.white.withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สรุปข้อมูลก่อนส่งคำขอ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ผู้ติดต่อ: ${_nameController.text.isEmpty ? '-' : _nameController.text}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          Text(
            'ร้าน: ${_storeNameController.text.isEmpty ? '-' : _storeNameController.text}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          Text(
            'ธนาคาร: ${_bankNameController.text.isEmpty ? '-' : _bankNameController.text}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          Text(
            'พิกัดร้าน: ${(_storeLat != null && _storeLng != null) ? '${_storeLat!.toStringAsFixed(6)}, ${_storeLng!.toStringAsFixed(6)}' : '-'}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.store_mall_directory_outlined,
                color: AppColors.orange,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'สมัคร FoodMerchant Partner',
              style: AppTextStyles.brand,
            ),
            const SizedBox(height: 6),
            Text(
              'ขั้นตอนที่ ${_currentStep + 1} จาก 4',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 20),
            _buildStepHeader(),
            const SizedBox(height: 28),
            _buildStepContent(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.orangeMid),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentStep == 0 ? 'ย้อนกลับ' : 'ขั้นก่อนหน้า',
                      style: const TextStyle(color: AppColors.text),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentStep == 3 ? 'ส่งคำขอสมัคร' : 'ถัดไป',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _thaibanks = [
    'กสิกรไทย',
    'กรุงไทย',
    'ไทยพาณิชย์',
    'กรุงเทพ',
    'กรุงศรีอยุธยา',
    'ทหารไทยธนชาต (TTB)',
    'ออมสิน',
    'ธ.ก.ส.',
    'ซีไอเอ็มบีไทย',
    'ยูโอบี (UOB)',
    'แลนด์แอนด์เฮ้าส์',
    'ทิสโก้',
    'เกียรตินาคินภัทร',
  ];

  Future<void> _pickBank() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.orangeMid,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'เลือกธนาคาร',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _thaibanks.length,
                  itemBuilder: (_, i) {
                    final bank = _thaibanks[i];
                    final isSelected = _bankNameController.text == bank;
                    return ListTile(
                      title: Text(
                        bank,
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected ? AppColors.orange : AppColors.text,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.orange, size: 20)
                          : null,
                      onTap: () => Navigator.pop(context, bank),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() => _bankNameController.text = picked);
  }

  Widget _buildBankPickerField() {
    final selected = _bankNameController.text;
    return FormField<String>(
      initialValue: selected.isEmpty ? null : selected,
      validator: (_) => _bankNameController.text.trim().isEmpty ? 'กรุณาเลือกธนาคาร' : null,
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                await _pickBank();
                fieldState.didChange(_bankNameController.text);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: fieldState.hasError
                        ? Colors.red
                        : selected.isNotEmpty
                            ? AppColors.orange
                            : Colors.transparent,
                    width: selected.isNotEmpty ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 18, color: AppColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selected.isEmpty ? 'เลือกธนาคาร' : selected,
                        style: TextStyle(
                          fontSize: 15,
                          color: selected.isEmpty ? AppColors.muted : AppColors.text,
                          fontWeight: selected.isEmpty ? FontWeight.w400 : FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded, color: AppColors.muted, size: 20),
                  ],
                ),
              ),
            ),
            if (fieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  fieldState.errorText!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String text) => Text(text, style: AppTextStyles.label);

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.orangeLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }

  Widget _buildTimePickerField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      builder: (fieldState) {
        final hasError = fieldState.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _pickBusinessTime(
                controller: controller,
                fieldState: fieldState,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasError ? Colors.red : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.text.isEmpty ? hint : controller.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: controller.text.isEmpty
                              ? AppColors.muted
                              : AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  fieldState.errorText!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }
}

class MapLocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapLocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  LatLng? _selectedPoint;

  static const _bangkokCenter = LatLng(13.7563, 100.5018);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPoint = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  void _confirm() {
    if (_selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาแตะบนแผนที่เพื่อเลือกตำแหน่ง')),
      );
      return;
    }
    Navigator.pop(context, (_selectedPoint!.latitude, _selectedPoint!.longitude));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ปักหมุดตำแหน่งร้าน'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _selectedPoint ?? _bangkokCenter,
              initialZoom: 15,
              onTap: (_, point) => setState(() => _selectedPoint = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.digio.merchantapp',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColors.orange,
                        size: 48,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined, size: 18, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedPoint == null
                          ? 'แตะบนแผนที่เพื่อปักหมุดตำแหน่งร้าน'
                          : 'Lat: ${_selectedPoint!.latitude.toStringAsFixed(6)},  Lng: ${_selectedPoint!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _selectedPoint != null ? _confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.orangeMid,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'ยืนยันตำแหน่ง',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
