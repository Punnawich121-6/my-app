import 'dart:async';
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../main.dart';
import '../screen/chat/chat_screen.dart';
import '../screen/order/order_tracking_screen.dart';
import '../widgets/order_status_popup.dart';
import 'socket_service.dart';

class OrderNotificationService {
  OrderNotificationService._();
  static final instance = OrderNotificationService._();

  GlobalKey<NavigatorState>? navigatorKey;

  final activeOrder = ValueNotifier<Map<String, dynamic>?>(null);

  StreamSubscription<Map<String, dynamic>>? _orderSub;
  StreamSubscription<Map<String, dynamic>>? _chatSub;
  OverlayEntry? _entry;
  String? _lastOrderId;
  DateTime? _lastShown;
  String? _customerId;
  String? _customerName;

  bool _chatActive = false;
  String? _activeChatOrderId;

  void setChatActive(bool active, {String? orderId}) {
    _chatActive = active;
    _activeChatOrderId = orderId;
  }

  void start(String customerId, String customerName) {
    stop();
    _customerId = customerId;
    _customerName = customerName;

    SocketService.instance.connect(onConnect: () {
      SocketService.instance.joinCustomer(customerId);
    });

    SocketService.instance.on('connect', (_) {
      SocketService.instance.joinCustomer(customerId);
    });

    _orderSub = SocketService.instance.orderUpdates.listen(_onOrderUpdated);
    _chatSub  = SocketService.instance.chatUpdates.listen(_onChatMessage);
  }

  void stop() {
    if (_customerId != null) {
      SocketService.instance.off('connect');
    }
    _orderSub?.cancel();
    _chatSub?.cancel();
    _orderSub = null;
    _chatSub  = null;
    _customerId = null;
    _customerName = null;
    activeOrder.value = null;
    _dismiss();
  }

  // ── Order notifications ───────────────────────────────────────────────────

  void _onOrderUpdated(Map<String, dynamic> data) {
    final orderId = data['order_id']?.toString() ?? '';
    final status  = data['status']?.toString()   ?? '';

    if (orderId.isEmpty) return;

    _updateActiveBar(data);

    if (status == 'pending') return;

    if (!AppSettings.instance.pushNotif || !AppSettings.instance.orderUpdates) return;

    final now = DateTime.now();
    if (_lastOrderId == orderId &&
        _lastShown != null &&
        now.difference(_lastShown!) < const Duration(seconds: 2)) {
      return;
    }
    _lastOrderId = orderId;
    _lastShown = now;

    final storeName = data['store_name']?.toString() ?? 'ร้านอาหาร';
    _showOrderPopup(orderId: orderId, status: status, storeName: storeName);
  }

  void notifyOrderPlaced({required String orderId, required String storeName}) {
    _updateActiveBar({
      'order_id': orderId,
      'status': 'pending',
      'store_name': storeName,
    });
  }

  void _updateActiveBar(Map<String, dynamic> data) {
    final status  = data['status']?.toString() ?? '';
    final orderId = data['order_id']?.toString() ?? '';
    activeOrder.value = data;

    if (status == 'completed' || status == 'cancelled' || status == 'picking_up') {
      final delay = status == 'picking_up'
          ? const Duration(seconds: 10)
          : const Duration(seconds: 7);
      Future.delayed(delay, () {
        if (activeOrder.value?['order_id']?.toString() == orderId &&
            activeOrder.value?['status']?.toString() == status) {
          activeOrder.value = null;
        }
      });
    }
  }

  // ── Chat notifications ────────────────────────────────────────────────────

  void _onChatMessage(Map<String, dynamic> data) {
    if (!AppSettings.instance.pushNotif) return;

    final senderType = data['sender_type']?.toString() ?? '';
    if (senderType == 'customer') return;

    final orderId  = data['order_id']?.toString() ?? '';
    final chatType = data['chat_type']?.toString() ?? 'store';

    if (_chatActive && _activeChatOrderId == orderId) return;

    final senderName = data['sender_name']?.toString() ??
        (chatType == 'rider' ? 'ไรเดอร์' : 'ร้านอาหาร');
    final message = data['message']?.toString() ?? 'ส่งรูปภาพ';

    _showChatToast(
      orderId: orderId,
      chatType: chatType,
      senderName: senderName,
      message: message,
    );
  }

  void _showChatToast({
    required String orderId,
    required String chatType,
    required String senderName,
    required String message,
  }) {
    final overlay = _overlayState;
    if (overlay == null) return;

    _dismiss();

    _entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 12,
        left: 0,
        right: 0,
        child: _ChatNotifToast(
          senderName: senderName,
          message: message,
          chatType: chatType,
          onTap: () => _navigateToChat(
            orderId: orderId,
            chatType: chatType,
            storeName: senderName,
          ),
          onDismiss: _dismiss,
        ),
      ),
    );

    overlay.insert(_entry!);
  }

  void _navigateToChat({
    required String orderId,
    required String chatType,
    required String storeName,
  }) {
    final nav = navigatorKey?.currentState;
    if (nav == null || _customerId == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        orderId: orderId,
        customerId: _customerId!,
        customerName: _customerName ?? '',
        storeName: storeName,
        chatType: chatType,
      ),
    ));
  }

  // ── Order popup ───────────────────────────────────────────────────────────

  void _showOrderPopup({
    required String orderId,
    required String status,
    required String storeName,
  }) {
    final overlay = _overlayState;
    if (overlay == null) return;

    _dismiss();

    _entry = OverlayEntry(
      builder: (ctx) => Positioned(
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
    try { _entry?.remove(); } catch (_) {}
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

// ── Chat notification toast ───────────────────────────────────────────────────

class _ChatNotifToast extends StatefulWidget {
  final String senderName;
  final String message;
  final String chatType;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ChatNotifToast({
    required this.senderName,
    required this.message,
    required this.chatType,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_ChatNotifToast> createState() => _ChatNotifToastState();
}

class _ChatNotifToastState extends State<_ChatNotifToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;
  double _progress = 1.0;

  static const _autoDismiss = Duration(seconds: 5);
  static const _tickMs = 40;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6));
    _ctrl.forward();
    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _progress -= _tickMs / _autoDismiss.inMilliseconds);
      if (_progress <= 0) { t.cancel(); _animateOut(); }
    });
  }

  Future<void> _animateOut() async {
    _timer?.cancel();
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const chatColor = Color(0xFF1976D2);
    final icon = widget.chatType == 'rider'
        ? Icons.delivery_dining_rounded
        : Icons.store_rounded;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: () {
            _timer?.cancel();
            _ctrl.reverse().then((_) => widget.onDismiss());
            widget.onTap();
          },
          onVerticalDragUpdate: (d) {
            if (d.primaryDelta != null && d.primaryDelta! < -5) _animateOut();
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: chatColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: chatColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.senderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: CColors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: CColors.muted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: chatColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ดูแชท',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: LinearProgressIndicator(
                      value: _progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation(
                          chatColor.withValues(alpha: 0.55)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
