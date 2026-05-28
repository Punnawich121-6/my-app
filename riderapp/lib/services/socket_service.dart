import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config.dart';

class SocketService {
  static final SocketService _i = SocketService._();
  static SocketService get instance => _i;
  SocketService._();

  IO.Socket? _socket;

  void connect() {
    if (_socket?.connected == true) return;
    _socket = IO.io(
      kBackendUrl,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
    );
    _socket!.connect();
  }

  void joinOrder(String orderId) => _socket?.emit('join_order', orderId);
  void leaveOrder(String orderId) => _socket?.emit('leave_order', orderId);

  void on(String event, Function(dynamic) handler) => _socket?.on(event, handler);
  void off(String event) => _socket?.off(event);
}
