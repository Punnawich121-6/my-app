import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';

class _Msg {
  final String text;
  final bool isMe;
  final DateTime time;
  const _Msg({required this.text, required this.isMe, required this.time});
}

class ChatScreen extends StatefulWidget {
  final String name;
  final String? otherAvatarUrl;
  final String? myAvatarUrl;

  const ChatScreen({
    super.key,
    this.name = 'Robert Fox',
    this.otherAvatarUrl,
    this.myAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  final _messages = [
    _Msg(text: 'Are you coming?', isMe: true, time: DateTime(2024, 1, 1, 20, 10)),
    _Msg(text: 'Hay, Congratulation for order', isMe: false, time: DateTime(2024, 1, 1, 20, 11)),
    _Msg(text: 'Hey Where are you now?', isMe: true, time: DateTime(2024, 1, 1, 20, 11)),
    _Msg(text: "I'm Coming , just wait ...", isMe: false, time: DateTime(2024, 1, 1, 20, 12)),
    _Msg(text: 'Hurry Up, Man', isMe: true, time: DateTime(2024, 1, 1, 20, 12)),
  ];

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: text, isMe: true, time: DateTime.now()));
      _ctrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFF3F3F3), shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 18, color: AppColors.text),
          ),
        ),
        title: Text(
          widget.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.text),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildBubble(_messages[i]),
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(_Msg msg) {
    final timeStr = DateFormat('h:mm a').format(msg.time);
    final otherAvatar = widget.otherAvatarUrl ??
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face';
    final myAvatar = widget.myAvatarUrl ??
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!msg.isMe) ...[
                CircleAvatar(radius: 18, backgroundImage: NetworkImage(otherAvatar)),
                const SizedBox(width: 8),
              ],
              if (msg.isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 4),
                  child: Icon(Icons.done_all_rounded, size: 14, color: AppColors.orange.withValues(alpha: 0.8)),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: msg.isMe ? AppColors.orange : const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(msg.isMe ? 20 : 4),
                      bottomRight: Radius.circular(msg.isMe ? 4 : 20),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: msg.isMe ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (msg.isMe) ...[
                const SizedBox(width: 8),
                CircleAvatar(radius: 18, backgroundImage: NetworkImage(myAvatar)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sentiment_satisfied_alt_outlined, color: AppColors.muted, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Write somethings',
                        hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _send,
            child: const Icon(Icons.send_rounded, color: AppColors.orange, size: 30),
          ),
        ],
      ),
    );
  }
}
