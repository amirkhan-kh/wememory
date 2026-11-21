import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/archive_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/wa_icons.dart';
import '../connect/connect_screen.dart';

/// Post-install phone + in-app setup guide (EN/RU).
class SetupGuideScreen extends StatelessWidget {
  const SetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    final s = S.from(context.watch<LocaleController>());
    final archive = context.watch<ArchiveService>();

    final steps = <(WaIcons, String, String)>[
      (WaIcons.document, s.setupStep1Title, s.setupStep1Body),
      (WaIcons.notify, s.setupStep2Title, s.setupStep2Body),
      (WaIcons.settings, s.setupStep3Title, s.setupStep3Body),
      (WaIcons.lock, s.setupStep4Title, s.setupStep4Body),
      (WaIcons.chats, s.setupStep5Title, s.setupStep5Body),
      (WaIcons.image, s.setupStep6Title, s.setupStep6Body),
      (WaIcons.check, s.setupStep7Title, s.setupStep7Body),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        title: Text(
          s.setupGuide,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WaIcon(
                  WaIcons.info,
                  size: 28,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.setupGuideIntro,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final step in steps) ...[
            _StepCard(
              icon: step.$1,
              title: step.$2,
              body: step.$3,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              await archive.openNotificationSettings();
              await Future<void>.delayed(const Duration(seconds: 1));
              await archive.refreshListenerStatus();
            },
            icon: const WaIcon(
              WaIcons.notify,
              size: 20,
              color: Colors.white,
              secondaryColor: Colors.white,
            ),
            label: Text(s.setupOpenNotifications),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ConnectScreen(),
                ),
              );
            },
            icon: WaIcon(
              WaIcons.lock,
              size: 20,
              color: AppColors.accent,
            ),
            label: Text(s.setupOpenConnect),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(
                  text: 'http://13.140.202.159:8090/api',
                ),
              );
              if (!context.mounted) return;
              final ru = context.read<LocaleController>().isRu;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ru ? 'API URL скопирован' : 'API URL copied',
                  ),
                ),
              );
            },
            child: Text(
              'API: http://13.140.202.159:8090/api',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final WaIcons icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.navSelectedPill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: WaIcon(icon, size: 22, color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
