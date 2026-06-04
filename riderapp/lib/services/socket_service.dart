import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config.dart';

class SocketService {
  static final SocketService _i = SocketService._();
  static SocketService get instance => _i;
  SocketService._();

  IO.Socket? _socket;
  String? _supportRoom;

  void connect() {
    if (_socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }
    _socket = IO.io(
      kBackendUrl,
      IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .build(),
    );
    _socket!.onConnect((_) {
      if (_supportRoom != null) {
        _socket?.emit('join_support', _supportRoom);
      }
    });
    _socket!.connect();
  }

  void joinOrder(String orderId) => _socket?.emit('join_order', orderId);
  void leaveOrder(String orderId) => _socket?.emit('leave_order', orderId);

  void joinSupportRoom(String threadId) {
    _supportRoom = threadId;
    if (_socket?.connected == true) _socket?.emit('join_support', threadId);
  }

  void leaveSupportRoom(String threadId) {
    if (_supportRoom == threadId) _supportRoom = null;
    _socket?.emit('leave_support', threadId);
  }

  void on(String event, Function(dynamic) handler) => _socket?.on(event, handler);
  void off(String event) => _socket?.off(event);
}
