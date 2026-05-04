class MenuCategory {
  final int id;
  final int storeId;
  String name;
  int sortOrder;

  MenuCategory({required this.id, required this.storeId, required this.name, this.sortOrder = 0});

  factory MenuCategory.fromJson(Map<String, dynamic> j) => MenuCategory(
        id: j['id'],
        storeId: j['store_id'],
        name: j['name'],
        sortOrder: j['sort_order'] ?? 0,
      );
}

class MenuItem {
  final int id;
  final int storeId;
  int? categoryId;
  String name;
  String description;
  double price;
  String? imageUrl;
  bool isAvailable;

  MenuItem({
    required this.id,
    required this.storeId,
    this.categoryId,
    required this.name,
    this.description = '',
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'],
        storeId: j['store_id'],
        categoryId: j['category_id'],
        name: j['name'],
        description: j['description'] ?? '',
        price: double.parse(j['price'].toString()),
        imageUrl: j['image_url'],
        isAvailable: (j['is_available'] == 1 || j['is_available'] == true),
      );
}
