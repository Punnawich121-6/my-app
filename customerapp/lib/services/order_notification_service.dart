import 'dart:async';
import 'package:flutter/material.dart';
import '../screen/order/order_tracking_screen.dart';
import '../widgets/order_status_popup.dart';
import 'socket_service.dart';

/// Shows GrabFood-style status popups whenever an order_updated socket event
/// is received, regardless of which screen the user is currently on.
class OrderNotificationService {
  OrderNotificationService._();
  static final instance = OrderNotificationService._();

  // Provided by main.dart after MaterialApp is built.
  GlobalKey<NavigatorState>? navigatorKey;

  StreamSubscription<Map<String, dynamic>>? _sub;
  OverlayEntry? _entry;

  // Debounce: don't stack popups for the same order within 2 seconds.
  String? _lastOrderId;
  DateTime? _lastShown;

  /// Call once after the user logs in (pass their customerId).
  void start(String customerId) {
    stop();
    SocketService.instance.connect();
    SocketService.instance.joinCustomer(customerId);
    _sub = SocketService.instance.orderUpdates.listen(_onOrderUpdated);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _dismiss();
  }

  void _onOrderUpdated(Map<String, dynamic> data) {
    final orderId   = data['order_id']?.toString() ?? '';
    final status    = data['status']?.toString()   ?? '';
    final storeName = data['store_name']?.toString() ?? 'ร้านอาหาร';

    // Skip statuses that don't need a popup.
    if (orderId.isEmpty || status == 'pending') return;

    // Debounce same-order rapid updates.
    final now = DateTime.now();
    if (_lastOrderId == orderId &&
        _lastShown != null &&
        now.difference(_lastShown!) < const Duration(seconds: 2)) {
      return;
    }
    _lastOrderId = orderId;
    _lastShown = now;

    _showPopup(orderId: orderId, status: status, storeName: storeName);
  }

  void _showPopup({
    required String orderId,
    required String status,
    required String storeName,
  }) {
    final overlay = _overlayState;
    if (overlay == null) return;

    _dismiss(); // remove any existing popup first

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(navigatorKey!.currentContext!).padding.top + 12,
        left: 0,
        right: 0,
        child: OrderStatusPopup(
          orderId: orderId,
          status: status,
          storeName: storeName,
          onTap: () => _navigateToTracking(orderId),
          onDismiss: _dismiss,
        ),
      ),
    );

    overlay.insert(_entry!);
  }

  void _dismiss() {
    _entry?.remove();
    _entry = null;
  }

  void _navigateToTracking(String orderId) {
    final nav = navigatorKey?.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => OrderTrackingScreen(orderId: orderId),
    ));
  }

  OverlayState? get _overlayState {
    final ctx = navigatorKey?.currentContext;
    if (ctx == null) return null;
    return Overlay.of(ctx);
  }
}
