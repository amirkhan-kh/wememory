import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/wa_icons.dart';
import '../chats/chats_screen.dart';
import '../deleted/deleted_screen.dart';
import '../settings/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    ChatsScreen(),
    DeletedScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.appBar.withValues(alpha: 0.72),
              border: const Border(
                top: BorderSide(color: AppColors.glassBorder),
              ),
            ),
            child: NavigationBar(
              height: 70,
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.accent.withValues(alpha: 0.18),
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                  icon: const WaIcon(WaIcons.chats, size: 24),
                  selectedIcon: const WaIcon(
                    WaIcons.chatsFilled,
                    size: 24,
                    color: AppColors.textPrimary,
                    glow: true,
                  ),
                  label: 'Chats',
                ),
                NavigationDestination(
                  icon: const WaIcon(WaIcons.deleted, size: 24),
                  selectedIcon: const WaIcon(
                    WaIcons.deletedFilled,
                    size: 24,
                    color: AppColors.textPrimary,
                    glow: true,
                  ),
                  label: 'Deleted',
                ),
                NavigationDestination(
                  icon: const WaIcon(WaIcons.settings, size: 24),
                  selectedIcon: const WaIcon(
                    WaIcons.settingsFilled,
                    size: 24,
                    color: AppColors.textPrimary,
                    glow: true,
                  ),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
