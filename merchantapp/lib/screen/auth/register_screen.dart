import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../merchant/merchant_main_screen.dart';

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
        'bank_name': _bankNameController.text.trim(),
        'account_name': _accountNameController.text.trim(),
        'account_no': _accountNoController.text.trim(),
      });
      if (storeId.isEmpty) throw Exception('ไม่ได้รับ store ID จากเซิร์ฟเวอร์');
      ApiService.storeId = storeId;
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MerchantMainScreen()),
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
    final selected = await showDialog<(double, double)>(
      context: context,
      builder: (dialogContext) => _LocationDialog(
        initialLat: _storeLat,
        initialLng: _storeLng,
      ),
    );

    if (selected == null) return;
    setState(() {
      _storeLat = selected.$1;
      _storeLng = selected.$2;
    });
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
            _buildLabel('ที่อยู่ร้าน *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _addressController,
              hint: 'บ้านเลขที่ / ถนน / แขวง-เขต',
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'กรุณากรอกที่อยู่ร้าน'
                  : null,
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
            _buildTextField(
              controller: _bankNameController,
              hint: 'เช่น กสิกรไทย',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'กรุณากรอกชื่อธนาคาร'
                  : null,
            ),
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

class _LocationDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const _LocationDialog({this.initialLat, this.initialLng});

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final TextEditingController _lat;
  late final TextEditingController _lng;

  @override
  void initState() {
    super.initState();
    _lat = TextEditingController(text: widget.initialLat?.toStringAsFixed(6) ?? '');
    _lng = TextEditingController(text: widget.initialLng?.toStringAsFixed(6) ?? '');
  }

  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  void _submit() {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('พิกัดไม่ถูกต้อง')),
      );
      return;
    }
    Navigator.pop(context, (lat, lng));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ปักหมุดร้าน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _lat,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: 'Latitude',
                hintText: 'เช่น 13.756331',
                filled: true,
                fillColor: AppColors.orangeLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orange, width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lng,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: 'Longitude',
                hintText: 'เช่น 100.501762',
                filled: true,
                fillColor: AppColors.orangeLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orange, width: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: AppColors.orangeMid),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF9E9E9E))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('บันทึกหมุด', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
