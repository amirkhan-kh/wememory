import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/archive_service.dart';
import '../../core/services/profile_store.dart';
import '../../core/services/wa_bridge_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';
import '../connect/connect_screen.dart';
import '../profile/profile_screen.dart';

const _appVersion = '0.1.0';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archive = context.watch<ArchiveService>();
    final profile = context.watch<ProfileStore>();
    final bridge = context.watch<WaBridgeService>();

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _ProfileHeader(
              profile: profile,
              phone: profile.phone.isNotEmpty ? profile.phone : bridge.phone,
              chatCount: archive.chats.length,
              onEdit: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),
            const _SectionLabel('Account'),
            GlassPanel(
              radius: 18,
              child: Column(
                children: [
                  _Tile(
                    icon: WaIcons.lock,
                    title: 'Connect WhatsApp',
                    subtitle: bridge.phone.isEmpty
                        ? 'Enter your one WhatsApp number · ban risk'
                        : bridge.isLinked
                            ? '${bridge.phone} · linked (${bridge.connectionState})'
                            : '${bridge.phone} · ${bridge.connectionState}',
                    trailing: WaIcon(
                      bridge.isLinked ? WaIcons.check : WaIcons.warning,
                      size: 20,
                      color: bridge.isLinked
                          ? AppColors.accentBright
                          : AppColors.warning,
                      secondaryColor: bridge.isLinked
                          ? AppColors.accentBright
                          : AppColors.warning,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ConnectScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _Tile(
                    icon: WaIcons.premium,
                    title: 'WAMemory Premium',
                    subtitle: '\$5 / month · 7-day trial · 1 WhatsApp account',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Billing comes in the next milestone'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const _SectionLabel('Privacy & safety'),
            GlassPanel(
              radius: 18,
              child: Column(
                children: [
                  const _Tile(
                    icon: WaIcons.shield,
                    title: 'Archive only (Option A)',
                    subtitle:
                        'Deleted copies stay inside WAMemory. Nothing is written back into WhatsApp.',
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  const _Tile(
                    icon: WaIcons.lock,
                    title: 'Not affiliated with WhatsApp',
                    subtitle:
                        'Hidden notification text and missed alerts cannot be recovered.',
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _Tile(
                    icon: WaIcons.warning,
                    title: 'Two capture modes',
                    subtitle:
                        'Archive = Notification Access (safer). Live clone = Evolution Linked Device (ban risk).',
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.panel,
                          title: const Text('Archive vs live clone'),
                          content: const Text(
                            'Path A archives WhatsApp notification text locally — lower risk.\n\n'
                            'Path B (Connect WhatsApp) uses Evolution / Baileys Linked Device — '
                            'unofficial. Meta may ban the number. Prefer a dedicated test account. '
                            'No ban immunity.',
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
                ],
              ),
            ),
            const _SectionLabel('Notifications'),
            GlassPanel(
              radius: 18,
              child: _Tile(
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
            ),
            const _SectionLabel('Storage'),
            GlassPanel(
              radius: 18,
              child: Column(
                children: [
                  _Tile(
                    icon: WaIcons.storage,
                    title: 'Local storage',
                    subtitle:
                        'SQLite on this device · ${archive.chats.length} chats · ${archive.deleted.length} deleted',
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _Tile(
                    icon: WaIcons.archive,
                    title: 'Retention',
                    subtitle: '30 / 90 / 365 days — coming next',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Retention controls come in a later milestone'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const _SectionLabel('Chats & profiles'),
            GlassPanel(
              radius: 18,
              child: _Tile(
                icon: WaIcons.chats,
                title: 'Linked chat profiles',
                subtitle:
                    'Each archived contact keeps its own avatar colour and thread in Chats.',
                onTap: () {
                  _showLinkedProfiles(context, archive);
                },
              ),
            ),
            const _SectionLabel('Language'),
            const GlassPanel(
              radius: 18,
              child: _Tile(
                icon: WaIcons.lab,
                title: 'App language',
                subtitle: 'English · Русский (full wiring in next milestone)',
              ),
            ),
            const _SectionLabel('Help'),
            GlassPanel(
              radius: 18,
              child: Column(
                children: [
                  _Tile(
                    icon: WaIcons.info,
                    title: 'How it works',
                    subtitle:
                        'WAMemory saves a copy when a WhatsApp notification arrives. If the sender deletes it later, the saved copy stays here.',
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.panel,
                          title: const Text('How it works'),
                          content: const Text(
                            '1. Grant Notification Access.\n'
                            '2. Keep WhatsApp notifications visible (not hidden text).\n'
                            '3. New alerts are archived locally.\n'
                            '4. If a message is deleted in WhatsApp, the copy remains in WAMemory.',
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
                  const Divider(height: 1, color: AppColors.divider),
                  const _Tile(
                    icon: WaIcons.check,
                    title: 'Support',
                    subtitle: 'Telegram support (channel comes with launch)',
                  ),
                ],
              ),
            ),
            const _SectionLabel('About'),
            GlassPanel(
              radius: 18,
              child: Column(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/brand/wamemory_mark.png',
                            width: 42,
                            height: 42,
                            errorBuilder: (_, __, ___) => const WaIcon(
                              WaIcons.archive,
                              size: 28,
                              color: AppColors.accentBright,
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WAMemory',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Version $_appVersion · Android archive',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  const _Tile(
                    icon: WaIcons.shield,
                    title: 'Limits',
                    subtitle:
                        'Not affiliated with WhatsApp. One account on Premium. ~2 GB media quota planned.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkedProfiles(BuildContext context, ArchiveService archive) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final chats = archive.chats;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Linked chat profiles',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  chats.isEmpty
                      ? 'No archived chats yet. Profiles appear when notifications are saved.'
                      : 'Each contact below is tied to its archive thread.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: chats.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (_, i) {
                      final c = chats[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: AvatarCircle(
                          name: c.title,
                          colorHex: c.avatarColor,
                          size: 44,
                        ),
                        title: Text(
                          c.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          c.lastMessage ?? 'No preview',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.phone,
    required this.chatCount,
    required this.onEdit,
  });

  final ProfileStore profile;
  final String phone;
  final int chatCount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 18,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              AvatarCircle(
                name: profile.displayName,
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
                      profile.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.about,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      phone.isEmpty
                          ? '$chatCount chats · tap to open profile'
                          : '+$phone · $chatCount chats',
                      style: TextStyle(
                        color: AppColors.accentBright.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const WaIcon(
                WaIcons.settings,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final WaIcons icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent.withValues(alpha: 0.12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        alignment: Alignment.center,
        child: WaIcon(icon, size: 20, color: AppColors.textPrimary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
