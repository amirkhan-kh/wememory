import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/wa_icons.dart';

/// WhatsApp-like Starred empty state (light/dark via AppColors).
class StarredScreen extends StatelessWidget {
  const StarredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        title: Text(
          'Starred',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.accentBright,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: WaIcon(
                    WaIcons.lab,
                    size: 40,
                    color: Color(0xFF111B21),
                    secondaryColor: Color(0xFF111B21),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Touch and hold any message or channel update to star it, so you can easily find it later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
