import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../models/menu_model.dart';
import '../../services/api_service.dart';

// ─── My Food List ─────────────────────────────────────────────────────────────

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  List<MenuCategory> _categories = [];
  List<MenuItem> _items = [];
  bool _loading = true;
  String? _error;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 1, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    if (ApiService.storeId.isEmpty) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'ไม่พบข้อมูลร้าน กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่'; });
      return;
    }

    try {
      final menuData = await ApiService.getMenu();
      if (!mounted) return;
      final cats = menuData['categories'] as List<MenuCategory>;
      final items = menuData['items'] as List<MenuItem>;
      final oldTab = _tab;
      _tab = TabController(length: cats.length + 1, vsync: this);
      setState(() {
        _categories = cats;
        _items = items;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => oldTab.dispose());
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
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
      _load();
    } catch (_) {}
  }

  List<MenuItem> _itemsForTab(int index) {
    if (index == 0) return _items;
    final catId = _categories[index - 1].id;
    return _items.where((i) => i.categoryId == catId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Food List', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1A1A1A))),
        leading: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF1A1A1A)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => AddEditMenuScreen(categories: _categories)),
              );
              if (ok == true) _load();
            },
            child: const Text('+ Add', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
        bottom: _loading
            ? null
            : TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.orange,
                unselectedLabelColor: const Color(0xFF9E9E9E),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                indicatorColor: AppColors.orange,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2.5,
                tabs: [
                  const Tab(text: 'All'),
                  ..._categories.map((c) => Tab(text: c.name)),
                ],
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFBDBDBD)),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF757575))),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('ลองใหม่'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ]),
                  ),
                )
              : TabBarView(
              controller: _tab,
              children: List.generate(_tab.length, (i) => _FoodList(
                items: _itemsForTab(i),
                categories: _categories,
                onDelete: _deleteItem,
                onEdit: (item) async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => AddEditMenuScreen(categories: _categories, item: item)),
                  );
                  if (ok == true) _load();
                },
                onTap: (item) => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FoodDetailScreen(item: item, categories: _categories)),
                ).then((_) => _load()),
              )),
            ),
    );
  }
}

// ─── Food List View ───────────────────────────────────────────────────────────

class _FoodList extends StatelessWidget {
  final List<MenuItem> items;
  final List<MenuCategory> categories;
  final void Function(MenuItem) onDelete;
  final void Function(MenuItem) onEdit;
  final void Function(MenuItem) onTap;

