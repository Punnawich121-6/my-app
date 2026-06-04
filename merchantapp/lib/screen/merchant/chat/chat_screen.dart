import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../main.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';

class MerchantChatScreen extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String chatType; // 'store' = คุยกับลูกค้า, 'rider' = คุยกับไรเดอร์

  const MerchantChatScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    this.chatType = 'store',
  });

  @override
  State<MerchantChatScreen> createState() => _MerchantChatScreenState();
}

class _MerchantChatScreenState extends State<MerchantChatScreen> {
  static String get _base => ApiService.chatBase;

  // static: ไม่รีเซ็ตเมื่อ navigate กลับเข้ามา
  static final Map<String, Set<String>> _hiddenByOrder = {};
  Set<String> get _hiddenIds =>
      _hiddenByOrder.putIfAbsent(widget.orderId, () => {});

  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    SocketService.instance.connect();
    SocketService.instance.joinOrder(widget.orderId);
    SocketService.instance.on('new_message', _onSocketMessage);
    // fallback poll: เพิ่มเฉพาะข้อความใหม่ ไม่ reload ทั้งหมด
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _appendNew());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
    if (id != null && _hiddenIds.contains(id)) return;
    if (id != null && _messages.any((m) => m['id']?.toString() == id)) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  // โหลดครั้งแรกเท่านั้น — กรอง hidden
  Future<void> _loadAll() async {
    try {
      final res = await http.get(Uri.parse(
        '$_base/${widget.orderId}?userId=${ApiService.storeId}&userRole=store&chatType=${widget.chatType}',
      ));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        final msgs = data.map((e) => Map<String, dynamic>.from(e)).toList();
        setState(() {
          _messages.clear();
          _messages.addAll(msgs.where((m) => !_hiddenIds.contains(m['id']?.toString())));
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // poll: append เฉพาะ id ใหม่ ไม่ clear list
  Future<void> _appendNew() async {
    if (!mounted) return;
    try {
      final res = await http.get(Uri.parse(
        '$_base/${widget.orderId}?userId=${ApiService.storeId}&userRole=store&chatType=${widget.chatType}',
      ));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        final existing = _messages.map((m) => m['id']?.toString()).toSet();
        final newMsgs = data
            .map((e) => Map<String, dynamic>.from(e))
            .where((m) {
              final id = m['id']?.toString();
              return id != null && !existing.contains(id) && !_hiddenIds.contains(id);
            })
            .toList();
        if (newMsgs.isNotEmpty && mounted) {
          setState(() => _messages.addAll(newMsgs));
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await ApiService.sendChatMessage(widget.orderId, text, chatType: widget.chatType);
      await _appendNew(); // append-only หลังส่ง
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _confirmClearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ล้างแชท'),
        content: const Text('ต้องการลบข้อความทั้งหมดใน conversation นี้ใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('ลบทั้งหมด')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _messages.clear());
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _sending = true);
    try {
      final url = await ApiService.uploadChatImage(widget.orderId, File(picked.path));
      if (url != null) {
        await ApiService.sendChatMessage(widget.orderId, '', chatType: widget.chatType, imageUrl: url);
        await _appendNew();
      }
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
    if (role == 'customer') return AppColors.orange;
    if (role == 'rider') return AppColors.green;
    return const Color(0xFF1976D2);
  }

  IconData _roleIcon(String role) {
    if (role == 'customer') return Icons.person_rounded;
    if (role == 'rider') return Icons.directions_bike_rounded;
    return Icons.store_rounded;
  }

  bool _isMe(Map<String, dynamic> msg) =>
      msg['sender_role'] == 'store' &&
      msg['sender_id'].toString() == ApiService.storeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatType == 'rider' ? 'แชทกับไรเดอร์' : widget.customerName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            Text(
              widget.chatType == 'rider'
                  ? 'Order #${widget.orderId}'
                  : 'แชทกับ ${widget.customerName}',
              style: const TextStyle(fontSize: 11, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
            tooltip: 'ล้างแชท',
            onPressed: _confirmClearChat,
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
              : _messages.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                            color: AppColors.orange, size: 34),
                        ),
                        const SizedBox(height: 16),
                        const Text('ยังไม่มีข้อความ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
                        const SizedBox(height: 6),
                        const Text('ส่งข้อความเพื่อเริ่มสนทนากับลูกค้า',
                          style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      ]),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final isMe = _isMe(msg);
                        final role = msg['sender_role'] as String? ?? 'store';
                        return Dismissible(
                          key: ValueKey(msg['id'] ?? i),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.transparent,
                            child: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 24),
                          ),
                          onDismissed: (_) => setState(() {
                            final id = _messages[i]['id']?.toString();
                            if (id != null) _hiddenIds.add(id);
                            _messages.removeAt(i);
                          }),
                          child: _MsgBubble(
                            message: msg['message'] ?? '',
                            imageUrl: msg['image_url'] as String?,
                            senderName: msg['sender_name'] ?? '',
                            time: _formatTime(msg['created_at']),
                            isMe: isMe,
                            roleColor: _roleColor(role),
                            roleIcon: _roleIcon(role),
                          ),
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
        GestureDetector(
          onTap: _sending ? null : _pickAndSendImage,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.image_outlined, color: AppColors.muted, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(22)),
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              decoration: const InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
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
            decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
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

class _MsgBubble extends StatelessWidget {
  final String message;
  final String? imageUrl;
  final String senderName;
  final String time;
  final bool isMe;
  final Color roleColor;
  final IconData roleIcon;

  const _MsgBubble({
    required this.message,
    this.imageUrl,
    required this.senderName,
    required this.time,
    required this.isMe,
    required this.roleColor,
    required this.roleIcon,
  });

  Widget _buildImage(String url) {
    if (url.startsWith('data:')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(
          Uint8List.fromList(bytes),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox(
            height: 80,
            child: Center(child: Icon(Icons.broken_image_outlined, color: AppColors.muted)),
          ),
        );
      } catch (_) {
        return const SizedBox(height: 80, child: Center(child: Icon(Icons.broken_image_outlined, color: AppColors.muted)));
      }
    }
    final fullUrl = url.startsWith('http') ? url : '${ApiService.serverBase}$url';
    return Image.network(
      fullUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2))),
      errorBuilder: (_, _, _) => const SizedBox(
        height: 80,
        child: Center(child: Icon(Icons.broken_image_outlined, color: AppColors.muted)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const myBubble   = AppColors.orange;
    const theirBubble = Color(0xFFFFF0E0);
    const myText     = Colors.white;
    const theirText  = Color(0xFF2D1A00);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Avatar ซ้าย (ฝั่งคนอื่น) ──────────────────────────────────
          if (!isMe)
            Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.orange.withValues(alpha: 0.35), width: 1.5),
              ),
              child: Icon(roleIcon, color: AppColors.orange, size: 18),
            ),

          // ── Bubble ────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // ชื่อผู้ส่ง
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 4,
                    left: isMe ? 0 : 4,
                    right: isMe ? 4 : 0,
                  ),
                  child: Text(
                    isMe ? 'ร้านของฉัน' : senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isMe ? AppColors.orange : AppColors.orange.withValues(alpha: 0.75),
                    ),
                  ),
                ),

                // Bubble
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  child: Container(
                    padding: imageUrl != null && message.isEmpty
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? myBubble : theirBubble,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      border: isMe
                          ? null
                          : Border.all(color: AppColors.orange.withValues(alpha: 0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: isMe
                              ? AppColors.orange.withValues(alpha: 0.28)
                              : Colors.black.withValues(alpha: 0.06),
                          blurRadius: isMe ? 10 : 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(message.isEmpty ? (isMe ? 18 : 4) : 0),
                              bottomRight: Radius.circular(message.isEmpty ? (isMe ? 4 : 18) : 0),
                            ),
                            child: _buildImage(imageUrl!),
                          ),
                        if (message.isNotEmpty)
                          Padding(
                            padding: imageUrl != null
                                ? const EdgeInsets.fromLTRB(14, 8, 14, 10)
                                : EdgeInsets.zero,
                            child: Text(
                              message,
                              style: TextStyle(
                                fontSize: 14,
                                color: isMe ? myText : theirText,
                                height: 1.45,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // เวลา
                Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    left: isMe ? 0 : 4,
                    right: isMe ? 4 : 0,
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),

          // ── Avatar ขวา (ตัวเอง) ────────────────────────────────────────
          if (isMe)
            Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(left: 8, bottom: 2),
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.store_rounded, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }
}
