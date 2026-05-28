import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../main.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  // static: ไม่รีเซ็ตเมื่อ navigate กลับเข้ามา
  static final Set<String> _hiddenIds = {};

  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  File? _pickedImage;
  Timer? _pollTimer;

  static const _mediaBase = 'http://10.0.2.2:3001';

  @override
  void initState() {
    super.initState();
    _loadAll();
    SocketService.instance.connect();
    SocketService.instance.joinSupportRoom(ApiService.storeId);
    SocketService.instance.on('new_support_message', _onSocketMessage);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _appendNew());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    SocketService.instance.off('new_support_message');
    SocketService.instance.leaveSupportRoom(ApiService.storeId);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSocketMessage(dynamic data) {
    if (!mounted) return;
    final raw = data is Map ? data['message'] : null;
    if (raw == null) return;
    final msg = Map<String, dynamic>.from(raw as Map);
    final id = msg['id']?.toString();
    if (id != null && _hiddenIds.contains(id)) return;
    if (id != null && _messages.any((m) => m['id']?.toString() == id)) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  // โหลดครั้งแรก — กรอง hidden
  Future<void> _loadAll() async {
    try {
      final msgs = await ApiService.getSupportMessages();
      if (!mounted) return;
      setState(() {
        _messages..clear()..addAll(msgs.where((m) => !_hiddenIds.contains(m['id']?.toString())));
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // poll: append เฉพาะ id ใหม่ ไม่ clear list
  Future<void> _appendNew() async {
    if (!mounted) return;
    try {
      final msgs = await ApiService.getSupportMessages();
      final existing = _messages.map((m) => m['id']?.toString()).toSet();
      final newMsgs = msgs.where((m) {
        final id = m['id']?.toString();
        return id != null && !existing.contains(id) && !_hiddenIds.contains(id);
      }).toList();
      if (newMsgs.isNotEmpty && mounted) {
        setState(() => _messages.addAll(newMsgs));
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmClearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ล้างแชท'),
        content: const Text('ต้องการลบข้อความทั้งหมดใช่ไหม?'),
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _pickedImage = File(picked.path));
  }

  void _clearImage() => setState(() => _pickedImage = null);

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if ((text.isEmpty && _pickedImage == null) || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();

    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await ApiService.uploadSupportImage(_pickedImage!);
      setState(() => _pickedImage = null);
    }

    await ApiService.sendSupportMessage(text, imageUrl: imageUrl);
    if (!mounted) return;
    setState(() => _sending = false);
    await _appendNew();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
          ),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ทีมสนับสนุน', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text('Zest & Savory Admin', style: TextStyle(fontSize: 11, color: Colors.white)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
            tooltip: 'ล้างแชท',
            onPressed: _confirmClearChat,
          ),
        ],
      ),
      body: Column(children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.orangeLight,
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, color: AppColors.orange, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'ช่องทางติดต่อสอบถามและขอความช่วยเหลือจากทีม Admin',
                style: TextStyle(fontSize: 12, color: AppColors.orange),
              ),
            ),
          ]),
        ),

        // Messages
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
              : _messages.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => Dismissible(
                        key: ValueKey(_messages[i]['id'] ?? i),
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
                        child: _buildBubble(_messages[i]),
                      ),
                    ),
        ),

        // Image preview
        if (_pickedImage != null) _buildImagePreview(),

        // Input
        _buildInput(),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: AppColors.orangeLight, shape: BoxShape.circle),
            child: const Icon(Icons.support_agent_rounded, color: AppColors.orange, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('ยังไม่มีข้อความ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text(
            'ส่งข้อความถึงทีม Admin ได้เลย\nเราพร้อมช่วยเหลือคุณ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
          ),
        ]),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender_role'] == 'store';
    final text = msg['message']?.toString() ?? '';
    final imageUrl = msg['image_url']?.toString();
    final time = _formatTime(msg['created_at']?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFFF6B35),
              child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3, left: 2),
                    child: Text('Admin', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.orange : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            '$_mediaBase$imageUrl',
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) => progress == null
                                ? child
                                : const SizedBox(
                                    height: 120,
                                    child: Center(child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2)),
                                  ),
                            errorBuilder: (ctx, err, e) => const Row(
                              children: [Icon(Icons.broken_image_rounded, color: AppColors.muted), SizedBox(width: 6), Text('โหลดรูปไม่ได้', style: TextStyle(fontSize: 12))],
                            ),
                          ),
                        ),
                      if (imageUrl != null && imageUrl.isNotEmpty && text.isNotEmpty)
                        const SizedBox(height: 6),
                      if (text.isNotEmpty)
                        Text(
                          text,
                          style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppColors.text, height: 1.4),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(time, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_pickedImage!, height: 90, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _clearImage,
              child: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 40, height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.image_rounded, color: AppColors.muted, size: 22),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              decoration: const InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _send,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _sending ? AppColors.muted : AppColors.orange,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.orange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: _sending
                ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  String _formatTime(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
