class MenuCategory {
  final String id;
  final String storeId;
  String name;
  int sortOrder;

  MenuCategory({required this.id, required this.storeId, required this.name, this.sortOrder = 0});

  factory MenuCategory.fromJson(Map<String, dynamic> j) => MenuCategory(
        id: j['id'].toString(),
        storeId: j['store_id'].toString(),
        name: j['name'],
        sortOrder: j['sort_order'] ?? 0,
      );
}

class MenuItem {
  final String id;
  final String storeId;
  String? categoryId;
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
        id: j['id'].toString(),
        storeId: j['store_id'].toString(),
        categoryId: j['category_id']?.toString(),
        name: j['name'],
        description: j['description'] ?? '',
        price: double.parse(j['price'].toString()),
        imageUrl: j['image_url'],
        isAvailable: (j['is_available'] == 1 || j['is_available'] == true),
      );
}
