import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../app_settings.dart';
import '../../main.dart';
import '../../config.dart';
import 'chat_screen.dart';

class RiderConversationsScreen extends StatefulWidget {
  final String riderId;
  final String riderName;

  const RiderConversationsScreen({
    super.key,
    required this.riderId,
    required this.riderName,
  });

  @override
  State<RiderConversationsScreen> createState() => _RiderConversationsScreenState();
}

class _RiderConversationsScreenState extends State<RiderConversationsScreen> {
  static String get _base => '$kBackendUrl/api/chat';

  List<Map<String, dynamic>> _convs = [];
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/conversations/rider/${widget.riderId}'),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() {
          _convs = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(dynamic isoStr) {
    if (isoStr == null) return '';
    final dt = DateTime.tryParse(isoStr.toString())?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.rBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: RiderColors.blue))
          : _convs.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 72, height: 72,
                      decoration: const BoxDecoration(
                        color: RiderColors.blueLight, shape: BoxShape.circle),
                      child: const Icon(Icons.chat_bubble_outline_rounded,
                        color: RiderColors.blue, size: 34),
                    ),
                    const SizedBox(height: 16),
                    Text(rt('ยังไม่มีการสนทนา', 'No conversations yet'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.rFg)),
                    const SizedBox(height: 6),
                    Text(rt('แชทจะปรากฏเมื่อคุณรับออเดอร์', 'Chats will appear when you accept orders'),
                      style: TextStyle(color: context.rMuted, fontSize: 13)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: RiderColors.blue,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _convs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = _convs[i];
                      final lastMsg = c['last_msg'] as String?;
                      final lastSender = c['last_sender'] as String?;
                      final msgCount = (c['msg_count'] ?? 0) as int;
                      return Container(
                        decoration: BoxDecoration(
                          color: context.rCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.rDiv, width: 1),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 48, height: 48,
                          decoration: const BoxDecoration(
                            color: RiderColors.blueLight, shape: BoxShape.circle),
                          child: const Icon(Icons.person_rounded, color: RiderColors.blue, size: 24),
                        ),
                        title: Row(children: [
                          Expanded(
                            child: Text(
                              c['customer_name'] ?? rt('ลูกค้า', 'Customer'),
                              style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: context.rFg),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(c['last_msg_at']),
                            style: TextStyle(fontSize: 11, color: context.rMuted),
                          ),
                        ]),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              c['store_name'] ?? '',
                              style: const TextStyle(fontSize: 12, color: RiderColors.blue),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            if (lastMsg != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                lastSender != null ? '$lastSender: $lastMsg' : lastMsg,
                                style: TextStyle(fontSize: 12, color: context.rMuted),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ] else if (msgCount == 0)
                              Text(rt('ยังไม่มีข้อความ', 'No messages yet'),
                                style: TextStyle(fontSize: 12, color: context.rMuted, fontStyle: FontStyle.italic)),
                          ],
                        ),
                        trailing: msgCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: RiderColors.blueLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('$msgCount',
                                  style: const TextStyle(fontSize: 11, color: RiderColors.blue, fontWeight: FontWeight.w700)),
                              )
                            : null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RiderChatScreen(
                              orderId: c['order_id'].toString(),
                              riderId: widget.riderId,
                              riderName: widget.riderName,
                              customerName: c['customer_name'] ?? 'ลูกค้า',
                              storeName: c['store_name'] ?? 'ร้านค้า',
                            ),
                          ),
                        ),
                      ),
                      );
                    },
                  ),
                ),
    );
  }
}
