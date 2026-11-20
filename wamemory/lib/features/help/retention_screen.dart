import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/services/wa_shell_store.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/surreal_background.dart';
import '../../widgets/wa_icons.dart';

/// Retention preference — stored locally; purge job later.
class RetentionScreen extends StatelessWidget {
  const RetentionScreen({super.key});

  static const _options = [30, 90, 365];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final shell = context.watch<WaShellStore>();

    return SurrealBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(s.retentionTitle),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(16),
              child: Text(
                s.retentionBody,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                children: [
                  for (var i = 0; i < _options.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: AppColors.divider),
                    ListTile(
                      leading: const WaIcon(WaIcons.archive, size: 22),
                      title: Text(
                        s.retentionDays(_options[i]),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        s.retentionHint,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      trailing: shell.retentionDays == _options[i]
                          ? WaIcon(
                              WaIcons.check,
                              size: 20,
                              color: AppColors.accentBright,
                            )
                          : null,
                      onTap: () => shell.setRetentionDays(_options[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
