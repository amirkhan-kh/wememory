import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/archive_service.dart';
import '../../core/services/wa_bridge_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/wa_icons.dart';
import '../calls/calls_screen.dart';
import '../chats/chats_screen.dart';
import '../communities/communities_screen.dart';
import '../settings/settings_screen.dart';
import '../updates/updates_screen.dart';

/// WhatsApp-like bottom nav: Chats · Updates · Communities · Calls.
/// Settings opens from Chats header / profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ArchiveService>().onAppResumed();
      final bridge = context.read<WaBridgeService>();
      if (bridge.isLinked) {
        bridge.fetchContacts();
        bridge.pullSync();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    final locale = context.watch<LocaleController>();
    final s = S.from(locale);
    const pages = [
      ChatsScreen(),
      UpdatesScreen(),
      CommunitiesScreen(),
      CallsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 64,
        backgroundColor: AppColors.navBar,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const WaIcon(WaIcons.chats, size: 24),
            selectedIcon: WaIcon(
              WaIcons.chatsFilled,
              size: 24,
              color: AppColors.textPrimary,
            ),
            label: s.chats,
          ),
          NavigationDestination(
            icon: const WaIcon(WaIcons.image, size: 24),
            selectedIcon: WaIcon(
              WaIcons.image,
              size: 24,
              color: AppColors.textPrimary,
            ),
            label: s.updates,
          ),
          NavigationDestination(
            icon: const WaIcon(WaIcons.archive, size: 24),
            selectedIcon: WaIcon(
              WaIcons.archive,
              size: 24,
              color: AppColors.textPrimary,
            ),
            label: s.communities,
          ),
          NavigationDestination(
            icon: const WaIcon(WaIcons.call, size: 24),
            selectedIcon: WaIcon(
              WaIcons.call,
              size: 24,
              color: AppColors.textPrimary,
            ),
            label: s.calls,
          ),
        ],
      ),
    );
  }
}

/// Open Settings from Chats (WA gear / profile pattern).
void openSettings(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
  );
}
