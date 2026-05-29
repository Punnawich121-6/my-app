import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config.dart';

class SocketService {
  static final SocketService _i = SocketService._();
  static SocketService get instance => _i;
  SocketService._();

  IO.Socket? _socket;
  static final _url = kBackendUrl;

  bool get connected => _socket?.connected == true;

  void connect({void Function()? onConnect}) {
    if (_socket?.connected == true) {
      onConnect?.call();
      return;
    }
    if (_socket == null) {
      _socket = IO.io(
        _url,
        IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setExtraHeaders({'ngrok-skip-browser-warning': 'true'})
          .build(),
      );
    }
    if (onConnect != null) {
      _socket!.once('connect', (_) => onConnect());
    }
    if (_socket!.disconnected) _socket!.connect();
  }

  void joinOrder(String orderId) => _socket?.emit('join_order', orderId);
  void leaveOrder(String orderId) => _socket?.emit('leave_order', orderId);

  void joinSupport(String threadId) => _socket?.emit('join_support', threadId);
  void leaveSupport(String threadId) => _socket?.emit('leave_support', threadId);

  void on(String event, Function(dynamic) handler) => _socket?.on(event, handler);
  void off(String event) => _socket?.off(event);
}
