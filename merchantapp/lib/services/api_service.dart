import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/menu_model.dart';
import '../models/store_model.dart';

class ApiService {
  static const _base = 'https://backend-gqls.onrender.com/api';
  static const serverBase = 'https://backend-gqls.onrender.com';
  static String get chatBase => '$_base/chat';

  // storeId and storeName are loaded once via init() before screens are built
  static String storeId = '';
  static String storeName = '';

  static Future<void> init() async {
    if (storeId.isNotEmpty) return;
    try {
      final res = await http.get(Uri.parse('$_base/config'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        storeId = data['store_id']?.toString() ?? '';
      }
    } catch (_) {}
  }

  static Map<String, dynamic> _checkResponse(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    late Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('Server error ${res.statusCode}: ไม่ได้รับ JSON (backend อาจยังไม่ได้ restart)');
    }
    if (res.statusCode >= 400) throw Exception(data['error'] ?? 'Request failed (${res.statusCode})');
    return data;
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'));
    return _checkResponse(res);
  }

  static Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _checkResponse(res);
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _checkResponse(res);
  }

  static Future<dynamic> _delete(String path) async {
    final res = await http.delete(
      Uri.parse('$_base$path'),
      headers: {'ngrok-skip-browser-warning': 'true'},
    );
    if (res.statusCode >= 400) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      throw Exception(data['error'] ?? 'Request failed (${res.statusCode})');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  // OTP
  static Future<void> sendOtp(String phone) async {
    try {
      await _post('/otp/send', {'phone': phone});
    } catch (_) {}
  }

  static Future<bool> verifyOtp(String phone, String code) async {
    try {
      await _post('/otp/verify', {'phone': phone, 'code': code});
      return true;
    } catch (_) {
      return false;
    }
  }

  // Dashboard
  static Future<DashboardData> getDashboard() async {
    final data = await _get('/dashboard/$storeId');
    return DashboardData.fromJson(data);
  }

  static Future<bool> toggleStoreOpen() async {
    final data = await _put('/dashboard/$storeId/toggle', {});
    return data['is_open'] == 1;
  }

  // Orders
  static Future<List<Order>> getOrders({String status = 'all'}) async {
    final res = await http.get(Uri.parse('$_base/orders/$storeId?status=$status'));
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data.map((e) => Order.fromJson(e)).toList();
  }

  static Future<Order> getOrderDetail(String orderId) async {
    final data = await _get('/orders/detail/$orderId');
    return Order.fromJson(data);
  }

  static Future<Map<String, dynamic>> getOrderDetailMap(String orderId) async {
    return await _get('/orders/detail/$orderId');
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    await _put('/orders/$orderId/status', {'status': status});
  }

  // Menu
  static Future<Map<String, dynamic>> getMenu() async {
    final data = await _get('/menu/$storeId');
    return {
      'categories': (data['categories'] as List).map((e) => MenuCategory.fromJson(e)).toList(),
      'items': (data['items'] as List).map((e) => MenuItem.fromJson(e)).toList(),
    };
  }

  static Future<MenuCategory> addCategory(String name) async {
    final data = await _post('/menu/category', {'store_id': storeId, 'name': name});
    return MenuCategory.fromJson(data);
  }

  static Future<void> deleteCategory(String id) async {
    await _delete('/menu/category/$id');
  }

  static Future<MenuItem> addMenuItem(Map<String, dynamic> body) async {
    final data = await _post('/menu/item', {...body, 'store_id': storeId});
    return MenuItem.fromJson(data);
  }

  static Future<void> updateMenuItem(String id, Map<String, dynamic> body) async {
    await _put('/menu/item/$id', body);
  }

  static Future<bool> toggleMenuItem(String id) async {
    final data = await _put('/menu/item/$id/toggle', {});
    return data['is_available'] == 1;
  }

  static Future<void> deleteMenuItem(String id) async {
    await _delete('/menu/item/$id');
  }

  static Future<Map<String, dynamic>> createTestOrder(List<Map<String, dynamic>> items) async {
    return await _post('/orders/test-order', {
      'store_id': storeId,
      'items': items,
    });
  }

  static Future<bool> submitReport({
    required String orderId,
    required String reasonType,
    String description = '',
    List<File> photos = const [],
  }) async {
    try {
      final uri = Uri.parse('$_base/disputes');
      final desc = '[ร้านค้าแจ้งปัญหา] $description';
      if (photos.isEmpty) {
        final res = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orderId': orderId,
            'customerId': storeId,
            'reasonType': reasonType,
            'description': desc,
          }),
        ).timeout(const Duration(seconds: 20));
        return res.statusCode == 201;
      }
      final req = http.MultipartRequest('POST', uri)
        ..fields['orderId']     = orderId
        ..fields['customerId']  = storeId
        ..fields['reasonType']  = reasonType
        ..fields['description'] = desc;
      for (final photo in photos) {
        req.files.add(await http.MultipartFile.fromPath('evidence', photo.path));
      }
      final streamed = await req.send().timeout(const Duration(seconds: 20));
      return streamed.statusCode == 201;
    } catch (_) { return false; }
  }

  // Earnings
  static Future<Map<String, dynamic>> getEarnings({String period = 'day'}) async {
    return await _get('/earnings/$storeId?period=$period');
  }

  // Chat
  static Future<List<Map<String, dynamic>>> getChatMessages(String orderId) async {
    try {
      final res = await http.get(Uri.parse(
        '$_base/chat/$orderId?userId=$storeId&userRole=store'));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> sendChatMessage(String orderId, String message, {String chatType = 'store', String? imageUrl}) async {
    try {
      final body = <String, dynamic>{
        'userId': storeId,
        'userRole': 'store',
        'senderName': storeName.isEmpty ? 'ร้านค้า' : storeName,
        'message': message,
        'chatType': chatType,
      };
      if (imageUrl != null) body['imageUrl'] = imageUrl;
      final res = await http.post(
        Uri.parse('$_base/chat/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<bool> clearChat(String orderId) async {
    try {
      final res = await http.delete(Uri.parse(
        '$_base/chat/$orderId?userId=$storeId&userRole=store',
      ));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<String?> uploadChatImage(String orderId, File imageFile) async {
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/chat/$orderId/upload'),
      );
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  // Support Chat (Merchant ↔ Admin)
  static Future<List<Map<String, dynamic>>> getSupportMessages() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/support/$storeId?userId=$storeId&userRole=store'),
      );
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (_) {}
    return [];
  }

  // Soft-delete: marks a deletion timestamp for this store only.
  // Admin and other parties still see all messages.
  static Future<bool> clearSupportChat() async {
    try {
      final res = await http.delete(
        Uri.parse('$_base/support/$storeId?userId=$storeId&userRole=store'),
      );
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<bool> sendSupportMessage(String message, {String? imageUrl}) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/support/$storeId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderRole': 'store',
          'senderName': storeName.isEmpty ? 'ร้านค้า' : storeName,
          'storeName': storeName.isEmpty ? 'ร้านค้า' : storeName,
          'message': message,
          // ignore: use_null_aware_elements
          if (imageUrl != null) 'imageUrl': imageUrl,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> uploadSupportImage(File imageFile) async {
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/support/$storeId/upload'),
      );
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  // Auth helpers
  static Future<Map<String, dynamic>?> getStoreByPhone(String phone) async {
    try {
      final res = await http.get(Uri.parse('$_base/store/by-phone/$phone'));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data == null || data is! Map) return null;
      return Map<String, dynamic>.from(data);
    } catch (_) { return null; }
  }

  // Returns { email, name, store } — store is null when no restaurant uses this Google email
  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    return _post('/store/google-login', {'idToken': idToken});
  }

  static Future<String> registerStore(Map<String, dynamic> body) async {
    final data = await _post('/store/register', body);
    return data['store_id']?.toString() ?? '';
  }

  // Store
  static Future<Store> getStore() async {
    final data = await _get('/store/$storeId');
    return Store.fromJson(data);
  }

  static Future<void> updateStore(Map<String, dynamic> body) async {
    await _put('/store/$storeId', body);
  }

  static Future<Map<String, dynamic>> getReviews() async {
    return await _get('/store/$storeId/reviews');
  }

  static Future<String?> uploadStoreImage(String base64Image) async {
    try {
      final data = await _post('/store/$storeId/image', {'image': base64Image});
      return data['image_url'] as String?;
    } catch (_) { return null; }
  }

  static Future<void> replyToReview(String reviewId, String reply) async {
    await _post('/store/$storeId/reviews/$reviewId/reply', {'reply': reply});
  }

  // SmartPromo
  static Future<Map<String, dynamic>> getPromotions() async {
    return await _get('/promotions/$storeId');
  }

  static Future<Map<String, dynamic>> analyzePromotion() async {
    return await _post('/promotions/$storeId/analyze', {});
  }

  static Future<void> approvePromotion(int id) async {
    await _put('/promotions/$id/approve', {});
  }

  static Future<void> rejectPromotion(int id) async {
    await _put('/promotions/$id/reject', {});
  }

  static Future<void> deletePromotion(int id) async {
    await _delete('/promotions/$id');
  }

  static Future<void> finalizePromotions() async {
    try { await _post('/promotions/$storeId/finalize', {}); } catch (_) {}
  }

  static Future<Map<String, dynamic>?> autoCropImage(String base64Image) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/ai/auto-crop'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 20));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> smartPrice(String itemName) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/ai/smart-price'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'itemName': itemName}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> generateDescription({
    String? itemName,
    String? storeName,
    String context = 'menu',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/ai/generate-description'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'itemName': itemName, 'storeName': storeName, 'context': context}),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }
}
