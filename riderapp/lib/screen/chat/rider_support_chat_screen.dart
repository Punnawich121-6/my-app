import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config.dart';
import '../../main.dart';
import '../../services/rider_service.dart';
import '../../services/socket_service.dart';

class RiderSupportChatScreen extends StatefulWidget {
  final String riderId;
  final String riderName;

  const RiderSupportChatScreen({
    super.key,
    required this.riderId,
    required this.riderName,
  });

  @override
  State<RiderSupportChatScreen> createState() => _RiderSupportChatScreenState();
}

class _RiderSupportChatScreenState extends State<RiderSupportChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  XFile? _pickedImage;
  Timer? _pollTimer;

  String get _threadId => 'rider_${widget.riderId}';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    SocketService.instance.connect();
    SocketService.instance.joinSupportRoom(_threadId);
    SocketService.instance.on('new_support_message', _onSocketMessage);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollNew());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    SocketService.instance.off('new_support_message');
    SocketService.instance.leaveSupportRoom(_threadId);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSocketMessage(dynamic data) {
    if (!mounted) return;
    final raw = data is Map ? data['message'] : null;
    if (raw == null) return;
    final msg = Map<String, dynamic>.from(raw as Map);
    final threadId = data['storeId']?.toString();
    if (threadId != null && threadId != _threadId) return;
    final id = msg['id']?.toString();
    if (id != null && _messages.any((m) => m['id']?.toString() == id)) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await RiderService.getSupportMessages(widget.riderId);
      if (!mounted) return;
      setState(() {
        _messages..clear()..addAll(msgs);
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pollNew() async {
    if (!mounted) return;
    try {
      final msgs = await RiderService.getSupportMessages(widget.riderId);
      final existing = _messages.map((m) => m['id']?.toString()).toSet();
      final newMsgs = msgs
          .where((m) => !existing.contains(m['id']?.toString()))
          .toList();
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

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file != null && mounted) setState(() => _pickedImage = file);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.rCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: context.rDiv,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text('แนบรูปภาพ',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.rFg)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _SheetBtn(
                icon: Icons.photo_library_rounded,
                label: 'คลังภาพ',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SheetBtn(
                icon: Icons.camera_alt_rounded,
                label: 'ถ่ายรูป',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if ((text.isEmpty && _pickedImage == null) || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();

    final imageToUpload = _pickedImage;
    setState(() => _pickedImage = null);

    String? imageUrl;
    if (imageToUpload != null) {
      final bytes = await imageToUpload.readAsBytes();
      imageUrl = await RiderService.uploadSupportImage(
        widget.riderId,
        bytes,
        imageToUpload.name,
      );
    }

    await RiderService.sendSupportMessage(
      widget.riderId,
      widget.riderName,
      message: text,
      imageUrl: imageUrl,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    await _pollNew();
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ลบแชท', style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            const Text('ข้อความจะหายไปจากหน้าจอของคุณเท่านั้น\nทีม Admin ยังคงเห็นข้อความเดิม'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก',
                style: TextStyle(color: context.rMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await RiderService.clearSupportChat(widget.riderId);
              if (mounted) setState(() => _messages.clear());
            },
            child: const Text('ลบ',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic isoStr) {
    if (isoStr == null) return '';
    final dt = DateTime.tryParse(isoStr.toString())?.toLocal();
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.rBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 20),
          ),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ทีมสนับสนุน',
                style:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text('Zest & Savory Admin',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'ลบแชท',
            onPressed: _confirmClearChat,
          ),
        ],
      ),
      body: Column(children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: RiderColors.blueLight,
          child: const Row(children: [
            Icon(Icons.info_outline_rounded,
                color: RiderColors.blue, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'ช่องทางติดต่อทีม Admin สำหรับไรเดอร์',
                style: TextStyle(fontSize: 12, color: RiderColors.blue),
              ),
            ),
          ]),
        ),

        // Messages
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: RiderColors.blue))
              : _messages.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _buildBubble(_messages[i]),
                    ),
        ),

        // Image preview
        if (_pickedImage != null) _buildImagePreview(),

        // Input bar
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
                color: RiderColors.blueLight, shape: BoxShape.circle),
            child: const Icon(Icons.support_agent_rounded,
                color: RiderColors.blue, size: 36),
          ),
          const SizedBox(height: 16),
          Text('ยังไม่มีข้อความ',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.rFg)),
          const SizedBox(height: 8),
          Text(
            'ส่งข้อความถึงทีม Admin ได้เลย\nเราพร้อมช่วยเหลือคุณ',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: context.rMuted, height: 1.5),
          ),
        ]),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender_role'] == 'rider';
    final text = msg['message']?.toString() ?? '';
    final imageUrl = msg['image_url']?.toString();
    final time = _formatTime(msg['created_at']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: RiderColors.blueLight,
              child: Icon(Icons.support_agent_rounded,
                  color: RiderColors.blue, size: 15),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text('Admin',
                        style: TextStyle(
                            fontSize: 11,
                            color: context.rMuted,
                            fontWeight: FontWeight.w600)),
                  ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (imageUrl != null && imageUrl.isNotEmpty) ? 6 : 14,
                    vertical: (imageUrl != null && imageUrl.isNotEmpty) ? 6 : 10,
                  ),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.68),
                  decoration: BoxDecoration(
                    color: isMe ? RiderColors.blue : context.rCard,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isMe ? 0.15 : 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        _buildNetworkImage(imageUrl),
                      if (imageUrl != null &&
                          imageUrl.isNotEmpty &&
                          text.isNotEmpty)
                        const SizedBox(height: 6),
                      if (text.isNotEmpty)
                        Text(
                          text,
                          style: TextStyle(
                              fontSize: 14,
                              color: isMe ? Colors.white : context.rFg,
                              height: 1.4),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(time,
                    style:
                        TextStyle(fontSize: 11, color: context.rMuted)),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: RiderColors.blue, shape: BoxShape.circle),
              child: const Icon(Icons.directions_bike_rounded,
                  color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNetworkImage(String url) {
    if (url.contains('/uploads/')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.image_not_supported_rounded,
              size: 14, color: context.rMuted),
          const SizedBox(width: 6),
          Text('รูปภาพหมดอายุ',
              style: TextStyle(fontSize: 12, color: context.rMuted)),
        ]),
      );
    }
    if (url.startsWith('data:')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover),
        );
      } catch (_) {}
    }
    final fullUrl = url.startsWith('http') ? url : '$kBackendUrl$url';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        fullUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: double.infinity,
            height: 200,
            color: RiderColors.blueLight,
            child: const Center(
              child: CircularProgressIndicator(
                  color: RiderColors.blue, strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.broken_image_rounded,
                size: 14, color: context.rMuted),
            const SizedBox(width: 6),
            Text('โหลดรูปไม่ได้',
                style: TextStyle(fontSize: 12, color: context.rMuted)),
          ]),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      color: context.rCard,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(children: [
        FutureBuilder<dynamic>(
          future: _pickedImage!.readAsBytes(),
          builder: (_, snap) {
            if (snap.hasData) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(snap.data!,
                    width: 60, height: 60, fit: BoxFit.cover),
              );
            }
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: RiderColors.blueLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.image_rounded,
                  color: RiderColors.blue, size: 28),
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(_pickedImage!.name,
              style: TextStyle(fontSize: 12, color: context.rMuted),
              overflow: TextOverflow.ellipsis),
        ),
        GestureDetector(
          onTap: () => setState(() => _pickedImage = null),
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
                color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 14),
          ),
        ),
      ]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: context.rCard,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _pickedImage != null
                  ? RiderColors.blueLight
                  : context.isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _pickedImage != null
                  ? Icons.image_rounded
                  : Icons.add_photo_alternate_rounded,
              color: _pickedImage != null
                  ? RiderColors.blue
                  : context.rMuted,
              size: 22,
            ),
          ),
        ),
        Expanded(
          child: Container(
            constraints:
                const BoxConstraints(minHeight: 44, maxHeight: 120),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              controller: _ctrl,
              style: TextStyle(fontSize: 14, color: context.rFg),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                hintStyle: TextStyle(color: context.rMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sending ? null : _send,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _sending
                  ? context.rMuted
                  : RiderColors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: RiderColors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: _sending
                ? const Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _SheetBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SheetBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: RiderColors.blueLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: RiderColors.blue, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: RiderColors.blue)),
          ]),
        ),
      );
}
