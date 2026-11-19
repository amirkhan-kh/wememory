import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/wa_shell_store.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';

/// WhatsApp-like Communities tab — local groups list (not Meta).
class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.from(context.watch<LocaleController>());
    final shell = context.watch<WaShellStore>();

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_communities',
          onPressed: () => _create(context, shell, s),
          backgroundColor: AppColors.accent,
          icon: const WaIcon(
            WaIcons.plus,
            size: 22,
            color: Colors.white,
            secondaryColor: Colors.white,
          ),
          label: Text(
            s.newCommunity,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
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
                        s.communities,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _create(context, shell, s),
                      icon: const WaIcon(WaIcons.plus, size: 22),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  s.communitiesBody,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              Expanded(
                child: shell.communities.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const WaIcon(
                                WaIcons.archive,
                                size: 56,
                                color: AppColors.accentBright,
                                glow: true,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                s.noCommunities,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.noCommunitiesHint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: shell.communities.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 76,
                          color: AppColors.divider,
                        ),
                        itemBuilder: (context, i) {
                          final c = shell.communities[i];
                          return ListTile(
                            leading: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              alignment: Alignment.center,
                              child: const WaIcon(
                                WaIcons.chats,
                                size: 24,
                                color: AppColors.accentBright,
                              ),
                            ),
                            title: Text(
                              c.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              s.communityLocal,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: s.delete,
                              onPressed: () => shell.removeCommunity(c.id),
                              icon: const WaIcon(
                                WaIcons.deleted,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            onTap: () {
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.panel,
                                  title: Text(c.name),
                                  content: Text(
                                    s.communityDetail,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(s.ok),
                                    ),
                                  ],
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
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    WaShellStore shell,
    S s,
  ) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text(s.newCommunity),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: s.communityNameHint,
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
            child: Text(s.create),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await shell.addCommunity(name);
    }
  }
}
