import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/chat.dart';
import '../../core/models/message.dart';
import '../../core/services/archive_service.dart';
import '../../core/services/wa_bridge_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/wa_icons.dart';
import '../chat_detail/chat_detail_screen.dart';

/// WhatsApp-style search: live nickname suggestions + chats + messages.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  List<Message> _messages = [];
  List<WaContact> _contactHits = [];
  bool _busy = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaBridgeService>().fetchContacts();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () => _run(raw));
  }

  Future<void> _run(String q) async {
    final query = q.trim();
    setState(() {
      _query = query;
      _busy = true;
    });
    final archive = context.read<ArchiveService>();
    final bridge = context.read<WaBridgeService>();
    if (query.isNotEmpty && bridge.isLinked) {
      await bridge.fetchContacts();
    }
    final msgs =
        query.isEmpty ? <Message>[] : await archive.searchMessages(query);
    final contactHits =
        query.isEmpty ? <WaContact>[] : bridge.filterContacts(query);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _contactHits = contactHits;
      _busy = false;
    });
  }

  Chat? _chatFor(ArchiveService archive, String chatId) {
    for (final c in archive.chats) {
      if (c.id == chatId) return c;
    }
    return null;
  }

  Future<void> _openContact(WaContact c) async {
    final archive = context.read<ArchiveService>();
    final chat = await archive.openOrCreatePeerChat(
      title: c.displayName,
      peerPhone: c.phone,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatDetailScreen(chat: chat),
      ),
    );
  }

  Future<void> _openChat(Chat chat) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatDetailScreen(chat: chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final archive = context.watch<ArchiveService>();
    final bridge = context.watch<WaBridgeService>();
    final q = _query.toLowerCase();
    final chats = q.isEmpty
        ? <Chat>[]
        : archive.chats
            .where(
              (c) =>
                  c.title.toLowerCase().contains(q) ||
                  (c.peerPhone ?? '').contains(q) ||
                  (c.lastMessage ?? '').toLowerCase().contains(q),
            )
            .toList();

    // Prefer contact nicknames that are not already in chat list.
    final chatPhones = {
      for (final c in chats)
        if ((c.peerPhone ?? '').isNotEmpty) c.peerPhone!,
    };
    final nickHits = _contactHits
        .where((c) => c.phone.isEmpty || !chatPhones.contains(c.phone))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: bridge.isLinked
                ? 'Search name, number, messages'
                : 'Search chats & messages',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  bridge.isLinked
                      ? 'Type a WhatsApp nickname or number — suggestions appear live.'
                      : 'Link WhatsApp in Settings → Connect to search contacts by nickname.\nLocal chats still searchable.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : _busy
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                  children: [
                    if (nickHits.isNotEmpty) ...[
                      const _Label('Contacts'),
                      for (final c in nickHits)
                        ListTile(
                          leading: AvatarCircle(
                            name: c.displayName,
                            size: 44,
                          ),
                          title: Text(
                            c.displayName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            c.phone.isNotEmpty
                                ? '+${c.phone}'
                                : (c.pushName.isNotEmpty
                                    ? c.pushName
                                    : 'WhatsApp contact'),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          onTap: () => _openContact(c),
                        ),
                    ],
                    if (chats.isNotEmpty) ...[
                      const _Label('Chats'),
                      for (final chat in chats)
                        ListTile(
                          leading: AvatarCircle(
                            name: chat.title,
                            colorHex: chat.avatarColor,
                            size: 44,
                          ),
                          title: Text(
                            chat.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            chat.lastMessage ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          onTap: () => _openChat(chat),
                        ),
                    ],
                    if (_messages.isNotEmpty) ...[
                      const _Label('Messages'),
                      for (final m in _messages)
                        Builder(
                          builder: (context) {
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
                                  : () => _openChat(chat),
                            );
                          },
                        ),
                    ],
                    if (nickHits.isEmpty &&
                        chats.isEmpty &&
                        _messages.isEmpty)
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
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
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
