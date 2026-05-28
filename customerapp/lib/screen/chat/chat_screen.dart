import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config.dart';
import '../../main.dart';
import '../../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String customerId;
  final String customerName;
  final String storeName;
  final String chatType; // 'store' or 'rider'

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.storeName,
    this.chatType = 'store',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static final _base = '$kBackendUrl/api/chat';

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
      final res = await apiGet(
        '$_base/${widget.orderId}?userId=${widget.customerId}&userRole=customer&chatType=${widget.chatType}',
      );
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
      await apiPost(
        '$_base/${widget.orderId}',
        jsonEncode({
          'userId': widget.customerId,
          'userRole': 'customer',
          'senderName': widget.customerName,
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
    return '$h:${m} ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  Color _roleColor(String role) {
    if (role == 'store') return const Color(0xFF1976D2);
    if (role == 'rider') return CColors.green;
    return CColors.orange;
  }

  IconData _roleIcon(String role) {
    if (role == 'store') return Icons.store_rounded;
    if (role == 'rider') return Icons.directions_bike_rounded;
    return Icons.person_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: CColors.text, size: 16),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: widget.chatType == 'rider' ? const Color(0xFFE3F2FD) : CColors.orangeLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.chatType == 'rider' ? Icons.directions_bike_rounded : Icons.store_rounded,
                color: widget.chatType == 'rider' ? const Color(0xFF1976D2) : CColors.orange,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.chatType == 'rider' ? 'ไรเดอร์' : widget.storeName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: CColors.text),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(widget.chatType == 'rider' ? 'แชทกับไรเดอร์' : 'แชทกับร้านค้า',
                    style: const TextStyle(fontSize: 11, color: CColors.muted)),
                ],
              ),
            ),
          ]),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: CColors.orange))
              : _messages.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 72, height: 72,
                          decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
                          child: const Icon(Icons.chat_bubble_rounded, color: CColors.orange, size: 34),
                        ),
                        const SizedBox(height: 16),
                        const Text('ยังไม่มีข้อความ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CColors.text)),
                        const SizedBox(height: 6),
                        const Text('ส่งข้อความเพื่อเริ่มสนทนา',
                          style: TextStyle(color: CColors.muted, fontSize: 13)),
                      ]),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final isMe = msg['sender_role'] == 'customer' &&
                            msg['sender_id'].toString() == widget.customerId;
                        final role = msg['sender_role'] as String? ?? 'customer';
                        return _MessageBubble(
                          message: msg['message'] ?? '',
                          senderName: msg['sender_name'] ?? '',
                          time: _formatTime(msg['created_at']),
                          isMe: isMe,
                          roleColor: _roleColor(role),
                          roleIcon: _roleIcon(role),
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
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(22)),
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(fontSize: 14, color: CColors.text),
              decoration: const InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                hintStyle: TextStyle(color: CColors.muted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _send,
          child: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
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

class _MessageBubble extends StatelessWidget {
  final String message;
  final String senderName;
  final String time;
  final bool isMe;
  final Color roleColor;
  final IconData roleIcon;

  const _MessageBubble({
    required this.message,
    required this.senderName,
    required this.time,
    required this.isMe,
    required this.roleColor,
    required this.roleIcon,
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
                      color: isMe ? CColors.orange : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
                    ),
                    child: Text(message,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : CColors.text,
                        height: 1.4)),
                  ),
                ),
                const SizedBox(height: 3),
                Text(time, style: const TextStyle(fontSize: 11, color: CColors.muted)),
              ],
            ),
          ),
          if (isMe) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}
