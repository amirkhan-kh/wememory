import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/chat.dart';
import '../../core/models/message.dart';
import '../../core/services/archive_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/surreal_background.dart'; // GlassPanel
import '../../widgets/wa_icons.dart';
import '../chat_detail/chat_detail_screen.dart';

/// WhatsApp-style global search across chat titles and message bodies.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  List<Message> _messages = [];
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _run(String q) async {
    setState(() {
      _query = q.trim();
      _busy = true;
    });
    final archive = context.read<ArchiveService>();
    final msgs = _query.isEmpty
        ? <Message>[]
        : await archive.searchMessages(_query);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _busy = false;
    });
  }

  Chat? _chatFor(ArchiveService archive, String chatId) {
    for (final c in archive.chats) {
      if (c.id == chatId) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final archive = context.watch<ArchiveService>();
    final q = _query.toLowerCase();
    final chats = q.isEmpty
        ? <Chat>[]
        : archive.chats
            .where(
              (c) =>
                  c.title.toLowerCase().contains(q) ||
                  (c.lastMessage ?? '').toLowerCase().contains(q),
            )
            .toList();

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Search chats and messages',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
            ),
            onChanged: (v) {
              _run(v);
            },
          ),
          actions: [
            IconButton(
              onPressed: () {
                _ctrl.clear();
                _run('');
              },
              icon: const WaIcon(WaIcons.refresh, size: 20),
            ),
          ],
        ),
        body: _query.isEmpty
            ? const Center(
                child: Text(
                  'Search contacts and message text',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : _busy
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (chats.isNotEmpty) ...[
                        const _Label('Chats'),
                        GlassPanel(
                          radius: 16,
                          child: Column(
                            children: [
                              for (var i = 0; i < chats.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    color: AppColors.divider,
                                  ),
                                ListTile(
                                  leading: AvatarCircle(
                                    name: chats[i].title,
                                    colorHex: chats[i].avatarColor,
                                    size: 44,
                                  ),
                                  title: Text(
                                    chats[i].title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    chats[i].lastMessage ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            ChatDetailScreen(chat: chats[i]),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (_messages.isNotEmpty) ...[
                        const _Label('Messages'),
                        GlassPanel(
                          radius: 16,
                          child: Column(
                            children: [
                              for (var i = 0; i < _messages.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    color: AppColors.divider,
                                  ),
                                Builder(
                                  builder: (context) {
                                    final m = _messages[i];
                                    final chat = _chatFor(archive, m.chatId);
                                    final title = chat?.title ?? 'Chat';
                                    return ListTile(
                                      leading: AvatarCircle(
                                        name: title,
                                        colorHex: chat?.avatarColor,
                                        size: 44,
                                      ),
                                      title: Text(
                                        title,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        m.body,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      onTap: chat == null
                                          ? null
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      ChatDetailScreen(
                                                    chat: chat,
                                                  ),
                                                ),
                                              );
                                            },
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (chats.isEmpty && _messages.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(
                            child: Text(
                              'No results',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
