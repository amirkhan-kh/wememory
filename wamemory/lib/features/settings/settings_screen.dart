import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/archive_service.dart';
import '../../core/services/profile_store.dart';
import '../../core/services/wa_bridge_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/wa_icons.dart';
import '../connect/connect_screen.dart';
import '../help/feedback_screen.dart';
import '../help/premium_screen.dart';
import '../help/retention_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import 'broadcasts_screen.dart';
import 'starred_screen.dart';

const _appVersion = '0.1.0';

/// WhatsApp Settings layout (light screenshot + dark palette).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archive = context.watch<ArchiveService>();
    final profile = context.watch<ProfileStore>();
    final bridge = context.watch<WaBridgeService>();
    final theme = context.watch<ThemeController>();
    final s = S.from(context.watch<LocaleController>());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        title: Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
              );
            },
            icon: WaIcon(WaIcons.search, size: 22, color: AppColors.iconMuted),
          ),
        ],
      ),
      body: ListView(
        children: [
          _ProfileRow(
            profile: profile,
            phone: profile.phone.isNotEmpty ? profile.phone : bridge.phone,
            onEdit: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          Divider(height: 1, color: AppColors.divider),
          _WaTile(
            icon: WaIcons.premium,
            title: 'Subscriptions',
            subtitle: 'Explore premium benefits',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
              );
            },
          ),
          _WaTile(
            icon: WaIcons.lock,
            title: 'Linked devices',
            subtitle: bridge.isLinked
                ? 'Connected · ${bridge.connectionState}'
                : 'Use WhatsApp on other devices',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ConnectScreen()),
              );
            },
          ),
          _WaTile(
            icon: WaIcons.settings,
            title: 'Account',
            subtitle: 'Security notifications, change number',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          _WaTile(
            icon: WaIcons.shield,
            title: 'Privacy',
            subtitle: 'Archive only · nothing written back to WhatsApp',
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text(
                    'Privacy',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    'Deleted copies stay inside WAMemory. '
                    'Hidden notification text cannot be recovered. '
                    'Not affiliated with WhatsApp / Meta.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          _WaTile(
            icon: WaIcons.archive,
            title: 'Lists',
            subtitle: 'Manage people and groups',
            onTap: () => _showLinkedProfiles(context, archive),
          ),
          _WaTile(
            icon: WaIcons.chats,
            title: 'Chats',
            subtitle: 'Chat history, backup, retention',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RetentionScreen(),
                ),
              );
            },
          ),
          _WaTile(
            icon: WaIcons.image,
            title: 'Appearance',
            subtitle: _appearanceSubtitle(theme.mode),
            onTap: () => _pickAppearance(context, theme),
          ),
          _WaTile(
            icon: WaIcons.notify,
            title: 'Broadcasts',
            subtitle: 'Send updates to many contacts',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BroadcastsScreen(),
                ),
              );
            },
          ),
          _WaTile(
            icon: WaIcons.lab,
            title: 'Starred',
            subtitle: 'Starred messages',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StarredScreen()),
              );
            },
          ),
          _WaTile(
            icon: WaIcons.notify,
            title: 'Notification access',
            subtitle: archive.listenerEnabled
                ? 'Enabled — WhatsApp alerts are archived'
                : 'Required for auto-archive',
            trailing: WaIcon(
              archive.listenerEnabled ? WaIcons.check : WaIcons.warning,
              size: 20,
              color: archive.listenerEnabled
                  ? AppColors.accentBright
                  : AppColors.warning,
              secondaryColor: archive.listenerEnabled
                  ? AppColors.accentBright
                  : AppColors.warning,
            ),
            onTap: () async {
              await archive.openNotificationSettings();
              await Future<void>.delayed(const Duration(seconds: 1));
              await archive.refreshListenerStatus();
            },
          ),
          _WaTile(
            icon: WaIcons.lab,
            title: s.language,
            subtitle: context.watch<LocaleController>().isRu
                ? s.russian
                : s.english,
            onTap: () => _pickLanguage(context),
          ),
          _WaTile(
            icon: WaIcons.info,
            title: 'Help',
            subtitle: 'Support, feedback, how it works',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FeedbackScreen(),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: Text(
              'WAMemory $_appVersion',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  static String _appearanceSubtitle(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System default',
    };
  }

  static Future<void> _pickAppearance(
    BuildContext context,
    ThemeController theme,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Light', style: TextStyle(color: AppColors.textPrimary)),
                trailing: theme.mode == ThemeMode.light
                    ? WaIcon(
                        WaIcons.check,
                        size: 20,
                        color: AppColors.accentBright,
                      )
                    : null,
                onTap: () {
                  theme.setMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text('Dark', style: TextStyle(color: AppColors.textPrimary)),
                trailing: theme.mode == ThemeMode.dark
                    ? WaIcon(
                        WaIcons.check,
                        size: 20,
                        color: AppColors.accentBright,
                      )
                    : null,
                onTap: () {
                  theme.setMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(
                  'System default',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                trailing: theme.mode == ThemeMode.system
                    ? WaIcon(
                        WaIcons.check,
                        size: 20,
                        color: AppColors.accentBright,
                      )
                    : null,
                onTap: () {
                  theme.setMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _pickLanguage(BuildContext context) async {
    final locale = context.read<LocaleController>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        final s = S.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(s.english),
                onTap: () {
                  locale.setLocale(const Locale('en'));
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(s.russian),
                onTap: () {
                  locale.setLocale(const Locale('ru'));
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showLinkedProfiles(BuildContext context, ArchiveService archive) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) {
        final chats = archive.chats;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Linked chat profiles',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (chats.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No chats yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                for (final c in chats.take(40))
                  ListTile(
                    leading: AvatarCircle(
                      name: c.title,
                      colorHex: c.avatarColor,
                      size: 40,
                    ),
                    title: Text(
                      c.title,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      c.peerPhone ?? (c.isGroup ? 'Group' : 'Chat'),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.profile,
    required this.phone,
    required this.onEdit,
  });

  final ProfileStore profile;
  final String phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName.trim().isEmpty
        ? 'Set your name'
        : profile.displayName;
    final about =
        profile.about.trim().isEmpty ? "I'm feeling..." : profile.about;

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            AvatarCircle(
              name: name,
              colorHex: profile.avatarColor,
              imagePath: profile.photoPath,
              size: 64,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      about,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      phone.startsWith('+') ? phone : '+$phone',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: WaIcon(
                WaIcons.plus,
                size: 22,
                color: AppColors.accentBright,
                secondaryColor: AppColors.accentBright,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaTile extends StatelessWidget {
  const _WaTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final WaIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: WaIcon(icon, size: 24, color: AppColors.iconMuted),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
      ),
      trailing: trailing,
    );
  }
}
