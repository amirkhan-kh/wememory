import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/chat.dart';
import '../../core/models/message.dart';
import '../../core/services/archive_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.chat});

  final Chat chat;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<Message> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final archive = context.read<ArchiveService>();
    final msgs = await archive.messagesFor(widget.chat.id);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SurrealBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.appBar.withValues(alpha: 0.72),
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarCircle(
              name: widget.chat.title,
              colorHex: widget.chat.avatarColor,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Archived by WAMemory',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [
          WaIcon(WaIcons.video, size: 22),
          SizedBox(width: 14),
          WaIcon(WaIcons.call, size: 22),
          SizedBox(width: 14),
          WaIcon(WaIcons.more, size: 22),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => MessageBubble(message: _messages[i]),
                  ),
          ),
          _ComposerBar(
            onSend: (text) async {
              final archive = context.read<ArchiveService>();
              await archive.simulateIncoming(title: widget.chat.title, body: text);
              await _load();
            },
          ),
        ],
      ),
    ),
    );
  }
}

class _ComposerBar extends StatefulWidget {
  const _ComposerBar({required this.onSend});
  final ValueChanged<String> onSend;

  @override
  State<_ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<_ComposerBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const WaIcon(
                        WaIcons.plus,
                        size: 22,
                        color: AppColors.accentBright,
                        secondaryColor: AppColors.accentBright,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Type here',
                          border: InputBorder.none,
                          filled: false,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const WaIcon(WaIcons.camera, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBright.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const WaIcon(
                  WaIcons.send,
                  size: 20,
                  color: Colors.white,
                  secondaryColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }
}
