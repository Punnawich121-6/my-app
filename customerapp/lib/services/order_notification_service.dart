import 'dart:async';
import 'package:flutter/material.dart';
import '../screen/order/order_tracking_screen.dart';
import '../widgets/order_status_popup.dart';
import 'socket_service.dart';

class OrderNotificationService {
  OrderNotificationService._();
  static final instance = OrderNotificationService._();

  GlobalKey<NavigatorState>? navigatorKey;

  StreamSubscription<Map<String, dynamic>>? _sub;
  OverlayEntry? _entry;
  String? _lastOrderId;
  DateTime? _lastShown;
  String? _customerId;

  void start(String customerId) {
    stop();
    _customerId = customerId;

    // Join customer room after socket connects (handles both first-connect and reconnect)
    SocketService.instance.connect(onConnect: () {
      SocketService.instance.joinCustomer(customerId);
    });

    // Also handle reconnection: re-join on every 'connect' event
    SocketService.instance.on('connect', (_) {
      SocketService.instance.joinCustomer(customerId);
    });

    _sub = SocketService.instance.orderUpdates.listen(_onOrderUpdated);
  }

  void stop() {
    if (_customerId != null) {
      SocketService.instance.off('connect');
    }
    _sub?.cancel();
    _sub = null;
    _customerId = null;
    _dismiss();
  }

  void _onOrderUpdated(Map<String, dynamic> data) {
    final orderId   = data['order_id']?.toString() ?? '';
    final status    = data['status']?.toString()   ?? '';
    final storeName = data['store_name']?.toString() ?? 'ร้านอาหาร';

    if (orderId.isEmpty || status == 'pending') return;

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

    _dismiss();

    _entry = OverlayEntry(
      builder: (ctx) => Positioned(
        // ใช้ ctx จาก builder แทน navigatorKey.currentContext เพื่อป้องกัน null crash
        top: MediaQuery.of(ctx).padding.top + 12,
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
    try {
      _entry?.remove();
    } catch (_) {}
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