  const _FoodList({
    required this.items,
    required this.categories,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  String? _categoryName(String? id) {
    if (id == null) return null;
    try { return categories.firstWhere((c) => c.id == id).name; } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.restaurant_menu_rounded, size: 40, color: AppColors.orange),
          ),
          const SizedBox(height: 16),
          const Text('No Items yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('แตะ + Add เพื่อเพิ่มเมนูแรก', style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            'Total ${items.length.toString().padLeft(2, '0')} items',
            style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final catName = _categoryName(item.categoryId);
              final imgUrl = item.imageUrl?.isNotEmpty == true ? item.imageUrl! : null;

              return GestureDetector(
                onTap: () => onTap(item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Food Image ──
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18), bottomLeft: Radius.circular(18),
                        ),
                        child: imgUrl != null
                            ? Image.network(
                                imgUrl, width: 110, height: 110, fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                      // ── Info ──
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + three-dot menu
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A1A)),
                                      maxLines: 2, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    iconSize: 20,
                                    icon: const Icon(Icons.more_vert, color: Color(0xFFBDBDBD)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    onSelected: (v) {
                                      if (v == 'edit') onEdit(item);
                                      if (v == 'delete') onDelete(item);
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                                      const PopupMenuItem(value: 'delete',
                                        child: Text('ลบ', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Category badge
                              if (catName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.orangeLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(catName,
                                    style: const TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w600)),
                                ),
                              const SizedBox(height: 8),
                              // Rating + Pick UP
                              Row(children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                const SizedBox(width: 3),
                                const Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                                const SizedBox(width: 3),
                                const Text('(10 Review)', style: TextStyle(fontSize: 11, color: Color(0xFFBDBDBD))),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Pick UP', style: TextStyle(fontSize: 10, color: Color(0xFF757575), fontWeight: FontWeight.w500)),
                                ),
                                const SizedBox(width: 4),
                              ]),
                              const SizedBox(height: 6),
                              // Price
                              Text(
                                '฿${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
    width: 110, height: 110,
    color: AppColors.orangeLight,
    child: const Icon(Icons.fastfood_rounded, color: AppColors.orange, size: 36),
  );
}

// ─── Food Detail Screen ───────────────────────────────────────────────────────

class FoodDetailScreen extends StatelessWidget {
  final MenuItem item;
  final List<MenuCategory> categories;

  const FoodDetailScreen({super.key, required this.item, required this.categories});

  String? get _categoryName {
    if (item.categoryId == null) return null;
    try {
      return categories.firstWhere((c) => c.id == item.categoryId).name;
    } catch (_) {
      return null;
    }
  }

  static const _ingredients = [
    {'icon': Icons.grain_rounded, 'name': 'Salt'},
    {'icon': Icons.set_meal_rounded, 'name': 'Chicken'},
    {'icon': Icons.eco_rounded, 'name': 'Onion', 'allergy': true},
    {'icon': Icons.grass_rounded, 'name': 'Garlic', 'allergy': true},
    {'icon': Icons.local_florist_rounded, 'name': 'Pappers'},
    {'icon': Icons.spa_rounded, 'name': 'Ginger'},
    {'icon': Icons.park_rounded, 'name': 'Broccoli'},
    {'icon': Icons.circle_rounded, 'name': 'Orange'},
    {'icon': Icons.circle_outlined, 'name': 'Walnut'},
  ];

  @override
  Widget build(BuildContext context) {
    final imgUrl = item.imageUrl?.isNotEmpty == true
        ? item.imageUrl!
        : 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800&h=500&fit=crop';
    final catName = _categoryName;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── AppBar ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  const Expanded(
                    child: Text('Food Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1A1A1A))),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('EDIT',
                      style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),

          // ── Hero Image ──
          SizedBox(
            height: 240,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imgUrl, fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Container(
                    color: AppColors.orangeLight,
                    child: const Icon(Icons.fastfood_rounded, color: AppColors.orange, size: 60)),
                ),
                // Bottom gradient
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 90,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xAA000000), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                // Category badge
                if (catName != null)
                  Positioned(
                    left: 16, bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(catName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A1A))),
                    ),
                  ),
                // Dots indicator
                Positioned(
                  bottom: 20, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == 0 ? 18 : 6, height: 6,
                      decoration: BoxDecoration(
                        color: i == 0 ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                ),
                // Delivery badge
                Positioned(
                  right: 16, bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Delivery',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A1A))),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                      ),
                      const SizedBox(width: 12),
                      Text('฿${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location
                  const Row(children: [
                    Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF9E9E9E)),
                    SizedBox(width: 4),
                    Text('สาขาหลัก', style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
                  ]),
                  const SizedBox(height: 10),
                  // Rating
                  const Row(children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    SizedBox(width: 4),
                    Text('4.9', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.orange)),
                    SizedBox(width: 4),
                    Text('(10 Reviews)', style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
                  ]),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF0F0F0), thickness: 1.5),
                  const SizedBox(height: 20),
                  // Ingredients
                  const Text('INGRIDENTS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9E9E9E), letterSpacing: 1)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _ingredients.map((ing) => Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: _IngredientChip(
                          icon: ing['icon'] as IconData,
                          name: ing['name'] as String,
                          isAllergy: ing['allergy'] == true,
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  const Text('Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 10),
                  Text(
                    item.description.isNotEmpty
                        ? item.description
                        : 'Lorem ipsum dolor sit amet, consetdur Maton adipiscing elit. Bibendum in vel, mattis et amet dui mauris turpis.',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF757575), height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientChip extends StatelessWidget {
  final IconData icon;
  final String name;
  final bool isAllergy;

  const _IngredientChip({required this.icon, required this.name, this.isAllergy = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            color: AppColors.orangeLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.15), width: 1.5),
          ),
          child: Icon(icon, color: AppColors.orange, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          isAllergy ? '$name\n(Alergy)' : name,
          style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ]),
    );
  }
}

