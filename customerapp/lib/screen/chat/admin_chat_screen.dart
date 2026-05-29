import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../config.dart';
import '../../main.dart';
import '../../services/socket_service.dart';

class AdminChatScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const AdminChatScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  static final _base = '$kBackendUrl/api/support';

  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  XFile? _pickedImage;
  Timer? _pollTimer;

  String get _threadId => 'customer_${widget.customerId}';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    SocketService.instance.connect();
    SocketService.instance.joinSupport(_threadId);
    SocketService.instance.on('new_support_message', _onSocketMessage);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    SocketService.instance.off('new_support_message');
    SocketService.instance.leaveSupport(_threadId);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pollMessages() async {
    if (!mounted || _sending) return;
    try {
      final res = await apiGet('$_base/$_threadId');
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        final fetched = data.map((e) => Map<String, dynamic>.from(e)).toList();
        final existingIds = _messages.map((m) => m['id']?.toString()).toSet();
        final newMsgs = fetched.where((m) => !existingIds.contains(m['id']?.toString())).toList();
        if (newMsgs.isNotEmpty && mounted) {
          setState(() => _messages.addAll(newMsgs));
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  void _onSocketMessage(dynamic data) {
    if (!mounted) return;
    final payload = Map<String, dynamic>.from(data as Map);
    if (payload['storeId']?.toString() != _threadId) return;
    final msg = Map<String, dynamic>.from(payload['message'] as Map);
    final id = msg['id']?.toString();
    if (id != null && _messages.any((m) => m['id']?.toString() == id)) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  Future<void> _loadMessages() async {
    try {
      final res = await apiGet('$_base/$_threadId');
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() {
          _messages
            ..clear()
            ..addAll(data.map((e) => Map<String, dynamic>.from(e)));
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null && mounted) {
      setState(() => _pickedImage = file);
    }
  }

  Future<String?> _uploadImage(XFile file) async {
    try {
      final uri = Uri.parse('$_base/$_threadId/upload');
      final request = http.MultipartRequest('POST', uri);
      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: file.name));
      final response = await request.send();
      if (response.statusCode == 200) {
        final body = jsonDecode(await response.stream.bytesToString());
        return body['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if ((text.isEmpty && _pickedImage == null) || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();

    final imageToUpload = _pickedImage;
    setState(() => _pickedImage = null);

    try {
      String? imageUrl;
      if (imageToUpload != null) {
        imageUrl = await _uploadImage(imageToUpload);
      }

      await apiPost(
        '$_base/$_threadId',
        jsonEncode({
          'senderRole': 'customer',
          'senderName': widget.customerName,
          'storeName': widget.customerName,
          'message': text,
          'imageUrl': imageUrl,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.card,
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
                decoration: BoxDecoration(color: context.subtleBg, shape: BoxShape.circle),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: context.fg, size: 16),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
              child: const Icon(Icons.support_agent_rounded, color: CColors.orange, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ทีมสนับสนุน',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.fg),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('ติดต่อ Admin',
                    style: TextStyle(fontSize: 11, color: context.muted)),
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
                          child: const Icon(Icons.support_agent_rounded, color: CColors.orange, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text('ยังไม่มีข้อความ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.fg)),
                        const SizedBox(height: 6),
                        Text('ส่งข้อความเพื่อติดต่อทีมสนับสนุน',
                          style: TextStyle(color: context.muted, fontSize: 13)),
                      ]),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final isMe = msg['sender_role'] == 'customer';
                        return _SupportBubble(
                          message: msg['message'] ?? '',
                          imageUrl: msg['image_url'] as String?,
                          time: _formatTime(msg['created_at']),
                          isMe: isMe,
                        );
                      },
                    ),
        ),
        if (_pickedImage != null)
          _ImagePreviewBar(
            file: _pickedImage!,
            onRemove: () => setState(() => _pickedImage = null),
          ),
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: context.card,
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 12, offset: const Offset(0, -3),
        )],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: context.subtleBg, shape: BoxShape.circle),
            child: Icon(Icons.image_rounded, color: context.muted, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: context.subtleBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              controller: _ctrl,
              style: TextStyle(fontSize: 14, color: context.fg),
              decoration: InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                hintStyle: TextStyle(color: context.muted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

class _ImagePreviewBar extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _ImagePreviewBar({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.card,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(file.path, width: 64, height: 64, fit: BoxFit.cover,
            errorBuilder: (_, e, stack) => Container(
              width: 64, height: 64, color: CColors.orangeLight,
              child: const Icon(Icons.image_rounded, color: CColors.orange),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(file.name, style: TextStyle(fontSize: 12, color: context.muted), overflow: TextOverflow.ellipsis)),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ),
      ]),
    );
  }
}

class _SupportBubble extends StatelessWidget {
  final String message;
  final String? imageUrl;
  final String time;
  final bool isMe;

  const _SupportBubble({
    required this.message,
    required this.time,
    required this.isMe,
    this.imageUrl,
  });

  Widget _buildImage(String url) {
    final broken = Container(
      width: 160, height: 120,
      color: CColors.orangeLight,
      child: const Icon(Icons.broken_image_rounded, color: CColors.orange),
    );
    if (url.startsWith('data:')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(bytes, fit: BoxFit.cover,
            errorBuilder: (_, e, s) => broken);
      } catch (_) {
        return broken;
      }
    }
    final fullUrl = url.startsWith('http') ? url : '$kBackendUrl$url';
    return Image.network(fullUrl, fit: BoxFit.cover,
        errorBuilder: (_, e, s) => broken);
  }

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
              decoration: const BoxDecoration(color: CColors.orangeLight, shape: BoxShape.circle),
              child: const Icon(Icons.support_agent_rounded, color: CColors.orange, size: 16),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3, left: 2),
                    child: Text('Admin',
                      style: TextStyle(
                        fontSize: 11, color: CColors.orange, fontWeight: FontWeight.w600)),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: imageUrl != null ? 6 : 14,
                      vertical: imageUrl != null ? 6 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? CColors.orange : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildImage(imageUrl!),
                          ),
                        if (imageUrl != null && message.isNotEmpty)
                          const SizedBox(height: 6),
                        if (message.isNotEmpty)
                          Text(message,
                            style: TextStyle(
                              fontSize: 14,
                              color: isMe ? Colors.white : CColors.text,
                              height: 1.4)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(time,
                  style: const TextStyle(fontSize: 11, color: CColors.muted)),
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
