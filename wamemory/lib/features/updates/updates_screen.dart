import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/archive_service.dart';
import '../../core/services/profile_store.dart';
import '../../core/services/wa_shell_store.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';
import '../chat_detail/chat_detail_screen.dart';

/// WhatsApp-like Updates (Status + Channels) — local archive shell.
class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.from(context.watch<LocaleController>());
    final profile = context.watch<ProfileStore>();
    final shell = context.watch<WaShellStore>();
    final archive = context.watch<ArchiveService>();
    final recent = archive.chats.take(8).toList();

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.updates,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: s.searchHint,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.statusSearchHint)),
                          );
                        },
                        icon: const WaIcon(WaIcons.search, size: 22),
                      ),
                      IconButton(
                        tooltip: s.more,
                        onPressed: () => _statusMenu(context, s),
                        icon: const WaIcon(WaIcons.more, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    s.statusSection,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ListTile(
                  onTap: () => _editStatus(context, shell, s),
                  leading: Stack(
                    children: [
                      AvatarCircle(
                        name: profile.displayName,
                        colorHex: profile.avatarColor,
                        imagePath: profile.photoPath,
                        size: 52,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.bgDeep,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const WaIcon(
                            WaIcons.plus,
                            size: 12,
                            color: Colors.white,
                            secondaryColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    s.myStatus,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    shell.myStatus.isEmpty ? s.tapToAddStatus : shell.myStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              if (recent.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      s.recentUpdates,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final chat = recent[i];
                      return ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ChatDetailScreen(chat: chat),
                            ),
                          );
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accentBright,
                              width: 2,
                            ),
                          ),
                          child: AvatarCircle(
                            name: chat.title,
                            colorHex: chat.avatarColor,
                            size: 48,
                          ),
                        ),
                        title: Text(
                          chat.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          chat.lastMessage ?? s.noPreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    },
                    childCount: recent.length,
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    s.channels,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const WaIcon(
                          WaIcons.image,
                          size: 28,
                          color: AppColors.accentBright,
                          glow: true,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.channelsBody,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.channelsLocalOnly)),
                            );
                          },
                          child: Text(
                            s.findChannels,
                            style: const TextStyle(color: AppColors.accentBright),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editStatus(
    BuildContext context,
    WaShellStore shell,
    S s,
  ) async {
    final ctrl = TextEditingController(text: shell.myStatus);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text(s.myStatus),
        content: TextField(
          controller: ctrl,
          maxLength: 140,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: s.tapToAddStatus,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (text != null) await shell.setMyStatus(text);
  }

  void _statusMenu(BuildContext context, S s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const WaIcon(WaIcons.info, size: 22),
              title: Text(s.statusPrivacy),
              onTap: () {
                Navigator.pop(ctx);
                showDialog<void>(
                  context: context,
                  builder: (d) => AlertDialog(
                    backgroundColor: AppColors.panel,
                    title: Text(s.statusPrivacy),
                    content: Text(
                      s.statusPrivacyBody,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d),
                        child: Text(s.ok),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
