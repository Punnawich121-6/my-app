import 'package:flutter/material.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  final String riderName;
  const ChatScreen({super.key, this.riderName = 'Robert Fox'});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<_ChatMsg> _messages = [
    _ChatMsg(
        text: "Hi! I'm on my way to pick up your order.",
        isSent: false,
        time: '10:22 AM'),
    _ChatMsg(
        text: "Great! How long will it take?",
        isSent: true,
        time: '10:23 AM'),
    _ChatMsg(
        text: "About 15 minutes. Traffic is light today.",
        isSent: false,
        time: '10:23 AM'),
    _ChatMsg(
        text: "Perfect, I'll be waiting. Thank you!",
        isSent: true,
        time: '10:24 AM'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMsg(text: text, isSent: true, time: _nowTime()));
      _ctrl.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _nowTime() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
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
            // Close button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: CColors.text, size: 18),
              ),
            ),
            const Expanded(
              child: Text('Robert Fox',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: CColors.text)),
            ),
            // Rider avatar
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                  color: CColors.orangeLight, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded,
                  color: CColors.orange, size: 20),
            ),
          ]),
        ),
      ),
      body: Column(
        children: [
          // ── Message list ───────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + 1, // +1 for time label
              itemBuilder: (_, i) {
                if (i == 0) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('Today 10:22 AM',
                          style:
                              TextStyle(fontSize: 12, color: CColors.muted)),
                    ),
                  );
                }
                final msg = _messages[i - 1];
                return _MessageBubble(msg: msg);
              },
            ),
          ),

          // ── Input bar ──────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: Row(
              children: [
                // Emoji icon
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: CColors.orangeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_emotions_outlined,
                      color: CColors.orange, size: 20),
                ),
                const SizedBox(width: 10),
                // Text field
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      style:
                          const TextStyle(fontSize: 14, color: CColors.text),
                      decoration: const InputDecoration(
                        hintText: 'Write something...',
                        hintStyle:
                            TextStyle(color: CColors.muted, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Send button
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                        color: CColors.orange, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isSent;
  final String time;
  const _ChatMsg({required this.text, required this.isSent, required this.time});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isSent) ...[
            // Rider avatar
            Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                  color: CColors.orangeLight, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded,
                  color: CColors.orange, size: 18),
            ),
          ],
          Column(
            crossAxisAlignment: msg.isSent
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: msg.isSent
                      ? CColors.orange
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft:
                        Radius.circular(msg.isSent ? 18 : 4),
                    bottomRight:
                        Radius.circular(msg.isSent ? 4 : 18),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        msg.isSent ? Colors.white : CColors.text,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(msg.time,
                  style: const TextStyle(
                      fontSize: 11, color: CColors.muted)),
            ],
          ),
          if (msg.isSent) ...[
            // Sender avatar
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                  color: CColors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
