import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// WhatsApp-style doodle wallpaper behind chat messages.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, required this.child});

  final Widget child;

  static const lightAsset = 'assets/images/chat_wallpaper_light.jpg';
  static const darkAsset = 'assets/images/chat_wallpaper_dark.jpg';

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    final asset = AppColors.isLight ? lightAsset : darkAsset;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: AppColors.chatWallpaper),
        Positioned.fill(
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        // Soft wash so bubbles stay readable (palette-matched).
        Positioned.fill(
          child: ColoredBox(
            color: AppColors.isLight
                ? const Color(0x22EFEAE2)
                : const Color(0x440B141A),
          ),
        ),
        child,
      ],
    );
  }
}
