import 'package:flutter/foundation.dart';

class CartManager extends ChangeNotifier {
  CartManager._();
  static final CartManager instance = CartManager._();

  Map<String, dynamic>? store;
  final Map<int, int> _items = {};
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> promos = [];

  bool get isEmpty => _items.isEmpty;
  String? get storeId => store?['id']?.toString();
  String? get storeName => store?['name']?.toString();
  int get count => _items.values.fold(0, (a, b) => a + b);

  int get total => _items.entries.fold(0, (sum, e) {
    final item = _allItems.firstWhere((i) => i['id'] == e.key, orElse: () => {});
    if (item.isEmpty) return sum;
    return sum + (double.tryParse(item['price'].toString()) ?? 0).round() * e.value;
  });

  Map<int, int> get items => Map.from(_items);

  List<Map<String, dynamic>> get cartItems => _items.entries.map((e) {
    final item = _allItems.firstWhere((i) => i['id'] == e.key, orElse: () => {});
    if (item.isEmpty) return <String, dynamic>{};
    return <String, dynamic>{...item, 'qty': e.value};
  }).where((i) => i.isNotEmpty).toList();

  void syncMenu(Map<String, dynamic> s, List<Map<String, dynamic>> menuItems, List<Map<String, dynamic>> storePromos) {
    store = s;
    _allItems = menuItems;
    promos = storePromos;
    notifyListeners();
  }

  void setItem(int id, int qty) {
    if (qty <= 0) { _items.remove(id); } else { _items[id] = qty; }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    store = null;
    _allItems = [];
    promos = [];
    notifyListeners();
  }
}
