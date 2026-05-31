import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
    SocketService.instance.connect(onConnect: () {
      SocketService.instance.joinSupport(_threadId);
    });
    if (SocketService.instance.connected) {
      SocketService.instance.joinSupport(_threadId);
    }
    SocketService.instance.on('connect', (_) {
      SocketService.instance.joinSupport(_threadId);
    });
    SocketService.instance.on('new_support_message', _onSocketMessage);
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    SocketService.instance.off('connect');
    SocketService.instance.off('new_support_message');
    SocketService.instance.leaveSupport(_threadId);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pollMessages() async {
    if (!mounted || _sending) return;
    try {
      final res = await apiGet('$_base/$_threadId?userId=${widget.customerId}&userRole=customer');
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
    // if image is stripped from socket payload, poll DB for full message
    if (msg['image_url']?.toString() == '[image]') {
      _pollMessages();
      return;
    }
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  Future<void> _loadMessages() async {
    try {
      final res = await apiGet('$_base/$_threadId?userId=${widget.customerId}&userRole=customer');
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() {
          _messages
            ..clear()
            ..addAll(data.map((e) => Map<String, dynamic>.from(e)));
          _loading = false;
        });
        _scrollToBottom();
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Show bottom sheet to choose camera or gallery
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(
        onGallery: () => _pickImage(ImageSource.gallery),
        onCamera: () => _pickImage(ImageSource.camera),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file != null && mounted) {
      setState(() => _pickedImage = file);
    }
  }

  Future<String?> _uploadImage(XFile file) async {
    try {
      final uri = Uri.parse('$_base/$_threadId/upload');
      final request = http.MultipartRequest('POST', uri);
      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'image', bytes,
        filename: file.name,
      ));
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

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ลบแชท', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('ข้อความจะหายไปจากหน้าจอคุณเท่านั้น\nทีมสนับสนุนยังคงเห็นข้อความเดิม'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: CColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteChat();
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat() async {
    try {
      await apiDelete(
        '$_base/$_threadId?userId=${widget.customerId}&userRole=customer',
      );
      if (mounted) setState(() => _messages.clear());
    } catch (_) {
      if (mounted) setState(() => _messages.clear());
    }
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
            GestureDetector(
              onTap: _confirmClearChat,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: context.subtleBg, shape: BoxShape.circle),
                child: Icon(Icons.delete_outline_rounded, color: context.muted, size: 18),
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

        // Image preview bar (shows when image is picked)
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
        // Image attach button
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _pickedImage != null ? CColors.orangeLight : context.subtleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _pickedImage != null
                  ? Icons.image_rounded
                  : Icons.add_photo_alternate_rounded,
              color: _pickedImage != null ? CColors.orange : context.muted,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Text input
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
            decoration: BoxDecoration(
              color: context.subtleBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              controller: _ctrl,
              style: TextStyle(fontSize: 14, color: context.fg),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                hintStyle: TextStyle(color: context.muted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Send button
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

// ─── Image Source Bottom Sheet ───────────────────────────────────────────────

class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  const _ImageSourceSheet({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: context.divider, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Text('แนบรูปภาพ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.fg)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _SourceButton(
              icon: Icons.photo_library_rounded,
              label: 'คลังภาพ',
              onTap: () { Navigator.pop(context); onGallery(); },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SourceButton(
              icon: Icons.camera_alt_rounded,
              label: 'ถ่ายรูป',
              onTap: () { Navigator.pop(context); onCamera(); },
            ),
          ),
        ]),
      ]),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: CColors.orangeLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: CColors.orange, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.orange)),
        ]),
      ),
    );
  }
}

// ─── Image Preview Bar ───────────────────────────────────────────────────────

class _ImagePreviewBar extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _ImagePreviewBar({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.card,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(children: [
        // Preview thumbnail (use File for local path)
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(file.path),
            width: 64, height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: CColors.orangeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.image_rounded, color: CColors.orange, size: 28),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('รูปภาพที่เลือก',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.fg)),
              const SizedBox(height: 2),
              Text(file.name,
                style: TextStyle(fontSize: 11, color: context.muted),
                overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
          ),
        ),
      ]),
    );
  }
}

// ─── Chat Bubble ─────────────────────────────────────────────────────────────

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

  Widget _buildNetworkImage(BuildContext context, String url) {
    // Old file-path uploads (Render ephemeral disk) — never try to fetch
    // Catches both '/uploads/support/...' and 'https://.../uploads/support/...'
    if (url.contains('/uploads/')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.image_not_supported_rounded, size: 14, color: CColors.muted),
          SizedBox(width: 6),
          Text('รูปภาพหมดอายุ', style: TextStyle(fontSize: 12, color: CColors.muted)),
        ]),
      );
    }

    final Widget broken = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.image_not_supported_rounded, size: 14, color: CColors.muted),
        SizedBox(width: 6),
        Text('โหลดรูปไม่ได้', style: TextStyle(fontSize: 12, color: CColors.muted)),
      ]),
    );

    // base64 data URI
    if (url.startsWith('data:')) {
      try {
        final parts = url.split(',');
        if (parts.length < 2) return broken;
        final bytes = base64Decode(parts.last);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes,
            width: double.infinity, height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => broken,
          ),
        );
      } catch (_) {
        return broken;
      }
    }

    final fullUrl = url.startsWith('http') ? url : '$kBackendUrl$url';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        fullUrl,
        width: double.infinity, height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: double.infinity, height: 200,
            decoration: BoxDecoration(
              color: CColors.orangeLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
                color: CColors.orange,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => broken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Admin avatar
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
                      style: TextStyle(fontSize: 11, color: CColors.orange, fontWeight: FontWeight.w600)),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  child: GestureDetector(
                    onTap: hasImage
                        ? () => _viewFullImage(context, imageUrl!)
                        : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: hasImage ? 6 : 14,
                        vertical: hasImage ? 6 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? CColors.orange : context.card,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isMe ? 18 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 6),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasImage)
                            _buildNetworkImage(context, imageUrl!),
                          if (hasImage && message.isNotEmpty)
                            const SizedBox(height: 6),
                          if (message.isNotEmpty)
                            Text(message,
                              style: TextStyle(
                                fontSize: 14,
                                color: isMe ? Colors.white : context.fg,
                                height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(time,
                    style: TextStyle(fontSize: 11, color: context.muted)),
                ),
              ],
            ),
          ),

          // My avatar
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

  void _viewFullImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullImageViewer(url: url),
      ),
    );
  }
}

// ─── Full Image Viewer ────────────────────────────────────────────────────────

class _FullImageViewer extends StatelessWidget {
  final String url;
  const _FullImageViewer({required this.url});

  Widget _buildImage() {
    if (url.startsWith('data:')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return InteractiveViewer(
          child: Image.memory(bytes, fit: BoxFit.contain),
        );
      } catch (_) {}
    }
    final fullUrl = url.startsWith('http') ? url : '$kBackendUrl$url';
    return InteractiveViewer(
      child: Image.network(
        fullUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.broken_image_rounded, color: Colors.white60, size: 48),
          SizedBox(height: 12),
          Text('โหลดรูปไม่ได้', style: TextStyle(color: Colors.white60)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(child: _buildImage()),
    );
  }
}
