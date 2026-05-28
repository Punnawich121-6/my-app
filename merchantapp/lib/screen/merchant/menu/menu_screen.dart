import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../../main.dart';
import '../../../models/menu_model.dart';
import '../../../services/api_service.dart';

// ─── My Food List ─────────────────────────────────────────────────────────────

class MenuScreen extends StatefulWidget {
  final bool autoAdd;
  const MenuScreen({super.key, this.autoAdd = false});
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldTab.dispose();
        if (widget.autoAdd && mounted) {
          Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => AddEditMenuScreen(categories: cats)),
          ).then((ok) { if (ok == true && mounted) _load(); });
        }
      });
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
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_loading ? kToolbarHeight : kToolbarHeight + 50),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.orange,
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'เมนูอาหาร',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditMenuScreen(categories: _categories),
                              ),
                            );
                            if (ok == true) _load();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, size: 16, color: AppColors.orange),
                                const SizedBox(width: 4),
                                const Text(
                                  'เพิ่ม',
                                  style: TextStyle(
                                    color: AppColors.orange,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_loading)
                  Container(
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: TabBar(
                      controller: _tab,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColors.orange,
                      unselectedLabelColor: const Color(0xFF9E9E9E),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      indicatorColor: AppColors.orange,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorWeight: 3,
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tabs: [
                        const Tab(text: 'ทั้งหมด'),
                        ..._categories.map((c) => Tab(text: c.name)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
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

class _FoodList extends StatefulWidget {
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

  @override
  State<_FoodList> createState() => _FoodListState();
}

class _FoodListState extends State<_FoodList> {
  late List<MenuItem> _sorted;

  @override
  void initState() {
    super.initState();
    _sorted = List.from(widget.items);
  }

  @override
  void didUpdateWidget(_FoodList old) {
    super.didUpdateWidget(old);
    if (old.items != widget.items) {
      _sorted = List.from(widget.items);
    }
  }

  String? _categoryName(String? id) {
    if (id == null) return null;
    try { return widget.categories.firstWhere((c) => c.id == id).name; } catch (_) { return null; }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _sorted.removeAt(oldIndex);
      _sorted.insert(newIndex, item);
    });
    for (int i = 0; i < _sorted.length; i++) {
      ApiService.updateMenuItem(_sorted[i].id, {'sort_order': i + 1});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sorted.isEmpty) {
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
          child: Row(children: [
            Text(
              'Total ${_sorted.length.toString().padLeft(2, '0')} items',
              style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Row(children: [
              Icon(Icons.drag_handle_rounded, size: 14, color: Color(0xFFBDBDBD)),
              SizedBox(width: 4),
              Text('กดค้างเพื่อเรียง', style: TextStyle(fontSize: 11, color: Color(0xFFBDBDBD))),
            ]),
          ]),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _sorted.length,
            onReorder: _onReorder,
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.transparent,
              elevation: 8,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(18),
              child: child,
            ),
            itemBuilder: (_, i) {
              final item = _sorted[i];
              final catName = _categoryName(item.categoryId);
              final imgUrl = item.imageUrl?.isNotEmpty == true ? item.imageUrl! : null;

              return Container(
                key: ValueKey(item.id),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => widget.onTap(item),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18), bottomLeft: Radius.circular(18),
                        ),
                        child: imgUrl != null
                            ? Image.network(
                                imgUrl, width: 110, height: 110, fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onTap(item),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                      if (v == 'edit') widget.onEdit(item);
                                      if (v == 'delete') widget.onDelete(item);
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                                      const PopupMenuItem(value: 'delete',
                                        child: Text('ลบ', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ],
                              ),
                              if (catName != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.orangeLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(catName,
                                    style: const TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w600)),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                '฿${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                        child: Icon(Icons.drag_handle_rounded, color: Color(0xFFBDBDBD), size: 22),
                      ),
                    ),
                  ],
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
                    onPressed: () async {
                      await Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => AddEditMenuScreen(categories: categories, item: item)),
                      );
                    },
                    child: const Text('EDIT',
                      style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),

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

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const Row(children: [
                    Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF9E9E9E)),
                    SizedBox(width: 4),
                    Text('สาขาหลัก', style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
                  ]),
                  const SizedBox(height: 10),
                  const Row(children: [
                    Icon(Icons.star_rounded, color: Color(0xFFFF6B35), size: 18),
                    SizedBox(width: 4),
                    Text('4.9', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.orange)),
                    SizedBox(width: 4),
                    Text('(10 Reviews)', style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
                  ]),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE0E0E0), thickness: 1.5),
                  const SizedBox(height: 20),
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
  final Set<String> _selectedIngredients = {};
  late List<MenuCategory> _localCategories;
  int? _croppingSlot;
  Map<String, dynamic>? _smartPriceData;
  bool _loadingSmartPrice = false;
  bool _generatingDesc = false;

  static const _presetCategories = [
    'อาหารจานหลัก', 'เครื่องดื่ม', 'อาหารเรียกน้ำย่อย',
    'ของหวาน', 'กับข้าว', 'อาหารทะเล', 'อาหารเจ', 'ก๋วยเตี๋ยว',
  ];

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _localCategories = List.from(widget.categories);
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
    if (pickedFile == null) return;
    final bytes = await pickedFile.readAsBytes();
    final ext = pickedFile.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    final original = 'data:image/$ext;base64,${base64Encode(bytes)}';
    setState(() { _images[slot] = original; _croppingSlot = slot; });

    bool cropped = false;
    try {
      final cropResult = await ApiService.autoCropImage(original);
      if (cropResult != null && mounted) {
        final x = (cropResult['x'] as num).toDouble();
        final y = (cropResult['y'] as num).toDouble();
        final w = (cropResult['w'] as num).toDouble();
        final h = (cropResult['h'] as num).toDouble();
        final needsCrop = x > 0.03 || y > 0.03 || (x + w) < 0.97 || (y + h) < 0.97;
        if (needsCrop) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            final cx = (x * decoded.width).round().clamp(0, decoded.width - 1);
            final cy = (y * decoded.height).round().clamp(0, decoded.height - 1);
            final cw = (w * decoded.width).round().clamp(1, decoded.width - cx);
            final ch = (h * decoded.height).round().clamp(1, decoded.height - cy);
            final croppedImg = img.copyCrop(decoded, x: cx, y: cy, width: cw, height: ch);
            final croppedBytes = Uint8List.fromList(img.encodeJpg(croppedImg, quality: 88));
            if (mounted) setState(() => _images[slot] = 'data:image/jpeg;base64,${base64Encode(croppedBytes)}');
            cropped = true;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _croppingSlot = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(cropped ? '✨ AI ครอปรูปอัตโนมัติเรียบร้อย' : '✨ รูปนี้ไม่จำเป็นต้องครอป'),
        ]),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _loadSmartPrice() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() { _loadingSmartPrice = true; _smartPriceData = null; });
    final result = await ApiService.smartPrice(name);
    if (!mounted) return;
    setState(() { _smartPriceData = result; _loadingSmartPrice = false; });
  }

  Future<void> _generateDesc() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อเมนูก่อน')));
      return;
    }
    setState(() => _generatingDesc = true);
    final result = await ApiService.generateDescription(itemName: name, storeName: ApiService.storeName);
    if (!mounted) return;
    if (result != null && result['description'] != null) setState(() => _desc.text = result['description']);
    setState(() => _generatingDesc = false);
  }

  Future<void> _showAddCategorySheet() async {
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            const Text('เพิ่มประเภทอาหาร', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: _presetCategories.map((name) {
              final exists = _localCategories.any((c) => c.name == name);
              return GestureDetector(
                onTap: exists ? null : () => Navigator.pop(ctx, name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: exists ? const Color(0xFFF0F0F0) : AppColors.orangeLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: exists ? const Color(0xFFE0E0E0) : AppColors.orange),
                  ),
                  child: Text(name,
                    style: TextStyle(
                      fontSize: 13,
                      color: exists ? const Color(0xFFBDBDBD) : AppColors.orange,
                      fontWeight: FontWeight.w600,
                    )),
                ),
              );
            }).toList()),
            const SizedBox(height: 20),
            const Text('หรือพิมพ์ชื่อเอง', style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'เช่น อาหารตะวันตก, สลัด',
                    hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final text = ctrl.text.trim();
                  if (text.isNotEmpty) Navigator.pop(ctx, text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('เพิ่ม', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        );
      },
    );
    if (result == null || !mounted) return;
    final existing = _localCategories.firstWhere(
      (c) => c.name == result,
      orElse: () => MenuCategory(id: '', storeId: '', name: ''),
    );
    if (existing.id.isNotEmpty) {
      setState(() => _selectedCategoryId = existing.id);
      return;
    }
    try {
      final newCat = await ApiService.addCategory(result);
      setState(() {
        _localCategories.add(newCat);
        _selectedCategoryId = newCat.id;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้างประเภทไม่สำเร็จ'), backgroundColor: Colors.red),
      );
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
      final imgData = _images.firstWhere((i) => i != null && i.startsWith('data:'), orElse: () => null);
      if (imgData != null) body['image_base64'] = imgData;

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
          _isEditing ? 'แก้ไขเมนู' : 'เพิ่มเมนูใหม่',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1A1A1A)),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2))
                : const Text('บันทึก', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label('ชื่อเมนู'),
            const SizedBox(height: 8),
            _field(_name, hint: 'เช่น ผัดกะเพราหมูสับ', validator: (v) => (v?.trim().isEmpty ?? true) ? 'กรุณากรอกชื่อเมนู' : null),
            const SizedBox(height: 24),

            _label('รูปภาพ'),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, i) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _ImageSlot(
                  imageData: _images[i],
                  isCropping: _croppingSlot == i,
                  onTap: () => _pickImage(i),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _label('ราคา (บาท)'),
            const SizedBox(height: 8),
            Row(children: [
              SizedBox(
                width: 130,
                child: _field(
                  _price,
                  hint: '฿ ราคา',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'กรุณากรอกราคา';
                    if (double.tryParse(v!.trim()) == null) return 'ราคาไม่ถูกต้อง';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              _CheckItem(label: 'Pick up', value: _pickUp, onChanged: (v) => setState(() => _pickUp = v!)),
              const SizedBox(width: 16),
              _CheckItem(label: 'Delivery', value: _delivery, onChanged: (v) => setState(() => _delivery = v!)),
            ]),
            const SizedBox(height: 10),
            _buildSmartPricing(),
            const SizedBox(height: 14),

            Row(children: [
              const Expanded(child: Text('ประเภทอาหาร', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9E9E9E), letterSpacing: 0.8))),
              GestureDetector(
                onTap: _showAddCategorySheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 14, color: AppColors.orange),
                    SizedBox(width: 3),
                    Text('สร้างประเภทใหม่', style: TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            _localCategories.isEmpty
                ? GestureDetector(
                    onTap: _showAddCategorySheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.orangeLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.orangeMid, style: BorderStyle.solid),
                      ),
                      child: const Center(child: Text('+ แตะเพื่อสร้างประเภทอาหาร', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600, fontSize: 13))),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._localCategories.map((cat) {
                        final selected = _selectedCategoryId == cat.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategoryId = selected ? null : cat.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.orange : const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? AppColors.orange : const Color(0xFFE0E0E0)),
                            ),
                            child: Text(cat.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: selected ? Colors.white : const Color(0xFF424242),
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              )),
                          ),
                        );
                      }),
                    ],
                  ),
            const SizedBox(height: 24),

            _label('ส่วนผสม'),
            const SizedBox(height: 12),
            _buildIngredientsSection(),
            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _label('รายละเอียด'),
              GestureDetector(
                onTap: _generatingDesc ? null : _generateDesc,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(20)),
                  child: _generatingDesc
                      ? const Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 1.5)),
                          SizedBox(width: 6),
                          Text('Generating...', style: TextStyle(fontSize: 11, color: AppColors.orange)),
                        ])
                      : const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.auto_awesome_rounded, color: AppColors.orange, size: 13),
                          SizedBox(width: 5),
                          Text('AI Generate', style: TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w700)),
                        ]),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: 'อธิบายส่วนผสม รสชาติ หรือความพิเศษของเมนูนี้',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 40),

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
                    : Text(_isEditing ? 'บันทึกการแก้ไข' : 'เพิ่มเมนู', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    final cats = [
      {'name': 'Basic', 'items': ['Salt', 'Chicken', 'Onion', 'Garlic', 'Pappers', 'Ginger']},
      {'name': 'Fruit', 'items': ['Avocado', 'Apple', 'Blueberry', 'Broccoli', 'Orange', 'Walnut']},
    ];
    final icons = [Icons.grain_rounded, Icons.set_meal_rounded, Icons.eco_rounded, Icons.grass_rounded, Icons.local_florist_rounded, Icons.spa_rounded];

    return Column(
      children: cats.map((cat) {
        final catItems = cat['items'] as List<String>;
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
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: catItems.length,
                separatorBuilder: (_, i) => const SizedBox(width: 16),
                itemBuilder: (_, i) {
                  final name = catItems[i];
                  final selected = _selectedIngredients.contains(name);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selected ? _selectedIngredients.remove(name) : _selectedIngredients.add(name);
                    }),
                    child: SizedBox(
                      width: 58,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.orange : AppColors.orangeLight,
                                  shape: BoxShape.circle,
                                  border: selected ? Border.all(color: AppColors.orange, width: 2) : null,
                                ),
                                child: Icon(icons[i % icons.length], color: selected ? Colors.white : AppColors.orange, size: 22),
                              ),
                              if (selected)
                                Positioned(
                                  right: 0, bottom: 0,
                                  child: Container(
                                    width: 16, height: 16,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.orange),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(name,
                            style: TextStyle(fontSize: 11, color: selected ? AppColors.orange : const Color(0xFF757575), fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSmartPricing() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: _loadingSmartPrice ? null : _loadSmartPrice,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(10)),
          child: _loadingSmartPrice
              ? const Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 13, height: 13, child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('กำลังตรวจสอบราคา...', style: TextStyle(fontSize: 12, color: AppColors.orange)),
                ])
              : const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.orange, size: 13),
                  SizedBox(width: 6),
                  Text('Smart Pricing', style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w700)),
                ]),
        ),
      ),
      if (_smartPriceData != null && (_smartPriceData!['count'] ?? 0) > 0) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.orange, size: 14),
              const SizedBox(width: 6),
              Text('ราคาในตลาด (${_smartPriceData!['count']} เมนูที่คล้ายกัน)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _PriceTag('ต่ำสุด', '฿${_smartPriceData!['min']}', Colors.green),
              const SizedBox(width: 8),
              _PriceTag('เฉลี่ย', '฿${_smartPriceData!['avg']}', AppColors.orange),
              const SizedBox(width: 8),
              _PriceTag('สูงสุด', '฿${_smartPriceData!['max']}', const Color(0xFFE53935)),
            ]),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _price.text = '${_smartPriceData!['suggestion']}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(8)),
                child: Text('ใช้ราคาแนะนำ ฿${_smartPriceData!['suggestion']}',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ],
      if (_smartPriceData != null && (_smartPriceData!['count'] ?? 0) == 0)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('ไม่พบเมนูที่คล้ายกันในฐานข้อมูล', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
        ),
    ]);
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9E9E9E), letterSpacing: 0.8));

  Widget _field(TextEditingController ctrl, {required String hint, TextInputType? keyboardType, String? Function(String?)? validator}) =>
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