// ─── Add / Edit Menu Item ─────────────────────────────────────────────────────

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
  String? _selectedCategoryId;
  bool _loading = false;
  bool _pickUp = true;
  bool _delivery = false;
  final List<String?> _images = [null, null, null];

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _desc = TextEditingController(text: widget.item?.description ?? '');
    _price = TextEditingController(text: widget.item != null ? widget.item!.price.toStringAsFixed(0) : '');
    _selectedCategoryId = widget.item?.categoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    if (widget.item?.imageUrl != null) _images[0] = widget.item!.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int slot) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final ext = pickedFile.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      setState(() => _images[slot] = 'data:image/$ext;base64,${base64Encode(bytes)}');
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
        'category_id': _selectedCategoryId,
      };
      final img = _images.firstWhere((i) => i != null && i.startsWith('data:'), orElse: () => null);
      if (img != null) body['image_base64'] = img;

      if (_isEditing) {
        await ApiService.updateMenuItem(widget.item!.id, {...body, 'is_available': widget.item!.isAvailable ? 1 : 0});
      } else {
        await ApiService.addMenuItem(body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกไม่สำเร็จ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF1A1A1A)),
          ),
        ),
        title: Text(
          _isEditing ? 'Edit Item' : 'Add New Items',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1A1A1A)),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2))
                : const Text('READY', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Item Name
            _label('ITEM NAME'),
            const SizedBox(height: 8),
            _field(_name, hint: 'Mazalichiken Halim', validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
            const SizedBox(height: 24),

            // Upload Photo
            _label('UPLOAD PHOTO/VIDEO'),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, i) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _ImageSlot(
                  imageData: _images[i],
                  onTap: () => _pickImage(i),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Price
            _label('PRICE'),
            const SizedBox(height: 8),
            Row(children: [
              SizedBox(
                width: 110,
                child: _field(
                  _price,
                  hint: '\$50',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Required';
                    if (double.tryParse(v!.trim()) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              _CheckItem(label: 'Pick up', value: _pickUp, onChanged: (v) => setState(() => _pickUp = v!)),
              const SizedBox(width: 16),
              _CheckItem(label: 'Delivery', value: _delivery, onChanged: (v) => setState(() => _delivery = v!)),
            ]),
            const SizedBox(height: 24),

            // Category
            if (widget.categories.isNotEmpty) ...[
              _label('CATEGORY'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                items: widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
              const SizedBox(height: 24),
            ],

            // Ingredients (static display)
            _label('INGREDIENTS'),
            const SizedBox(height: 12),
            _buildIngredientsSection(),
            const SizedBox(height: 24),

            // Details / Description
            _label('DETAILS'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Bibendum in vel, mattis et amet dui mauris turpis.',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEditing ? 'Save Changes' : 'Add Item', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    final categories = [
      {'name': 'Basic', 'items': ['Salt', 'Chicken', 'Onion', 'Garlic', 'Pappers', 'Ginger']},
      {'name': 'Fruit', 'items': ['Avocado', 'Apple', 'Blueberry', 'Broccoli', 'Orange', 'Walnut']},
    ];
    final icons = [Icons.grain_rounded, Icons.set_meal_rounded, Icons.eco_rounded, Icons.grass_rounded, Icons.local_florist_rounded, Icons.spa_rounded];

    return Column(
      children: categories.map((cat) {
        final items = cat['items'] as List<String>;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(cat['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              const Spacer(),
              const Text('See All', style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF9E9E9E)),
            ]),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: items.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 50, height: 50,
                      decoration: const BoxDecoration(color: AppColors.orangeLight, shape: BoxShape.circle),
                      child: Icon(icons[e.key % icons.length], color: AppColors.orange, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(e.value, style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
                  ]),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9E9E9E), letterSpacing: 0.8),
  );

  Widget _field(
    TextEditingController ctrl, {
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orange, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );
}

class _ImageSlot extends StatelessWidget {
  final String? imageData;
  final VoidCallback onTap;
  const _ImageSlot({this.imageData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (imageData != null && imageData!.startsWith('data:')) {
      final bytes = base64Decode(imageData!.split(',')[1]);
      return GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(bytes, width: 100, height: 100, fit: BoxFit.cover),
        ),
      );
    }
    if (imageData != null && imageData!.startsWith('http')) {
      return GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(imageData!, width: 100, height: 100, fit: BoxFit.cover),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0), style: BorderStyle.solid),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.cloud_upload_outlined, color: AppColors.orange.withValues(alpha: 0.6), size: 28),
          const SizedBox(height: 6),
          Text('Add', style: TextStyle(fontSize: 12, color: AppColors.orange.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _CheckItem({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.orange,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF424242))),
  ]);
}
