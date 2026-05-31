import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config.dart';
import '../../main.dart';
import '../../l10n/strings.dart';
import '../../utils/responsive.dart';
import '../store/store_screen.dart';
import '../order/orders_screen.dart';
import '../profile/profile_screen.dart';
import 'search_screen.dart';
import '../food/random_food_screen.dart';
import '../food/food_scan_match_screen.dart';
import '../../cart_manager.dart';
import '../../services/customer_service.dart';
import '../cart/cart_screen.dart';
import '../profile/favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  final String customerId;
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
    OrdersScreen(customerId: widget.customerId, customerName: widget.customerName, customerPhone: widget.customerPhone),
    ProfileScreen(customerId: widget.customerId, customerName: widget.customerName, customerPhone: widget.customerPhone),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.card,
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
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: S.home),
            BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_rounded), label: S.orders),
            BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: S.profile),
          ],
        ),
      ),
    );
  }
}

// ─── Store List Tab ───────────────────────────────────────────────────────────

class _StoreListTab extends StatefulWidget {
  final String customerId;
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

const _kAllTypes = '__all__';

class _StoreListTabState extends State<_StoreListTab> {
  List<Map<String, dynamic>> _stores = [];
  bool _loading = true;
  String _selectedType = _kAllTypes;

  void _onCartChanged() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    CartManager.instance.addListener(_onCartChanged);
    _load();
  }

