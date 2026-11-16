import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/archive_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/chat_list_tile.dart';
import '../../widgets/perspective_scroll_list.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';
import '../chat_detail/chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archive = context.watch<ArchiveService>();
    final chats = archive.chats.where((c) {
      if (_query.isEmpty) return true;
      return c.title.toLowerCase().contains(_query.toLowerCase()) ||
          (c.lastMessage ?? '').toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'WAMemory',
                        style: TextStyle(
                          color: AppColors.accentBright,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          shadows: [
                            Shadow(
                              color: Color(0x6625D366),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showMenu(context, archive),
                      icon: const WaIcon(WaIcons.more, size: 22),
                    ),
                  ],
                ),
              ),
              if (!archive.listenerEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: GlassPanel(
                    radius: 16,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const WaIcon(
                          WaIcons.notify,
                          size: 22,
                          color: AppColors.warning,
                          secondaryColor: AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Enable Notification Access to archive WhatsApp messages automatically.',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await archive.openNotificationSettings();
                            await Future<void>.delayed(const Duration(seconds: 1));
                            await archive.refreshListenerStatus();
                          },
                          child: const Text(
                            'Enable',
                            style: TextStyle(color: AppColors.accentBright),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: GlassPanel(
                  radius: 22,
                  blur: 10,
                  opacity: 0.4,
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search chats & messages',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: WaIcon(WaIcons.search, size: 20),
                      ),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              _StoriesRow(names: chats.take(6).map((c) => c.title).toList()),
              Expanded(
                child: chats.isEmpty
                    ? const Center(
                        child: Text(
                          'No archived chats yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : PerspectiveScrollList(
                        itemCount: chats.length,
                        itemBuilder: (context, i) {
                          final chat = chats[i];
                          return ChatListTile(
                            chat: chat,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(chat: chat),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _simulate(context, archive),
            backgroundColor: AppColors.accent,
            child: const WaIcon(
              WaIcons.plus,
              size: 26,
              color: Colors.white,
              secondaryColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, ArchiveService archive) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassPanel(
          radius: 20,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const WaIcon(
                    WaIcons.refresh,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text('Refresh archive'),
                  onTap: () {
                    archive.refresh();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const WaIcon(
                    WaIcons.lab,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text('Simulate WhatsApp message'),
                  onTap: () {
                    Navigator.pop(context);
                    _simulate(context, archive);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _simulate(BuildContext context, ArchiveService archive) async {
    await archive.simulateIncoming(
      title: 'Demo Contact',
      body: 'Test message at ${TimeOfDay.now().format(context)}',
    );
  }
}

class _StoriesRow extends StatelessWidget {
  const _StoriesRow({required this.names});
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: names.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  GlassPanel(
                    radius: 28,
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(child: WaIcon(WaIcons.search, size: 22)),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Search',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            );
          }
          final name = names[i - 1];
          final short = name.split(' ').first;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        AppColors.accentBright,
                        AppColors.auroraViolet,
                        AppColors.auroraTeal,
                        AppColors.accentBright,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBright.withValues(alpha: 0.25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.panel,
                    child: Text(
                      short.isNotEmpty ? short[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.accentBright,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 64,
                  child: Text(
                    short,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
