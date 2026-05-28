import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _i = SocketService._();
  static SocketService get instance => _i;
  SocketService._();

  io.Socket? _socket;
  static const _url = 'https://backend-gqls.onrender.com';

  final Set<String> _orderRooms = {};
  String? _supportRoom;

  void connect() {
    if (_socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }
    _socket = io.io(
      _url,
      io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .build(),
    );
    _socket!.onConnect((_) {
      for (final id in _orderRooms) {
        _socket?.emit('join_order', id);
      }
      if (_supportRoom != null) {
        _socket?.emit('join_support', _supportRoom);
      }
    });
    _socket!.connect();
  }

  void joinOrder(String orderId) {
    _orderRooms.add(orderId);
    if (_socket?.connected == true) _socket?.emit('join_order', orderId);
  }

  void leaveOrder(String orderId) {
    _orderRooms.remove(orderId);
    _socket?.emit('leave_order', orderId);
  }

  void joinSupportRoom(String storeId) {
    _supportRoom = storeId;
    if (_socket?.connected == true) _socket?.emit('join_support', storeId);
  }

  void leaveSupportRoom(String storeId) {
    if (_supportRoom == storeId) _supportRoom = null;
    _socket?.emit('leave_support', storeId);
  }

  void on(String event, Function(dynamic) handler) => _socket?.on(event, handler);
  void off(String event) => _socket?.off(event);
}
