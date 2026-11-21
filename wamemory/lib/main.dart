import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/l10n/app_strings.dart';
import 'core/l10n/locale_controller.dart';
import 'core/services/archive_service.dart';
import 'core/services/profile_store.dart';
import 'core/services/wa_bridge_service.dart';
import 'core/services/wa_shell_store.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/setup/setup_flow_screen.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_done') ?? false;
      final localeCtrl = LocaleController(prefs: prefs);
      await localeCtrl.init();

      ArchiveService archive = ArchiveService();
      try {
        await archive.init();
      } catch (e, st) {
        debugPrint('Archive init failed, memory fallback: $e\n$st');
        archive = ArchiveService(useMemory: true);
        await archive.init();
      }

      await _boot(prefs, archive, localeCtrl, onboardingDone);
    } catch (e, st) {
      debugPrint('WAMemory boot failed: $e\n$st');
      runApp(_CrashApp(error: '$e'));
    }
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

Future<void> _boot(
  SharedPreferences prefs,
  ArchiveService archive,
  LocaleController localeCtrl,
  bool onboardingDone,
) async {
  final profile = ProfileStore(prefs: prefs);
  await profile.init();
  final shell = WaShellStore(prefs: prefs);
  await shell.init();
  final themeCtrl = ThemeController(prefs: prefs);
  await themeCtrl.init();
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
      shell: shell,
      localeController: localeCtrl,
      themeController: themeCtrl,
      showOnboarding: !onboardingDone,
    ),
  );
}

class _CrashApp extends StatelessWidget {
  const _CrashApp({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0B141A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'WAMemory failed to start.\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
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
    required this.shell,
    required this.localeController,
    required this.themeController,
    required this.showOnboarding,
  });

  final ArchiveService archive;
  final ProfileStore profile;
  final WaBridgeService bridge;
  final WaShellStore shell;
  final LocaleController localeController;
  final ThemeController themeController;
  final bool showOnboarding;

  @override
  State<WAMemoryApp> createState() => _WAMemoryAppState();
}

class _WAMemoryAppState extends State<WAMemoryApp>
    with WidgetsBindingObserver {
  late bool _showOnboarding = widget.showOnboarding;
  late bool _needsSetup = !widget.profile.setupComplete;

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
  void didChangePlatformBrightness() {
    widget.themeController.syncFromPlatform(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.archive),
        ChangeNotifierProvider.value(value: widget.profile),
        ChangeNotifierProvider.value(value: widget.bridge),
        ChangeNotifierProvider.value(value: widget.shell),
        ChangeNotifierProvider.value(value: widget.localeController),
        ChangeNotifierProvider.value(value: widget.themeController),
      ],
      child: LocaleControllerScope(
        controller: widget.localeController,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            widget.localeController,
            widget.themeController,
          ]),
          builder: (context, _) {
            final overlay = AppColors.isLight
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light;
            SystemChrome.setSystemUIOverlayStyle(overlay);
            return MaterialApp(
              title: 'WAMemory',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: widget.themeController.mode,
              locale: widget.localeController.locale,
              supportedLocales: const [Locale('en'), Locale('ru')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => ThemeScope(
                controller: widget.themeController,
                child: child ?? const SizedBox.shrink(),
              ),
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
            );
          },
        ),
      ),
    );
  }
}
