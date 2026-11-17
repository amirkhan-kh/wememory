import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/archive_service.dart';
import 'core/services/profile_store.dart';
import 'core/services/wa_bridge_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/setup/setup_flow_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  try {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final archive = ArchiveService();
    await archive.init();
    final profile = ProfileStore(prefs: prefs);
    await profile.init();
    final bridge = WaBridgeService(prefs: prefs, archive: archive);
    bridge.attachArchive(archive);
    await bridge.init();
    if (profile.phone.isNotEmpty && bridge.phone.isEmpty) {
      await bridge.setPhone(profile.phone);
    }
    runApp(
      WAMemoryApp(
        archive: archive,
        profile: profile,
        bridge: bridge,
        showOnboarding: !onboardingDone,
      ),
    );
  } catch (e, st) {
    debugPrint('WAMemory boot failed: $e\n$st');
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0B141A),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'WAMemory failed to start.\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WAMemoryApp extends StatefulWidget {
  const WAMemoryApp({
    super.key,
    required this.archive,
    required this.profile,
    required this.bridge,
    required this.showOnboarding,
  });

  final ArchiveService archive;
  final ProfileStore profile;
  final WaBridgeService bridge;
  final bool showOnboarding;

  @override
  State<WAMemoryApp> createState() => _WAMemoryAppState();
}

class _WAMemoryAppState extends State<WAMemoryApp> {
  late bool _showOnboarding = widget.showOnboarding;
  late bool _needsSetup = !widget.profile.setupComplete;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.archive),
        ChangeNotifierProvider.value(value: widget.profile),
        ChangeNotifierProvider.value(value: widget.bridge),
      ],
      child: MaterialApp(
        title: 'WAMemory',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: _showOnboarding
            ? OnboardingScreen(
                onDone: () => setState(() {
                  _showOnboarding = false;
                  _needsSetup = !widget.profile.setupComplete;
                }),
              )
            : _needsSetup
                ? SetupFlowScreen(
                    onDone: () => setState(() => _needsSetup = false),
                  )
                : const HomeShell(),
      ),
    );
  }
}
