import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/chat.dart';
import '../../core/models/message.dart';
import '../../core/services/archive_service.dart';
import '../../core/services/wa_bridge_service.dart';
import '../../core/services/wa_shell_store.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/wa_icons.dart';
import '../chat_detail/chat_detail_screen.dart';

/// WhatsApp-style global search: contacts, nicknames, groups, channels, chats, messages.
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
      context.read<WaBridgeService>().fetchContacts(force: true);
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
    _debounce = Timer(const Duration(milliseconds: 160), () => _run(raw));
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

  bool _looksChannel(Chat c) {
    final id = c.id.toLowerCase();
    final title = c.title.toLowerCase();
    return id.contains('newsletter') ||
        id.contains('@broadcast') ||
        title.contains('channel') ||
        title.startsWith('#');
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
    final shell = context.watch<WaShellStore>();
    final q = _query.toLowerCase();

    final matchedChats = q.isEmpty
        ? <Chat>[]
        : archive.chats
            .where(
              (c) =>
                  c.title.toLowerCase().contains(q) ||
                  (c.peerPhone ?? '').contains(q) ||
                  (c.lastMessage ?? '').toLowerCase().contains(q),
            )
            .toList();

    final groups = matchedChats.where((c) => c.isGroup && !_looksChannel(c)).toList();
    final channels = matchedChats.where(_looksChannel).toList();
    final dmChats = matchedChats
        .where((c) => !c.isGroup && !_looksChannel(c))
        .toList();

    final communityHits = q.isEmpty
        ? <ShellCommunity>[]
        : shell.communities
            .where((c) => c.name.toLowerCase().contains(q))
            .toList();

    final chatPhones = {
      for (final c in matchedChats)
        if ((c.peerPhone ?? '').isNotEmpty) c.peerPhone!,
    };
    final nickHits = _contactHits
        .where((c) => c.phone.isEmpty || !chatPhones.contains(c.phone))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: bridge.isLinked
                ? 'Search name or number'
                : 'Search…',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: _onChanged,
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: () {
                _ctrl.clear();
                _run('');
              },
              icon: Icon(Icons.close, color: AppColors.textSecondary),
            ),
        ],
      ),
      body: _query.isEmpty
          ? _EmptyHint(linked: bridge.isLinked, contactCount: bridge.contacts.length)
          : _busy
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    if (nickHits.isNotEmpty) ...[
                      const _SectionLabel('Contacts'),
                      for (final c in nickHits)
                        _ResultTile(
                          name: c.displayName,
                          subtitle: [
                            if (c.pushName.isNotEmpty &&
                                c.pushName != c.displayName)
                              '~ ${c.pushName}',
                            if (c.phone.isNotEmpty) '+${c.phone}',
                          ].join(' · '),
                          onTap: () => _openContact(c),
                        ),
                    ],
                    if (groups.isNotEmpty) ...[
                      const _SectionLabel('Groups'),
                      for (final chat in groups)
                        _ResultTile(
                          name: chat.title,
                          subtitle: chat.lastMessage ?? 'Group',
                          colorHex: chat.avatarColor,
                          onTap: () => _openChat(chat),
                        ),
                    ],
                    if (channels.isNotEmpty || communityHits.isNotEmpty) ...[
                      const _SectionLabel('Channels'),
                      for (final chat in channels)
                        _ResultTile(
                          name: chat.title,
                          subtitle: chat.lastMessage ?? 'Channel',
                          colorHex: chat.avatarColor,
                          onTap: () => _openChat(chat),
                        ),
                      for (final c in communityHits)
                        _ResultTile(
                          name: c.name,
                          subtitle: 'Community',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Community: ${c.name}')),
                            );
                          },
                        ),
                    ],
                    if (dmChats.isNotEmpty) ...[
                      const _SectionLabel('Chats'),
                      for (final chat in dmChats)
                        _ResultTile(
                          name: chat.title,
                          subtitle: chat.lastMessage ?? '',
                          colorHex: chat.avatarColor,
                          onTap: () => _openChat(chat),
                        ),
                    ],
                    if (_messages.isNotEmpty) ...[
                      const _SectionLabel('Messages'),
                      for (final m in _messages)
                        Builder(
                          builder: (context) {
                            final chat = _chatFor(archive, m.chatId);
                            final title = chat?.title ?? 'Chat';
                            return _ResultTile(
                              name: title,
                              subtitle: m.body,
                              colorHex: chat?.avatarColor,
                              onTap: chat == null ? null : () => _openChat(chat),
                            );
                          },
                        ),
                    ],
                    if (nickHits.isEmpty &&
                        groups.isEmpty &&
                        channels.isEmpty &&
                        communityHits.isEmpty &&
                        dmChats.isEmpty &&
                        _messages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 64),
                        child: Center(
                          child: Text(
                            'No results found',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.linked, required this.contactCount});
  final bool linked;
  final int contactCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WaIcon(
              WaIcons.search,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              linked
                  ? 'Search contacts, nicknames, groups, channels and messages'
                  : 'Search chats and messages.\nConnect WhatsApp in Settings for contact nicknames.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (linked && contactCount > 0) ...[
              const SizedBox(height: 10),
              Text(
                '$contactCount contacts loaded',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.name,
    required this.subtitle,
    this.colorHex,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final String? colorHex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: AvatarCircle(name: name, colorHex: colorHex, size: 48),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
    );
  }
}
