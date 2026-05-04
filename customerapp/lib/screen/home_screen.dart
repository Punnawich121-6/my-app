import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import 'store_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../services/customer_service.dart';

class HomeScreen extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerPhone;
  const HomeScreen({super.key, required this.customerId, required this.customerName, required this.customerPhone});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _goToOrders() => setState(() => _index = 1);

  late final List<Widget> _screens = [
    _StoreListTab(
      customerId: widget.customerId,
      customerName: widget.customerName,
      customerPhone: widget.customerPhone,
      onGoToOrders: _goToOrders,
    ),
    OrdersScreen(customerId: widget.customerId),
    ProfileScreen(customerId: widget.customerId, customerName: widget.customerName, customerPhone: widget.customerPhone),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: CColors.orange,
          unselectedItemColor: CColors.muted,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'หน้าหลัก'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'ออเดอร์'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'โปรไฟล์'),
          ],
        ),
      ),
    );
  }
}

// ─── Store List Tab ───────────────────────────────────────────────────────────

class _StoreListTab extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerPhone;
  final VoidCallback onGoToOrders;
  const _StoreListTab({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.onGoToOrders,
  });
  @override
  State<_StoreListTab> createState() => _StoreListTabState();
}

class _StoreListTabState extends State<_StoreListTab> {
  List<Map<String, dynamic>> _stores = [];
  bool _loading = true;
  String _selectedType = 'ทั้งหมด';

  static const _emojiMap = <String, String>{
    'ทั้งหมด': '🔥',
    'เบอร์เกอร์': '🍔', 'Burger': '🍔',
    'พิซซ่า': '🍕', 'Pizza': '🍕',
    'ซูชิ': '🍣', 'Sushi': '🍣',
    'ราเมน': '🍜', 'Ramen': '🍜', 'ก๋วยเตี๋ยว': '🍜', 'Noodle': '🍜',
    'ของหวาน': '🍰', 'Dessert': '🍰',
    'เบเกอรี่': '🥐', 'Bakery': '🥐',
    'กาแฟ': '☕', 'Coffee': '☕',
    'ไก่': '🍗', 'Chicken': '🍗',
    'อาหารทะเล': '🦐', 'Seafood': '🦐',
    'อาหารไทย': '🍛', 'Thai': '🍛',
    'สเต็ก': '🥩', 'Steak': '🥩',
    'ชานม': '🧋', 'Bubble Tea': '🧋',
    'ข้าว': '🍚', 'Rice': '🍚',
    'สลัด': '🥗', 'Salad': '🥗',
    'อาหารอีสาน': '🌶️', 'ส้มตำ': '🌶️',
    'โดนัท': '🍩', 'Donut': '🍩',
  };

  String _emoji(String type) => _emojiMap[type] ?? '🍽️';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stores = await CustomerService.getStores();
    if (!mounted) return;
    setState(() { _stores = stores; _loading = false; });
  }

  List<String> get _types {
    final types = _stores.map((s) => s['type']?.toString() ?? '').where((t) => t.isNotEmpty).toSet().toList();
    return ['ทั้งหมด', ...types];
  }

  List<Map<String, dynamic>> get _filtered =>
      _selectedType == 'ทั้งหมด' ? _stores : _stores.where((s) => s['type'] == _selectedType).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: CColors.orange,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar()),
              SliverToBoxAdapter(child: _buildGreeting()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildCategories()),
              SliverToBoxAdapter(child: _buildRestaurantsHeader()),
              if (_loading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: CColors.orange)))
              else if (_filtered.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('ไม่พบร้านอาหาร', style: TextStyle(color: CColors.muted))),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _RestaurantCard(
                      store: _filtered[i],
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => StoreScreen(
                          store: _filtered[i],
                          customerId: widget.customerId,
                          customerName: widget.customerName,
                          customerPhone: widget.customerPhone,
                        ),
                      )).then((_) => _load()),
                    ),
                    childCount: _filtered.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.menu_rounded, color: CColors.text, size: 22),
        ),
        const Spacer(),
        Column(children: [
          const Text('DELIVER TO', style: TextStyle(fontSize: 10, color: CColors.orange, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('My Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CColors.text)),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: CColors.text),
          ]),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: widget.onGoToOrders,
          child: Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: Color(0xFF1A1A1A), shape: BoxShape.circle),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
    final name = widget.customerName.split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 20, color: CColors.text, fontFamily: 'Roboto'),
          children: [
            TextSpan(text: 'Hey $name, '),
            TextSpan(text: '$greeting!', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => SearchScreen(
          stores: _stores,
          customerId: widget.customerId,
          customerName: widget.customerName,
          customerPhone: widget.customerPhone,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(children: [
          Icon(Icons.search_rounded, color: CColors.muted, size: 20),
          SizedBox(width: 10),
          Text('Search dishes, restaurants', style: TextStyle(color: CColors.muted, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(children: [
            const Text('All Categories', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: CColors.text)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _selectedType = 'ทั้งหมด'),
              child: const Row(children: [
                Text('See All', style: TextStyle(fontSize: 13, color: CColors.orange, fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right_rounded, size: 18, color: CColors.orange),
              ]),
            ),
          ]),
        ),
        SizedBox(
          height: 82,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _types.length,
            itemBuilder: (_, i) {
              final type = _types[i];
              final selected = type == _selectedType;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? CColors.orange : Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_emoji(type), style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white : CColors.text,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRestaurantsHeader() {
    final openCount = _filtered.where((s) => s['is_open'] == 1).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(children: [
        const Text('Open Restaurants', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: CColors.text)),
        const Spacer(),
        Text('$openCount ร้าน', style: const TextStyle(fontSize: 13, color: CColors.muted)),
        const Icon(Icons.chevron_right_rounded, size: 18, color: CColors.muted),
      ]),
    );
  }
}

// ─── Restaurant Card (list style) ─────────────────────────────────────────────

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> store;
  final VoidCallback onTap;
  const _RestaurantCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOpen = store['is_open'] == 1;
    final rating = double.tryParse(store['rating']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: isOpen ? onTap : null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(fit: StackFit.expand, children: [
                  store['image_url'] != null
                      ? Image.network(
                          store['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: CColors.orangeLight,
                            child: const Center(child: Icon(Icons.restaurant_rounded, color: CColors.orange, size: 48)),
                          ),
                        )
                      : Container(
                          color: CColors.orangeLight,
                          child: const Center(child: Icon(Icons.restaurant_rounded, color: CColors.orange, size: 48)),
                        ),
                  if (!isOpen)
                    Container(
                      color: Colors.black54,
                      child: const Center(child: Text('ปิดอยู่', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
                    ),
                ]),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CColors.text)),
                  const SizedBox(height: 4),
                  Text(store['type'] ?? '', style: const TextStyle(fontSize: 13, color: CColors.muted)),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 15, color: CColors.orange),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.text)),
                    const SizedBox(width: 16),
                    const Icon(Icons.delivery_dining_rounded, size: 15, color: CColors.orange),
                    const SizedBox(width: 4),
                    const Text('Free', style: TextStyle(fontSize: 13, color: CColors.text)),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time_rounded, size: 15, color: CColors.orange),
                    const SizedBox(width: 4),
                    const Text('20 min', style: TextStyle(fontSize: 13, color: CColors.text)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
