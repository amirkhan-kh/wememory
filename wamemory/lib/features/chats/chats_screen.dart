import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/archive_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/chat_list_tile.dart';
import '../../widgets/wa_icons.dart';
import '../chat_detail/chat_detail_screen.dart';
import '../deleted/deleted_screen.dart';
import '../home/home_shell.dart';
import '../search/search_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  /// 0 all · 1 unread · 2 groups
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    final archive = context.watch<ArchiveService>();
    final s = S.from(context.watch<LocaleController>());
    final chats = archive.chats.where((c) {
      if (_filter == 1 && c.unreadCount <= 0) return false;
      if (_filter == 2 && !c.isGroup) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.appName,
                      style: TextStyle(
                        color: AppColors.brandTitle,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: s.deleted,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeletedScreen(),
                        ),
                      );
                    },
                    icon: const WaIcon(WaIcons.deleted, size: 22),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SearchScreen(),
                        ),
                      );
                    },
                    icon: const WaIcon(WaIcons.search, size: 22),
                  ),
                  IconButton(
                    onPressed: () => openSettings(context),
                    icon: const WaIcon(WaIcons.settings, size: 22),
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Material(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        WaIcon(
                          WaIcons.notify,
                          size: 22,
                          color: AppColors.warning,
                          secondaryColor: AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.enableNotificationsBody,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await archive.openNotificationSettings();
                            await Future<void>.delayed(
                              const Duration(seconds: 1),
                            );
                            await archive.refreshListenerStatus();
                          },
                          child: Text(
                            s.enable,
                            style: TextStyle(color: AppColors.accentBright),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Material(
                color: AppColors.searchField,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SearchScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        const WaIcon(WaIcons.search, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          s.searchHint,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == 0,
                    onTap: () => setState(() => _filter = 0),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Unread',
                    selected: _filter == 1,
                    onTap: () => setState(() => _filter = 1),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Groups',
                    selected: _filter == 2,
                    onTap: () => setState(() => _filter = 2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: chats.isEmpty
                  ? Center(
                      child: Text(
                        s.noChats,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      itemCount: chats.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 76,
                        color: AppColors.divider,
                      ),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_chats',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
          );
        },
        backgroundColor: AppColors.accent,
        elevation: 3,
        child: const WaIcon(
          WaIcons.plus,
          size: 26,
          color: Colors.white,
          secondaryColor: Colors.white,
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, ArchiveService archive) {
    final s = S.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const WaIcon(WaIcons.refresh, size: 22),
              title: Text(s.refreshArchive),
              onTap: () {
                archive.refresh();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const WaIcon(WaIcons.deleted, size: 22),
              title: Text(s.deletedMessages),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DeletedScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const WaIcon(WaIcons.settings, size: 22),
              title: Text(s.settings),
              onTap: () {
                Navigator.pop(context);
                openSettings(context);
              },
            ),
            ListTile(
              leading: const WaIcon(WaIcons.lab, size: 22),
              title: const Text('Simulate WhatsApp message'),
              onTap: () {
                Navigator.pop(context);
                _simulate(context, archive);
              },
            ),
          ],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    return Material(
      color: selected ? AppColors.accent.withValues(alpha: 0.22) : AppColors.panel,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.accentBright : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
