import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/socket_service.dart';
import '../../config.dart';

class RiderChatScreen extends StatefulWidget {
  final String orderId;
  final String riderId;
  final String riderName;
  final String customerName;
  final String storeName;
  final String chatType; // 'rider' = คุยกับลูกค้า, 'store' = คุยกับร้านค้า

  const RiderChatScreen({
    super.key,
    required this.orderId,
    required this.riderId,
    required this.riderName,
    required this.customerName,
    required this.storeName,
    this.chatType = 'rider',
  });

  @override
  State<RiderChatScreen> createState() => _RiderChatScreenState();
}

class _RiderChatScreenState extends State<RiderChatScreen> {
  static String get _base => '$kBackendUrl/api/chat';

  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages(initial: true);
    SocketService.instance.connect();
    SocketService.instance.joinOrder(widget.orderId);
    SocketService.instance.on('new_message', _onSocketMessage);
  }

  @override
  void dispose() {
    SocketService.instance.off('new_message');
    SocketService.instance.leaveOrder(widget.orderId);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSocketMessage(dynamic data) {
    if (!mounted) return;
    final msg = Map<String, dynamic>.from(data as Map);
    if (msg['chat_type'] != widget.chatType) return;
    final id = msg['id']?.toString();
    if (id != null && _messages.any((m) => m['id']?.toString() == id)) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
    _lastCount = _messages.length;
  }

  Future<void> _loadMessages({bool initial = false}) async {
    try {
      final res = await http.get(Uri.parse(
        '$_base/${widget.orderId}?userId=${widget.riderId}&userRole=rider&chatType=${widget.chatType}',
      ));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        final msgs = data.map((e) => Map<String, dynamic>.from(e)).toList();
        final newCount = msgs.length;
        setState(() {
          _messages.clear();
          _messages.addAll(msgs);
          _loading = false;
        });
        if (initial || newCount > _lastCount) _scrollToBottom();
        _lastCount = newCount;
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await http.post(
        Uri.parse('$_base/${widget.orderId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.riderId,
          'userRole': 'rider',
          'senderName': widget.riderName,
          'message': text,
          'chatType': widget.chatType,
        }),
      );
      await _loadMessages();
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(dynamic isoStr) {
    if (isoStr == null) return '';
    final dt = DateTime.tryParse(isoStr.toString())?.toLocal();
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  Color _roleColor(String role) {
    if (role == 'customer') return const Color(0xFFFF8C5A);
    if (role == 'store') return const Color(0xFFFF6B35);
    return const Color(0xFFFF4500);
  }

  IconData _roleIcon(String role) {
    if (role == 'customer') return Icons.person_rounded;
    if (role == 'store') return Icons.store_rounded;
    return Icons.directions_bike_rounded;
  }

  bool _isMe(Map<String, dynamic> msg) =>
      msg['sender_role'] == 'rider' &&
      msg['sender_id'].toString() == widget.riderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B35),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.chatType == 'store' ? Icons.store_rounded : Icons.person_rounded,
              color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                widget.chatType == 'store' ? widget.storeName : widget.customerName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                widget.chatType == 'store' ? 'แชทกับร้านค้า' : 'แชทกับลูกค้า',
                style: const TextStyle(fontSize: 11, color: Colors.white),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
              : _messages.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 80, height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                            color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text('ยังไม่มีข้อความ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 6),
                        const Text('ส่งข้อความเพื่อเริ่มสนทนากับลูกค้า',
                          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
                      ]),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final isMe = _isMe(msg);
                        final role = msg['sender_role'] as String? ?? 'rider';
                        final isLast = i == _messages.length - 1;
                        return _RiderMsgBubble(
                          message: msg['message'] ?? '',
                          senderName: msg['sender_name'] ?? '',
                          time: _formatTime(msg['created_at']),
                          isMe: isMe,
                          roleColor: _roleColor(role),
                          roleIcon: _roleIcon(role),
                          showSent: isMe && isLast,
                        );
                      },
                    ),
        ),
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFD0BB)),
            ),
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              decoration: const InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _sending ? null : _send,
          child: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
            child: _sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _RiderMsgBubble extends StatelessWidget {
  final String message;
  final String senderName;
  final String time;
  final bool isMe;
  final Color roleColor;
  final IconData roleIcon;
  final bool showSent;

  const _RiderMsgBubble({
    required this.message,
    required this.senderName,
    required this.time,
    required this.isMe,
    required this.roleColor,
    required this.roleIcon,
    this.showSent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(roleIcon, color: roleColor, size: 16),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text(senderName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: roleColor, fontWeight: FontWeight.w600)),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFFFF6B35) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [BoxShadow(
                        color: isMe
                            ? const Color(0xFFFF4500).withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )],
                    ),
                    child: Text(message,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : const Color(0xFF1A1A1A),
                        height: 1.4,
                      )),
                  ),
                ),
                const SizedBox(height: 3),
                Row(children: [
                  Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                  if (showSent) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFFFF6B35)),
                    const SizedBox(width: 2),
                    const Text('ส่งแล้ว',
                      style: TextStyle(fontSize: 12, color: Color(0xFFFF6B35), fontWeight: FontWeight.w600)),
                  ],
                ]),
              ],
            ),
          ),
          if (isMe) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_bike_rounded, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}