class _PriceTag extends StatelessWidget {
  final String label, value;
  final Color color;
  const _PriceTag(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _ImageSlot extends StatelessWidget {
  final String? imageData;
  final bool isCropping;
  final VoidCallback onTap;
  const _ImageSlot({this.imageData, this.isCropping = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (imageData != null && imageData!.startsWith('data:')) {
      final bytes = base64Decode(imageData!.split(',')[1]);
      child = ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(bytes, width: 100, height: 100, fit: BoxFit.cover));
    } else if (imageData != null && imageData!.startsWith('http')) {
      child = ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(imageData!, width: 100, height: 100, fit: BoxFit.cover));
    } else {
      child = Container(
        width: 100, height: 100,
        decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE0E0E0), style: BorderStyle.solid)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.cloud_upload_outlined, color: AppColors.orange.withValues(alpha: 0.6), size: 28),
          const SizedBox(height: 6),
          Text('Add', style: TextStyle(fontSize: 12, color: AppColors.orange.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
        ]),
      );
    }
    return GestureDetector(
      onTap: isCropping ? null : onTap,
      child: Stack(children: [
        child,
        if (isCropping)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 100, height: 100,
                color: Colors.black.withValues(alpha: 0.45),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                  SizedBox(height: 6),
                  Text('AI Crop', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
      ]),
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
    Checkbox(value: value, onChanged: onChanged, activeColor: AppColors.orange, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
    Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF424242))),
  ]);
}
