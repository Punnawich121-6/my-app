import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../models/menu_model.dart';
import '../../models/store_model.dart';
import '../../services/api_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Store? _store;
  List<MenuCategory> _categories = [];
  List<MenuItem> _items = [];
  bool _loading = true;
  int _selectedCategoryId = 0; // 0 = All

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final menuData = await ApiService.getMenu();
      final store = await ApiService.getStore();
      if (!mounted) return;
      setState(() {
        _categories = menuData['categories'];
        _items = menuData['items'];
        _store = store;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategoryId == 0) return _items;
    return _items.where((i) => i.categoryId == _selectedCategoryId).toList();
  }

  Future<void> _addCategory() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('เพิ่มหมวดหมู่', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'ชื่อหมวดหมู่',
            filled: true,
            fillColor: AppColors.orangeLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, elevation: 0),
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      final cat = await ApiService.addCategory(name);
      setState(() => _categories.add(cat));
    } catch (_) {}
  }

  Future<void> _toggleItem(MenuItem item) async {
    try {
      final isAvail = await ApiService.toggleMenuItem(item.id);
      setState(() => item.isAvailable = isAvail);
    } catch (_) {}
  }

  Future<void> _deleteItem(MenuItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('ลบเมนู', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('ต้องการลบ "${item.name}" ใช่ไหม?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteMenuItem(item.id);
      setState(() => _items.remove(item));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1583394838336-acd977736f90?w=200&h=200&fit=crop'),
            ),
            const SizedBox(width: 12),
            Text(_store?.name ?? 'Store', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.orange)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: AppColors.orange), onPressed: () {}),
          const SizedBox(width: 10),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                  const Text('Menu Management', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A), letterSpacing: -1)),
                  const SizedBox(height: 4),
                  const Text('Manage your dishes, pricing, and availability.', style: TextStyle(fontSize: 14, color: Color(0xFF757575))),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final added = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => AddEditMenuScreen(categories: _categories)),
                        );
                        if (added == true) _load();
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add New Item', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildCategoryFilter(),
                  const SizedBox(height: 20),
                  if (_items.isEmpty && _categories.isEmpty)
                    _buildEmpty()
                  else
                    ..._filteredItems.map((item) => _MenuCard(
                          item: item,
                          onToggle: () => _toggleItem(item),
                          onDelete: () => _deleteItem(item),
                          onEdit: () async {
                            final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => AddEditMenuScreen(categories: _categories, item: item)),
                            );
                            if (ok == true) _load();
                          },
                        )),
                  const SizedBox(height: 80),
                ],
              ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildCategoryChip(0, 'All Items'),
          ..._categories.map((c) => _buildCategoryChip(c.id, c.name)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(int id, String label) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.orange : const Color(0xFFE0E0E0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF424242),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.restaurant_menu, size: 36, color: AppColors.orange),
            ),
            const SizedBox(height: 14),
            const Text('No Menu Items Yet', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class _MenuCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onToggle, onDelete, onEdit;

  const _MenuCard({required this.item, required this.onToggle, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final imgUrl = item.imageUrl?.isNotEmpty == true
        ? item.imageUrl!
        : 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&h=400&fit=crop';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: ColorFiltered(
              colorFilter: item.isAvailable ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply) : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: Image.network(
                imgUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description.isEmpty ? 'Delicious and freshly made, served hot.' : item.description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF757575), height: 1.4),
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFEEEEEE), height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      item.isAvailable ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: item.isAvailable ? const Color(0xFF424242) : const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: item.isAvailable,
                      onChanged: (_) => onToggle(),
                      activeThumbColor: AppColors.orange,
                      activeTrackColor: AppColors.orangeLight,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFE0E0E0),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF757575), size: 20),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Keep AddEditMenuScreen here below the main screen classes
class AddEditMenuScreen extends StatefulWidget {
  final List<MenuCategory> categories;
  final MenuItem? item;
  const AddEditMenuScreen({super.key, required this.categories, this.item});
  @override
  State<AddEditMenuScreen> createState() => _AddEditMenuScreenState();
}

class _AddEditMenuScreenState extends State<AddEditMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _desc, _price;
  int? _selectedCategory;
  bool _loading = false;
  String? _imageBase64;
  String? _existingImageUrl;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _desc = TextEditingController(text: widget.item?.description ?? '');
    _price = TextEditingController(text: widget.item != null ? widget.item!.price.toStringAsFixed(0) : '');
    _selectedCategory = widget.item?.categoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _existingImageUrl = widget.item?.imageUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final ext = pickedFile.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      setState(() {
        _imageBase64 = 'data:image/$ext;base64,$base64Image';
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final body = {
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'price': double.parse(_price.text.trim()),
        'category_id': _selectedCategory,
      };
      if (_imageBase64 != null) {
        body['image_base64'] = _imageBase64!;
      }
      if (_isEditing) {
        await ApiService.updateMenuItem(widget.item!.id, {...body, 'is_available': widget.item!.isAvailable ? 1 : 0});
      } else {
        await ApiService.addMenuItem(body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          title: Text(
            _isEditing ? 'Edit Menu Item' : 'Add New Item',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF1A1A1A)),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
                        image: _imageBase64 != null
                            ? DecorationImage(image: MemoryImage(base64Decode(_imageBase64!.split(',')[1])), fit: BoxFit.cover)
                            : (_existingImageUrl != null ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover) : null),
                      ),
                      child: (_imageBase64 == null && _existingImageUrl == null)
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: AppColors.orange, size: 36),
                                SizedBox(height: 8),
                                Text('Add Photo', style: TextStyle(color: AppColors.orange, fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _label('Item Name *'),
                const SizedBox(height: 8),
                _field(_name, hint: 'e.g. Classic Burger', validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 20),
                _label('Description'),
                const SizedBox(height: 8),
                _field(_desc, hint: 'Short description of the item', maxLines: 3),
                const SizedBox(height: 20),
                _label('Price *'),
                const SizedBox(height: 8),
                _field(_price, hint: 'e.g. 15.00', keyboardType: TextInputType.number, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) return 'Invalid amount';
                  return null;
                }),
                if (widget.categories.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _label('Category'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategory,
                    decoration: _inputDecoration('Select category'),
                    items: widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isEditing ? 'Save Changes' : 'Add Item', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _label(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF424242)));

  Widget _field(TextEditingController ctrl, {required String hint, TextInputType? keyboardType, String? Function(String?)? validator, int maxLines = 1}) => TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
        decoration: _inputDecoration(hint),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.orange, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}
