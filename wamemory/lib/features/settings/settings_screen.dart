import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/archive_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archive = context.watch<ArchiveService>();

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _SectionLabel('Archive'),
            GlassPanel(
              radius: 18,
              child: Column(
                children: [
                  _Tile(
                    icon: WaIcons.notify,
                    title: 'Notification access',
                    subtitle: archive.listenerEnabled
                        ? 'Enabled'
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
                  const Divider(height: 1, color: AppColors.divider),
                  _Tile(
                    icon: WaIcons.storage,
                    title: 'Local storage',
                    subtitle: 'Messages stored on this device (SQLite)',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const _SectionLabel('Subscription'),
            GlassPanel(
              radius: 18,
              child: _Tile(
                icon: WaIcons.premium,
                title: 'WAMemory Premium',
                subtitle: '\$5 / month · 7-day trial',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Billing comes in the next milestone'),
                    ),
                  );
                },
              ),
            ),
            const _SectionLabel('About'),
            GlassPanel(
              radius: 18,
              child: Column(
                children: [
                  _Tile(
                    icon: WaIcons.info,
                    title: 'How it works',
                    subtitle:
                        'WAMemory saves a copy when a WhatsApp notification arrives. If the sender deletes it later, the saved copy stays here.',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _Tile(
                    icon: WaIcons.shield,
                    title: 'Limits',
                    subtitle:
                        'Not affiliated with WhatsApp. Hidden notification text and missed alerts cannot be recovered.',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Languages: English · Русский\nSupport: Telegram',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
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
