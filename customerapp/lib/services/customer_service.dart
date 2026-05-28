import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';

final _base = '$kBackendUrl/api/customer';
final _aiBase = '$kBackendUrl/api/ai';

class CustomerService {
  static Future<Map<String, dynamic>?> getByPhone(String phone) async {
    try {
      final res = await apiGet('$_base/by-phone/$phone');
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data is! Map || data['id'] == null) return null;
      return Map<String, dynamic>.from(data);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> register({required String phone, required String name}) async {
    try {
      final res = await apiPost('$_base/register', jsonEncode({'phone': phone, 'name': name}));
      final data = jsonDecode(res.body);
      if (data is! Map || data['user_id'] == null) return null;
      return Map<String, dynamic>.from(data);
    } catch (_) { return null; }
  }

  static Future<List<Map<String, dynamic>>> getStores() async {
    try {
      final res = await apiGet('$_base/stores');
      final data = jsonDecode(res.body) as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { return []; }
  }

  static Future<List<Map<String, dynamic>>> getActivePromos(dynamic storeId) async {
    try {
      final res = await apiGet('$_base/stores/$storeId/active-promos');
      final data = jsonDecode(res.body) as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { return []; }
  }

  static Future<Map<String, dynamic>?> getMenu(dynamic storeId) async {
    try {
      final res = await apiGet('$kBackendUrl/api/menu/$storeId');
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> placeOrder({
    required String? customerId,
    required String customerName,
    required String customerPhone,
    required dynamic storeId,
    required List<Map<String, dynamic>> items,
    required String address,
    double? latitude,
    double? longitude,
    String note = '',
    dynamic promoId,
  }) async {
    try {
      final body = {
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'store_id': storeId,
        'items': items,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'note': note,
      };
      if (promoId != null) body['promo_id'] = promoId;
      final res = await apiPost('$_base/orders', jsonEncode(body));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<List<Map<String, dynamic>>> getOrders(String customerId) async {
    try {
      final res = await apiGet('$_base/orders/$customerId');
      if (res.statusCode != 200) {
        // ignore: avoid_print
        print('[getOrders] error ${res.statusCode}: ${res.body}');
        return [];
      }
      final body = jsonDecode(res.body);
      if (body is! List) {
        // ignore: avoid_print
        print('[getOrders] unexpected response: ${res.body}');
        return [];
      }
      return body.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[getOrders] exception: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getOrderDetail(String orderId) async {
    try {
      final res = await apiGet('$_base/orders/detail/$orderId');
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> matchFood(String base64Image) async {
    try {
      final res = await apiPost('$_aiBase/match-food', jsonEncode({'image': base64Image}))
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> matchFoodByText(String name) async {
    try {
      final res = await apiPost('$_aiBase/match-food-text', jsonEncode({'name': name}))
          .timeout(const Duration(seconds: 20));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> suggestFood({
    String? preference,
    String? excludeStoreId,
    String? excludeItemId,
    String? sameStoreId,
  }) async {
    try {
      final res = await apiPost('$_aiBase/suggest-food', jsonEncode({
        'preference': preference,
        'excludeStoreId': excludeStoreId,
        'excludeItemId': excludeItemId,
        'sameStoreId': sameStoreId,
      })).timeout(const Duration(seconds: 20));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> getNutritionInfo(String foodName, {String? storeName}) async {
    try {
      final res = await apiPost('$_aiBase/nutrition-by-name', jsonEncode({'foodName': foodName, 'storeName': storeName}))
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> scanFood(String base64Image) async {
    try {
      final res = await apiPost('$_aiBase/scan-food', jsonEncode({'image': base64Image}))
          .timeout(const Duration(seconds: 40));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<List<Map<String, dynamic>>> getMyReviews(String customerId) async {
    try {
      final res = await apiGet('$_base/reviews/$customerId');
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { return []; }
  }

  static Future<bool> submitStoreReview({
    required String orderId,
    required String customerId,
    required String customerName,
    required String storeId,
    required int rating,
    String comment = '',
    List<File> images = const [],
  }) async {
    try {
      if (images.isEmpty) {
        final res = await apiPost('$_base/review/store', jsonEncode({
          'order_id': orderId,
          'customer_id': customerId,
          'customer_name': customerName,
          'store_id': storeId,
          'rating': rating,
          'comment': comment,
        }));
        return res.statusCode == 200;
      }
      final uri = Uri.parse('$_base/review/store');
      final request = http.MultipartRequest('POST', uri)
        ..fields['order_id'] = orderId
        ..fields['customer_id'] = customerId
        ..fields['customer_name'] = customerName
        ..fields['store_id'] = storeId
        ..fields['rating'] = rating.toString()
        ..fields['comment'] = comment;
      for (final img in images) {
        request.files.add(await http.MultipartFile.fromPath('images', img.path));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      return streamed.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<bool> submitRiderReview({
    required String orderId,
    required String customerId,
    required String customerName,
    required String riderId,
    required int rating,
    String comment = '',
  }) async {
    try {
      final res = await apiPost('$_base/review/rider', jsonEncode({
        'order_id': orderId,
        'customer_id': customerId,
        'customer_name': customerName,
        'rider_id': riderId,
        'rating': rating,
        'comment': comment,
      }));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<Map<String, dynamic>?> createQrPayment({
    required String orderId,
    required int amount,
    String? description,
  }) async {
    try {
      final res = await apiPost('$kBackendUrl/api/payment/qr', jsonEncode({
        'order_id': orderId,
        'amount': amount,
        'description': description ?? 'Food Order',
      })).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> createCardPayment({
    required String orderId,
    required int amount,
    String? description,
  }) async {
    try {
      final res = await apiPost('$kBackendUrl/api/payment/card', jsonEncode({
        'order_id': orderId,
        'amount': amount,
        'description': description ?? 'Food Order',
      })).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<bool> updateProfile(String customerId, String name) async {
    try {
      final res = await apiPut('$_base/profile/$customerId', jsonEncode({'name': name}));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<bool> submitDispute({
    required String orderId,
    required String customerId,
    required String reasonType,
    String description = '',
    List<File> photos = const [],
  }) async {
    try {
      final uri = Uri.parse('$kBackendUrl/api/disputes');
      if (photos.isEmpty) {
        final res = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orderId': orderId,
            'customerId': customerId,
            'reasonType': reasonType,
            'description': description,
          }),
        ).timeout(const Duration(seconds: 20));
        return res.statusCode == 201;
      }
      final request = http.MultipartRequest('POST', uri)
        ..fields['orderId']     = orderId
        ..fields['customerId']  = customerId
        ..fields['reasonType']  = reasonType
        ..fields['description'] = description;
      for (final photo in photos) {
        request.files.add(await http.MultipartFile.fromPath('evidence', photo.path));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 20));
      return streamed.statusCode == 201;
    } catch (_) { return false; }
  }

  static Future<bool> cancelOrder(String orderId) async {
    try {
      final res = await apiPut(
        '$kBackendUrl/api/orders/$orderId/status',
        jsonEncode({'status': 'cancelled'}),
      );
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<double> getWalletBalance(String customerId) async {
    try {
      final res = await apiGet('$_base/wallet/$customerId');
      if (res.statusCode != 200) return 0;
      final data = jsonDecode(res.body);
      return (data['balance'] as num?)?.toDouble() ?? 0;
    } catch (_) { return 0; }
  }

  static Future<List<Map<String, dynamic>>> getWalletTransactions(String customerId) async {
    try {
      final res = await apiGet('$_base/wallet/$customerId/transactions');
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { return []; }
  }

  static Future<Map<String, dynamic>?> topupWallet({
    required String customerId,
    required double amount,
  }) async {
    try {
      final res = await apiPost('$_base/wallet/topup', jsonEncode({
        'customer_id': customerId,
        'amount': amount,
      }));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> payWithWallet({
    required String customerId,
    required double amount,
    String? orderId,
    String? description,
  }) async {
    try {
      final res = await apiPost('$_base/wallet/pay', jsonEncode({
        'customer_id': customerId,
        'amount': amount,
        'order_id': orderId,
        'description': description,
      }));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }
}
