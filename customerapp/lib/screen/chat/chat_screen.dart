import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
  XFile? _pickedImage;

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

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('แนบรูปภาพ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CColors.text)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _SourceButton(
              icon: Icons.photo_library_rounded,
              label: 'คลังภาพ',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            )),
            const SizedBox(width: 12),
            Expanded(child: _SourceButton(
              icon: Icons.camera_alt_rounded,
              label: 'ถ่ายรูป',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            )),
          ]),
        ]),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file != null && mounted) setState(() => _pickedImage = file);
  }

  Future<String?> _uploadImage(XFile file) async {
    try {
      final uri = Uri.parse('$_base/${widget.orderId}/upload');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'image', await file.readAsBytes(),
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
      if (imageToUpload != null) imageUrl = await _uploadImage(imageToUpload);

      await apiPost(
        '$_base/${widget.orderId}',
        jsonEncode({
          'userId': widget.customerId,
          'userRole': 'customer',
          'senderName': widget.customerName,
          'message': text,
          'chatType': widget.chatType,
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
                          imageUrl: msg['image_url'] as String?,
                          senderName: msg['sender_name'] ?? '',
                          time: _formatTime(msg['created_at']),
                          isMe: isMe,
                          roleColor: _roleColor(role),
                          roleIcon: _roleIcon(role),
                        );
                      },
                    ),
        ),

        // Image preview bar
        if (_pickedImage != null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_pickedImage!.path),
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
                child: Text(_pickedImage!.name,
                  style: const TextStyle(fontSize: 12, color: CColors.muted),
                  overflow: TextOverflow.ellipsis),
              ),
              GestureDetector(
                onTap: () => setState(() => _pickedImage = null),
                child: Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                ),
              ),
            ]),
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
        // Image attach button
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _pickedImage != null ? CColors.orangeLight : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _pickedImage != null ? Icons.image_rounded : Icons.add_photo_alternate_rounded,
              color: _pickedImage != null ? CColors.orange : CColors.muted,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(22)),
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(fontSize: 14, color: CColors.text),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                hintStyle: TextStyle(color: CColors.muted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
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

// ─── Image source picker ──────────────────────────────────────────────────────

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
        decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: CColors.orange, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CColors.orange)),
        ]),
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String message;
  final String? imageUrl;
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
    this.imageUrl,
  });

  Widget _buildImage(BuildContext context) {
    final url = imageUrl!;

    final Widget broken = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.image_not_supported_rounded, size: 14, color: CColors.muted),
        SizedBox(width: 6),
        Text('โหลดรูปไม่ได้', style: TextStyle(fontSize: 12, color: CColors.muted)),
      ]),
    );

    // Old disk-path URLs (ephemeral — files are gone)
    if (url.contains('/uploads/')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.image_not_supported_rounded, size: 14, color: CColors.muted),
          SizedBox(width: 6),
          Text('รูปภาพหมดอายุ', style: TextStyle(fontSize: 12, color: CColors.muted)),
        ]),
      );
    }

    // base64 data URI
    if (url.startsWith('data:')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return GestureDetector(
          onTap: () => _viewFullImage(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes,
              width: double.infinity, height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => broken,
            ),
          ),
        );
      } catch (_) {
        return broken;
      }
    }

    final fullUrl = url.startsWith('http') ? url : '$kBackendUrl$url';
    return GestureDetector(
      onTap: () => _viewFullImage(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          fullUrl,
          width: double.infinity, height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              width: double.infinity, height: 200,
              decoration: BoxDecoration(color: CColors.orangeLight, borderRadius: BorderRadius.circular(12)),
              child: Center(child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
                color: CColors.orange, strokeWidth: 2,
              )),
            );
          },
          errorBuilder: (_, _, _) => broken,
        ),
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

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

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
              decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.15), shape: BoxShape.circle),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: hasImage ? 6 : 14,
                      vertical: hasImage ? 6 : 10,
                    ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasImage) _buildImage(context),
                        if (hasImage && message.isNotEmpty) const SizedBox(height: 6),
                        if (message.isNotEmpty)
                          Text(message,
                            style: TextStyle(fontSize: 14, color: isMe ? Colors.white : CColors.text, height: 1.4)),
                      ],
                    ),
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

// ─── Full image viewer ────────────────────────────────────────────────────────

class _FullImageViewer extends StatelessWidget {
  final String url;
  const _FullImageViewer({required this.url});

  Widget _buildImage() {
    if (url.startsWith('data:')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain));
      } catch (_) {}
    }
    final fullUrl = url.startsWith('http') ? url : '$kBackendUrl$url';
    return InteractiveViewer(
      child: Image.network(
        fullUrl, fit: BoxFit.contain,
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
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
      body: Center(child: _buildImage()),
    );
  }
}
