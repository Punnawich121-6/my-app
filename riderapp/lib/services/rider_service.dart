import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../config.dart';

class RiderService {
  static String get _base => '$kBackendUrl/api/rider';

  static Future<Map<String, dynamic>?> register({
    required String phone,
    required String name,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'name': name}),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getByPhone(String phone) async {
    try {
      final normalized = phone.startsWith('0') ? phone : '0$phone';
      final res = await http.get(Uri.parse('$_base/by-phone/$normalized'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getProfile(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/profile/$riderId'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> getAvailableOrders() async {
    try {
      final res = await http.get(Uri.parse('$_base/orders/available'));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> getActiveDelivery(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/orders/active/$riderId'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body != null ? Map<String, dynamic>.from(body) : null;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> acceptOrder(String orderId, String riderId) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/orders/$orderId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rider_id': riderId}),
      );
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  static Future<bool> completeDelivery(String orderId, String riderId) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/orders/$orderId/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rider_id': riderId}),
      );
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  static Future<List<Map<String, dynamic>>> getHistory(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/history/$riderId'));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> getEarnings(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/earnings/$riderId'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<String?> uploadProfilePhoto(String riderId, Uint8List bytes, String filename) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$_base/$riderId/photo'));
      req.files.add(http.MultipartFile.fromBytes('photo', bytes, filename: filename));
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = jsonDecode(await streamed.stream.bytesToString());
      if (streamed.statusCode == 200) return body['photo_url'] as String?;
    } catch (_) {}
    return null;
  }

  static Future<bool> updateProfile(String riderId, {String? name, String? description}) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base/$riderId/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (name != null) 'name': name,
          if (description != null) 'description': description,
        }),
      );
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<Map<String, dynamic>?> getAnalytics(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/analytics/$riderId'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<String?> generateRiderBio({required String riderName, String runsCompleted = '0'}) async {
    try {
      final res = await http.post(
        Uri.parse('$kBackendUrl/api/ai/generate-description'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'storeName': riderName, 'itemName': runsCompleted, 'context': 'rider'}),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      return data['description'] as String?;
    } catch (_) { return null; }
  }

  static Future<String?> getRiderPlan({
    required double todayEarned,
    required int todayCount,
    required int avgPerDelivery,
    required int targetAmount,
    required int remainingDeliveries,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$kBackendUrl/api/ai/rider-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'todayEarned': todayEarned,
          'todayCount': todayCount,
          'avgPerDelivery': avgPerDelivery,
          'targetAmount': targetAmount,
          'remainingDeliveries': remainingDeliveries,
        }),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      return data['tip'] as String?;
    } catch (_) { return null; }
  }

  static Future<String?> getRiderNotification({
    required String step,
    required String storeName,
    required String customerName,
    String? riderName,
    int? etaMinutes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$kBackendUrl/api/ai/rider-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'step': step,
          'storeName': storeName,
          'customerName': customerName,
          if (riderName != null) 'riderName': riderName,
          if (etaMinutes != null) 'etaMinutes': etaMinutes,
        }),
      ).timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body);
      return data['message'] as String?;
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> getReviews(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/$riderId/reviews'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<bool> sendAutoChat({
    required String orderId,
    required String riderId,
    required String riderName,
    required String message,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$kBackendUrl/api/chat/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': riderId,
          'userRole': 'rider',
          'senderName': riderName,
          'message': message,
          'chatType': 'rider',
        }),
      );
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<Map<String, dynamic>?> getRiderInsight({
    required double todayEarned,
    required int todayCount,
    required double weekEarned,
    required int weekCount,
    required double totalEarned,
    required int totalCount,
    required int avgPerDelivery,
    required int targetAmount,
    List<dynamic>? peakHours,
    double? avgRating,
    List<String>? recentComments,
  }) async {
    try {
      final days = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
      final dayOfWeek = days[DateTime.now().weekday - 1];
      final res = await http.post(
        Uri.parse('$kBackendUrl/api/ai/rider-insight'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'todayEarned': todayEarned,
          'todayCount': todayCount,
          'weekEarned': weekEarned,
          'weekCount': weekCount,
          'totalEarned': totalEarned,
          'totalCount': totalCount,
          'avgPerDelivery': avgPerDelivery,
          'targetAmount': targetAmount,
          'peakHours': peakHours ?? [],
          'dayOfWeek': dayOfWeek,
          if (avgRating != null) 'avgRating': avgRating,
          if (recentComments != null) 'recentComments': recentComments,
        }),
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<bool> submitRiderReport({
    required String orderId,
    required String riderId,
    required String reasonType,
    String description = '',
    List<File> photos = const [],
  }) async {
    try {
      final uri = Uri.parse('$kBackendUrl/api/disputes');
      final desc = '[ไรเดอร์แจ้งปัญหา] $description';
      if (photos.isEmpty) {
        final res = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orderId': orderId,
            'customerId': riderId,
            'reasonType': reasonType,
            'description': desc,
          }),
        ).timeout(const Duration(seconds: 20));
        return res.statusCode == 201;
      }
      final req = http.MultipartRequest('POST', uri)
        ..fields['orderId']     = orderId
        ..fields['customerId']  = riderId
        ..fields['reasonType']  = reasonType
        ..fields['description'] = desc;
      for (final photo in photos) {
        req.files.add(await http.MultipartFile.fromPath('evidence', photo.path));
      }
      final streamed = await req.send().timeout(const Duration(seconds: 20));
      return streamed.statusCode == 201;
    } catch (_) { return false; }
  }

  static Future<Map<String, dynamic>?> createQrPayment({
    required String orderId,
    required int amount,
    String? description,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$kBackendUrl/api/payment/qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId, 'amount': amount, 'description': description ?? 'Rider Wallet Topup'}),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> createCardPayment({
    required String orderId,
    required int amount,
    String? description,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$kBackendUrl/api/payment/card'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId, 'amount': amount, 'description': description ?? 'Rider Wallet Topup'}),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> topupRiderWallet({
    required String riderId,
    required double amount,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/wallet/topup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rider_id': riderId, 'amount': amount, 'description': 'ไรเดอร์เติมเงินชำระหนี้'}),
      );
      if (res.statusCode != 200 && res.statusCode != 201) return null;
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<bool> requestLoan({required String riderId, required double amount, String? reason}) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/loan/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rider_id': riderId, 'amount': amount, if (reason != null && reason.isNotEmpty) 'reason': reason}),
      );
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<List<Map<String, dynamic>>> getLoanHistory(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/loan/$riderId'));
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> getWallet(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/wallet/$riderId'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return {'balance': 0.0};
  }

  static Future<List<Map<String, dynamic>>> getWalletTransactions(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/wallet/$riderId/transactions'));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return [];
  }

  static Future<void> updateLocation(String riderId, double lat, double lng) async {
    try {
      await http.patch(
        Uri.parse('$_base/$riderId/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'latitude': lat, 'longitude': lng}),
      );
    } catch (_) {}
  }

  static Future<bool> updateOrderStep(
    String orderId,
    String riderId,
    String step, {
    double? lat,
    double? lng,
  }) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base/orders/$orderId/step'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rider_id': riderId,
          'step': step,
          if (lat != null) 'latitude': lat,
          if (lng != null) 'longitude': lng,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