  @override
  void dispose() {
    CartManager.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  static const _faIconMap = <String, IconData>{
    'ทั้งหมด': FontAwesomeIcons.fire,
    'เบอร์เกอร์': FontAwesomeIcons.burger,        'Burger': FontAwesomeIcons.burger,
    'พิซซ่า': FontAwesomeIcons.pizzaSlice,         'Pizza': FontAwesomeIcons.pizzaSlice,
    'ซูชิ': FontAwesomeIcons.fish,                 'Sushi': FontAwesomeIcons.fish,
    'ราเมน': FontAwesomeIcons.bowlFood,            'Ramen': FontAwesomeIcons.bowlFood,
    'ก๋วยเตี๋ยว': FontAwesomeIcons.bowlFood,      'Noodle': FontAwesomeIcons.bowlFood,
    'ของหวาน': FontAwesomeIcons.iceCream,          'Dessert': FontAwesomeIcons.iceCream,
    'เบเกอรี่': FontAwesomeIcons.breadSlice,      'Bakery': FontAwesomeIcons.breadSlice,
    'กาแฟ': FontAwesomeIcons.mugHot,               'Coffee': FontAwesomeIcons.mugHot,
    'ไก่': FontAwesomeIcons.drumstickBite,         'Chicken': FontAwesomeIcons.drumstickBite,
    'อาหารทะเล': FontAwesomeIcons.shrimp,          'Seafood': FontAwesomeIcons.shrimp,
    'อาหารไทย': FontAwesomeIcons.bowlFood,         'Thai': FontAwesomeIcons.bowlFood,
    'สเต็ก': FontAwesomeIcons.drumstickBite,       'Steak': FontAwesomeIcons.drumstickBite,
    'ชานม': FontAwesomeIcons.mugHot,               'Bubble Tea': FontAwesomeIcons.mugHot,
    'ข้าว': FontAwesomeIcons.bowlFood,             'Rice': FontAwesomeIcons.bowlFood,
    'สลัด': FontAwesomeIcons.leaf,                 'Salad': FontAwesomeIcons.leaf,
    'อาหารอีสาน': FontAwesomeIcons.pepperHot,     'ส้มตำ': FontAwesomeIcons.pepperHot,
    'โดนัท': FontAwesomeIcons.cookieBite,          'Donut': FontAwesomeIcons.cookieBite,
  };

  IconData _faIcon(String type) => _faIconMap[type] ?? FontAwesomeIcons.utensils;

  Future<void> _load() async {
    setState(() => _loading = true);
    final stores = await CustomerService.getStores();
    if (!mounted) return;
    setState(() { _stores = stores; _loading = false; });
  }

  List<String> get _types {
    final types = _stores.map((s) => s['type']?.toString() ?? '').where((t) => t.isNotEmpty).toSet().toList();
    return [_kAllTypes, ...types];
  }

  List<Map<String, dynamic>> get _filtered =>
      _selectedType == _kAllTypes ? _stores : _stores.where((s) => s['type'] == _selectedType).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: CColors.orange,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar(context)),
              SliverToBoxAdapter(child: _buildGreeting(context)),
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              SliverToBoxAdapter(child: _buildScanFoodBanner(context)),
              SliverToBoxAdapter(child: _buildCategories(context)),
              SliverToBoxAdapter(child: _buildRestaurantsHeader(context)),
              if (_loading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: CColors.orange)))
              else if (_filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(child: Text(S.noRestaurant, style: TextStyle(color: context.muted))),
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

  Widget _buildTopBar(BuildContext context) {
    final cartCount = CartManager.instance.count;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.wp(20), context.wp(14), context.wp(20), context.wp(8)),
      child: Row(children: [
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CartScreen(
              customerId: widget.customerId,
              customerName: widget.customerName,
              customerPhone: widget.customerPhone,
            )),
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: context.wp(40), height: context.wp(40),
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Icon(Icons.shopping_bag_rounded, color: Colors.white, size: context.wp(20)),
            ),
            if (cartCount > 0)
              Positioned(
                top: -4, right: -4,
                child: Container(
                  padding: EdgeInsets.all(context.wp(4)),
                  decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
                  child: Text(
                    cartCount > 99 ? '99+' : '$cartCount',
                    style: TextStyle(color: Colors.white, fontSize: context.sp(9), fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final name = widget.customerName.split(' ').first;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.wp(20), context.wp(6), context.wp(20), context.wp(14)),
      child: Text(
        S.greeting(name, hour),
        style: TextStyle(fontSize: context.sp(20), color: context.fg, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
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
        margin: EdgeInsets.fromLTRB(context.wp(20), 0, context.wp(20), context.wp(22)),
        padding: EdgeInsets.symmetric(horizontal: context.wp(16), vertical: context.wp(14)),
        decoration: BoxDecoration(
          color: context.subtleBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Icon(Icons.search_rounded, color: context.muted, size: context.wp(20)),
          SizedBox(width: context.wp(10)),
          Text(S.searchHint, style: TextStyle(color: context.muted, fontSize: context.sp(14))),
        ]),
      ),
    );
  }

  Widget _buildScanFoodBanner(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.wp(20), 0, context.wp(20), context.wp(22)),
      child: Row(
        children: [
          Expanded(
            child: _AIFeatureCard(
              icon: Icons.image_search_rounded,
              title: S.scanTitle,
              subtitle: S.scanSubtitle,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => FoodScanMatchScreen(
                  customerId: widget.customerId,
                  customerName: widget.customerName,
                  customerPhone: widget.customerPhone,
                ),
              )),
            ),
          ),
          SizedBox(width: context.wp(12)),
          Expanded(
            child: _AIFeatureCard(
              icon: Icons.casino_rounded,
              title: S.randomTitle,
              subtitle: S.randomSubtitle,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => RandomFoodScreen(
                  customerId: widget.customerId,
                  customerName: widget.customerName,
                  customerPhone: widget.customerPhone,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.wp(20), 0, context.wp(20), context.wp(14)),
          child: Row(children: [
            Text(S.allCategories, style: TextStyle(fontSize: context.sp(17), fontWeight: FontWeight.w800, color: context.fg)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _selectedType = _kAllTypes),
              child: Row(children: [
                Text(S.seeAll, style: TextStyle(fontSize: context.sp(13), color: CColors.orange, fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right_rounded, size: context.wp(18), color: CColors.orange),
              ]),
            ),
          ]),
        ),
        SizedBox(
          height: context.wp(88),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.wp(16)),
            itemCount: _types.length,
            itemBuilder: (_, i) {
              final type = _types[i];
              final selected = type == _selectedType;
              final label = type == _kAllTypes ? S.allCategories : type;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: Container(
                  margin: EdgeInsets.only(right: context.wp(12)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: context.wp(52),
                      height: context.wp(52),
                      decoration: BoxDecoration(
                        color: selected ? CColors.orange : context.card,
                        borderRadius: BorderRadius.circular(context.wp(14)),
                        border: selected ? null : Border.all(
                          color: const Color(0xFFEEEEEE),
                          width: 0.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selected
                                ? CColors.orange.withValues(alpha: 0.65)
                                : Colors.black.withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Center(
                        child: FaIcon(
                          _faIcon(type),
                          size: context.wp(20),
                          color: selected ? Colors.white : CColors.orange,
                        ),
                      ),
                    ),
                    SizedBox(height: context.wp(7)),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: context.sp(11),
                        color: selected ? CColors.orange : context.muted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
        SizedBox(height: context.wp(24)),
      ],
    );
  }

  Widget _buildRestaurantsHeader(BuildContext context) {
    final openCount = _filtered.where((s) => s['is_open'] == 1).length;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.wp(20), 0, context.wp(20), context.wp(14)),
      child: Row(children: [
        Text(S.openRestaurants, style: TextStyle(fontSize: context.sp(17), fontWeight: FontWeight.w800, color: context.fg)),
        const Spacer(),
        Text('$openCount ${S.stores}', style: TextStyle(fontSize: context.sp(13), color: context.muted)),
        Icon(Icons.chevron_right_rounded, size: context.wp(18), color: context.muted),
      ]),
    );
  }
}

// ─── AI Feature Card ──────────────────────────────────────────────────────────

class _AIFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AIFeatureCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    shadowColor: Colors.black.withValues(alpha: 0.4),
    elevation: 14,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE8E8E8), width: 0.8),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: CColors.orange.withValues(alpha: 0.15),
      highlightColor: CColors.orange.withValues(alpha: 0.08),
      child: Padding(
        padding: EdgeInsets.all(context.wp(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: context.wp(36), height: context.wp(36),
            decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(context.wp(10))),
            child: Icon(icon, color: CColors.orange, size: context.wp(18)),
          ),
          SizedBox(height: context.wp(10)),
          Text(title, style: TextStyle(fontSize: context.sp(13), fontWeight: FontWeight.w800, color: CColors.text)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: context.sp(12), color: CColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    ),
  );
}

