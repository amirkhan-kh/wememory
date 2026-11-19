import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/chat.dart';
import '../../core/services/archive_service.dart';
import '../../core/services/wa_shell_store.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';
import '../chat_detail/chat_detail_screen.dart';
import '../search/search_screen.dart';

/// WhatsApp-like Calls tab — local call log + open archived chat.
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.from(context.watch<LocaleController>());
    final shell = context.watch<WaShellStore>();
    final archive = context.watch<ArchiveService>();

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_calls',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            );
          },
          backgroundColor: AppColors.accent,
          child: const WaIcon(
            WaIcons.call,
            size: 24,
            color: Colors.white,
            secondaryColor: Colors.white,
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.calls,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  s.callsBody,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              Expanded(
                child: shell.calls.isEmpty
                    ? _FavouritesEmpty(
                        chats: archive.chats,
                        s: s,
                        onPick: (chat) => _startCall(
                          context,
                          shell,
                          chat,
                          video: false,
                          s: s,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: shell.calls.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 76,
                          color: AppColors.divider,
                        ),
                        itemBuilder: (context, i) {
                          final call = shell.calls[i];
                          final match = archive.chats.where(
                            (c) => c.id == call.chatId,
                          );
                          final chat = match.isEmpty ? null : match.first;
                          final when = DateTime.fromMillisecondsSinceEpoch(
                            call.atMs,
                          );
                          return ListTile(
                            onTap: () {
                              if (chat != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ChatDetailScreen(chat: chat),
                                  ),
                                );
                              }
                            },
                            leading: AvatarCircle(
                              name: call.title,
                              colorHex: chat?.avatarColor ?? '#00A884',
                              size: 52,
                            ),
                            title: Text(
                              call.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                WaIcon(
                                  call.outgoing
                                      ? WaIcons.refresh
                                      : WaIcons.call,
                                  size: 14,
                                  color: call.outgoing
                                      ? AppColors.accentBright
                                      : AppColors.warning,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${call.video ? s.video : s.voice} · '
                                  '${when.hour.toString().padLeft(2, '0')}:'
                                  '${when.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                if (chat == null) return;
                                _startCall(
                                  context,
                                  shell,
                                  chat,
                                  video: call.video,
                                  s: s,
                                );
                              },
                              icon: WaIcon(
                                call.video ? WaIcons.video : WaIcons.call,
                                size: 22,
                                color: AppColors.accentBright,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> startCallFromChat({
    required BuildContext context,
    required Chat chat,
    required bool video,
  }) async {
    final shell = context.read<WaShellStore>();
    final s = S.of(context);
    await _startCall(context, shell, chat, video: video, s: s);
  }

  static Future<void> _startCall(
    BuildContext context,
    WaShellStore shell,
    Chat chat, {
    required bool video,
    required S s,
  }) async {
    await shell.logCall(
      title: chat.title,
      chatId: chat.id,
      video: video,
      outgoing: true,
    );
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WaIcon(
                video ? WaIcons.video : WaIcons.call,
                size: 40,
                color: AppColors.accentBright,
                glow: true,
              ),
              const SizedBox(height: 12),
              Text(
                chat.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.callLoggedBody,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatDetailScreen(chat: chat),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: Text(s.openChat),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavouritesEmpty extends StatelessWidget {
  const _FavouritesEmpty({
    required this.chats,
    required this.s,
    required this.onPick,
  });

  final List<Chat> chats;
  final S s;
  final void Function(Chat chat) onPick;

  @override
  Widget build(BuildContext context) {
    if (chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WaIcon(
                WaIcons.call,
                size: 56,
                color: AppColors.accentBright,
                glow: true,
              ),
              const SizedBox(height: 16),
              Text(
                s.noCalls,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.noCallsHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            s.favourites,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...chats.take(12).map(
              (chat) => ListTile(
                onTap: () => onPick(chat),
                leading: AvatarCircle(
                  name: chat.title,
                  colorHex: chat.avatarColor,
                  size: 52,
                ),
                title: Text(
                  chat.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  s.tapToCall,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                trailing: const WaIcon(
                  WaIcons.call,
                  size: 22,
                  color: AppColors.accentBright,
                ),
              ),
            ),
      ],
    );
  }
}
