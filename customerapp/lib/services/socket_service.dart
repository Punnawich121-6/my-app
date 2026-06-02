import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config.dart';

class SocketService {
  static final SocketService _i = SocketService._();
  static SocketService get instance => _i;
  SocketService._();

  io.Socket? _socket;
  static final _url = kBackendUrl;

  final _orderUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get orderUpdates =>
      _orderUpdatesController.stream;

  /// Stream of all new_message events received globally.
  Stream<Map<String, dynamic>> get chatUpdates =>
      _chatUpdatesController.stream;

  bool get connected => _socket?.connected == true;

  void connect({void Function()? onConnect}) {
    if (_socket?.connected == true) {
      onConnect?.call();
      return;
    }
    if (_socket == null) {
      _socket = io.io(
        _url,
        io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setExtraHeaders({'ngrok-skip-browser-warning': 'true'})
          .build(),
      );
      // Global listeners — feed broadcast streams for any subscriber.
      _socket!.on('order_updated', (data) {
        if (!_orderUpdatesController.isClosed) {
          _orderUpdatesController.add(Map<String, dynamic>.from(data as Map));
        }
      });
      _socket!.on('new_message', (data) {
        if (!_chatUpdatesController.isClosed) {
          _chatUpdatesController.add(Map<String, dynamic>.from(data as Map));
        }
      });
    }
    if (onConnect != null) {
      _socket!.once('connect', (_) => onConnect());
    }
    if (_socket!.disconnected) _socket!.connect();
  }

  void joinOrder(String orderId) => _socket?.emit('join_order', orderId);
  void leaveOrder(String orderId) => _socket?.emit('leave_order', orderId);

  void joinCustomer(String customerId) =>
      _socket?.emit('join_customer', customerId);
  void leaveCustomer(String customerId) =>
      _socket?.emit('leave_customer', customerId);

  void joinSupport(String threadId) => _socket?.emit('join_support', threadId);
  void leaveSupport(String threadId) =>
      _socket?.emit('leave_support', threadId);

  void on(String event, Function(dynamic) handler) =>
      _socket?.on(event, handler);
  void off(String event) => _socket?.off(event);
}