// ─── Restaurant Card ──────────────────────────────────────────────────────────

class _RestaurantCard extends StatefulWidget {
  final Map<String, dynamic> store;
  final VoidCallback onTap;
  const _RestaurantCard({required this.store, required this.onTap});
  @override
  State<_RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<_RestaurantCard>
    with TickerProviderStateMixin {
  late final AnimationController _heartCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _heartScale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.88), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 35),
  ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));

  late final AnimationController _popCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void dispose() {
    _heartCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final isOpen = store['is_open'] == 1;
    final rating = double.tryParse(store['rating']?.toString() ?? '0') ?? 0;
    final storeId = store['id']?.toString() ?? '';
    final isFav = FavoritesManager.isFav(storeId);

    return GestureDetector(
      onTap: isOpen ? widget.onTap : null,
      child: Container(
        margin: EdgeInsets.fromLTRB(context.wp(20), 0, context.wp(20), context.wp(16)),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: store['image_url'] != null
                      ? Image.network(
                          store['image_url'].toString().startsWith('http')
                              ? store['image_url']
                              : '$kBackendUrl${store['image_url']}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: context.orangeLight,
                            child: const Center(child: Icon(Icons.restaurant_rounded, color: CColors.orange, size: 48)),
                          ),
                        )
                      : Container(
                          color: context.orangeLight,
                          child: const Center(child: Icon(Icons.restaurant_rounded, color: CColors.orange, size: 48)),
                        ),
                ),
                if (!isOpen)
                  Container(
                    color: Colors.black54,
                    child: Center(child: Text(S.closed, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
                  ),
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: () {
                      final wasLiked = FavoritesManager.isFav(storeId);
                      FavoritesManager.toggle(storeId);
                      _heartCtrl.forward(from: 0.0);
                      if (!wasLiked) _popCtrl.forward(from: 0.0);
                      setState(() {});
                    },
                    child: Container(
                      width: context.wp(36), height: context.wp(36),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: ScaleTransition(
                        scale: _heartScale,
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.red : Colors.white,
                          size: context.wp(20),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _popCtrl,
                  builder: (context, child) {
                    final v = _popCtrl.value;
                    if (v == 0.0) return const SizedBox.shrink();
                    final double scale;
                    final double opacity;
                    if (v < 0.35) {
                      scale = (v / 0.35) * 1.3;
                      opacity = v / 0.35;
                    } else if (v < 0.55) {
                      scale = 1.3 - ((v - 0.35) / 0.2) * 0.3;
                      opacity = 1.0;
                    } else if (v < 0.75) {
                      scale = 1.0;
                      opacity = 1.0;
                    } else {
                      scale = 1.0;
                      opacity = 1.0 - (v - 0.75) / 0.25;
                    }
                    return Center(
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: scale.clamp(0.0, 2.0),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.red,
                      size: 100,
                    ),
                  ),
                ),
                if (CartManager.instance.storeId == storeId && !CartManager.instance.isEmpty)
                  Positioned(
                    bottom: 8, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text('${CartManager.instance.count}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: EdgeInsets.all(context.wp(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store['name'] ?? '', style: TextStyle(fontSize: context.sp(16), fontWeight: FontWeight.w800, color: context.fg)),
                  SizedBox(height: context.wp(4)),
                  Text(store['type'] ?? '', style: TextStyle(fontSize: context.sp(13), color: context.muted)),
                  SizedBox(height: context.wp(10)),
                  Row(children: [
                    Icon(Icons.star_rounded, size: context.wp(15), color: CColors.orange),
                    SizedBox(width: context.wp(4)),
                    Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: context.sp(13), fontWeight: FontWeight.w600, color: context.fg)),
                    SizedBox(width: context.wp(16)),
                    Icon(Icons.delivery_dining_rounded, size: context.wp(15), color: CColors.orange),
                    SizedBox(width: context.wp(4)),
                    Text(S.freeDelivery, style: TextStyle(fontSize: context.sp(13), color: context.fg)),
                    SizedBox(width: context.wp(16)),
                    Icon(Icons.access_time_rounded, size: context.wp(15), color: CColors.orange),
                    SizedBox(width: context.wp(4)),
                    Text(S.min30, style: TextStyle(fontSize: context.sp(13), color: context.fg)),
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
