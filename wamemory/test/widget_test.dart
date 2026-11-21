import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wamemory/features/help/setup_guide_screen.dart';
import 'package:wamemory/features/settings/settings_screen.dart';
import 'package:wamemory/core/db/memory_store.dart';
import 'package:wamemory/core/l10n/app_strings.dart';
import 'package:wamemory/core/l10n/locale_controller.dart';
import 'package:wamemory/core/models/chat.dart';
import 'package:wamemory/core/services/archive_service.dart';
import 'package:wamemory/core/services/profile_store.dart';
import 'package:wamemory/core/services/wa_bridge_service.dart';
import 'package:wamemory/core/services/wa_shell_store.dart';
import 'package:wamemory/core/theme/app_colors.dart';
import 'package:wamemory/core/theme/app_theme.dart';
import 'package:wamemory/core/theme/theme_controller.dart';
import 'package:wamemory/core/utils/phone_utils.dart';
import 'package:wamemory/features/home/home_shell.dart';
import 'package:wamemory/features/onboarding/onboarding_screen.dart';
import 'package:wamemory/main.dart';
import 'package:wamemory/widgets/wa_icons.dart';

const _notifChannel = MethodChannel('com.wamemory.app/notifications');

/// Aurora / PageView animations never "settle"; force reduced motion in tests.
Widget _wrap(Widget child) {
  return MediaQuery(
    data: const MediaQueryData(
      size: Size(390, 844),
      disableAnimations: true,
      accessibleNavigation: true,
    ),
    child: child,
  );
}

Future<ArchiveService> _readyArchive() async {
  final archive = ArchiveService(memory: MemoryStore(), useMemory: true);
  await archive.init();
  return archive;
}

Future<ProfileStore> _readyProfile() async {
  final profile = ProfileStore();
  await profile.init();
  return profile;
}

Future<WaBridgeService> _readyBridge([ArchiveService? archive]) async {
  final bridge = WaBridgeService(archive: archive);
  if (archive != null) bridge.attachArchive(archive);
  await bridge.init();
  return bridge;
}

Future<LocaleController> _readyLocale() async {
  final locale = LocaleController();
  await locale.init();
  return locale;
}

Future<WaShellStore> _readyShell() async {
  final shell = WaShellStore();
  await shell.init();
  return shell;
}

Future<ThemeController> _readyTheme() async {
  final theme = ThemeController();
  await theme.init();
  await theme.setMode(ThemeMode.dark);
  return theme;
}

Widget _homeWithProviders(
  ArchiveService archive,
  ProfileStore profile,
  WaBridgeService bridge,
  LocaleController locale,
  WaShellStore shell,
  ThemeController theme,
) {
  final themeCtrl = theme;
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: archive),
      ChangeNotifierProvider.value(value: profile),
      ChangeNotifierProvider.value(value: bridge),
      ChangeNotifierProvider.value(value: shell),
      ChangeNotifierProvider.value(value: locale),
      ChangeNotifierProvider.value(value: themeCtrl),
    ],
    child: LocaleControllerScope(
      controller: locale,
      child: AnimatedBuilder(
        animation: Listenable.merge([locale, themeCtrl]),
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeCtrl.mode,
          locale: locale.locale,
          supportedLocales: const [Locale('en'), Locale('ru')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => ThemeScope(
            controller: themeCtrl,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const HomeShell(),
        ),
      ),
    ),
  );
}

Future<void> _pumpFrames(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppColors.apply(Brightness.dark);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notifChannel, (call) async {
      if (call.method == 'isNotificationAccessEnabled') return false;
      if (call.method == 'openNotificationAccessSettings') return true;
      if (call.method == 'flushPending') return 0;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notifChannel, null);
  });

  // Repeat critical UI assertions 3× (TESTING.md).
  for (var round = 1; round <= 3; round++) {
    group('round $round', () {
      testWidgets('theme + icons render', (tester) async {
        await tester.pumpWidget(
          _wrap(
            MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('WAMemory'),
                      WaIcon(WaIcons.chats, size: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await _pumpFrames(tester);
        expect(find.text('WAMemory'), findsOneWidget);
        expect(find.byType(WaIcon), findsOneWidget);
      });

      testWidgets('onboarding 3 slides + Get started', (tester) async {
        var done = false;
        await tester.pumpWidget(
          _wrap(
            MaterialApp(
              theme: AppTheme.dark,
              home: OnboardingScreen(onDone: () => done = true),
            ),
          ),
        );
        await _pumpFrames(tester);
        expect(find.text('Your chats. Your archive.'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await _pumpFrames(tester, 12);
        expect(find.text('Connect via notifications'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await _pumpFrames(tester, 12);
        expect(find.text('WhatsApp-like experience'), findsOneWidget);
        await tester.tap(find.text('Get started'));
        await _pumpFrames(tester);
        expect(done, isTrue);
      });

      testWidgets('home shell chats + WA tabs + settings', (tester) async {
        final archive = await _readyArchive();
        final profile = await _readyProfile();
        final bridge = await _readyBridge();
        final locale = await _readyLocale();
        final shell = await _readyShell();
        final theme = await _readyTheme();
        await tester.pumpWidget(
          _wrap(
            _homeWithProviders(archive, profile, bridge, locale, shell, theme),
          ),
        );
        await _pumpFrames(tester, 12);

        expect(find.text('WAMemory'), findsOneWidget);
        expect(find.text('Flor Camden'), findsWidgets);
        expect(find.text('Joanna'), findsWidgets);
        expect(find.text('Alex Rivera'), findsWidgets);
        expect(find.text('Chats'), findsWidgets);
        expect(find.text('Updates'), findsWidgets);
        expect(find.text('Communities'), findsWidgets);
        expect(find.text('Calls'), findsWidgets);

        await tester.tap(find.text('Updates'));
        await _pumpFrames(tester, 12);
        expect(find.text('My status'), findsOneWidget);

        await tester.tap(find.text('Chats'));
        await _pumpFrames(tester, 8);
        await tester.tap(find.byTooltip('Deleted'));
        await _pumpFrames(tester, 12);
        expect(find.text('Deleted messages'), findsOneWidget);
        await tester.pageBack();
        await _pumpFrames(tester, 8);

        // Settings gear is 3rd IconButton after Deleted+Search in header.
        final buttons = find.byType(IconButton);
        expect(buttons, findsWidgets);
        await tester.tap(buttons.at(2));
        await _pumpFrames(tester, 12);
        expect(find.text('Linked devices'), findsOneWidget);
      });

      testWidgets('open chat thread shows bubbles + deleted badge', (tester) async {
        final archive = await _readyArchive();
        final profile = await _readyProfile();
        final bridge = await _readyBridge();
        final locale = await _readyLocale();
        final shell = await _readyShell();
        final theme = await _readyTheme();
        await tester.pumpWidget(
          _wrap(
            _homeWithProviders(archive, profile, bridge, locale, shell, theme),
          ),
        );
        await _pumpFrames(tester, 12);
        await tester.tap(find.text('Flor Camden'));
        await _pumpFrames(tester, 16);
        expect(
          find.text('The payment terms are on page 3 — keep this confidential.'),
          findsOneWidget,
        );
        expect(find.textContaining('Deleted'), findsWidgets);
      });

      testWidgets('WAMemoryApp boots past onboarding into chats', (tester) async {
        SharedPreferences.setMockInitialValues({
          'onboarding_done': true,
          'profile_setup_complete': true,
        });
        final archive = await _readyArchive();
        final profile = await _readyProfile();
        final bridge = await _readyBridge();
        final locale = await _readyLocale();
        final shell = await _readyShell();
        final theme = await _readyTheme();
        await tester.pumpWidget(
          _wrap(
            WAMemoryApp(
              archive: archive,
              profile: profile,
              bridge: bridge,
              shell: shell,
              localeController: locale,
              themeController: theme,
              showOnboarding: false,
            ),
          ),
        );
        await _pumpFrames(tester, 12);
        expect(find.text('WAMemory'), findsOneWidget);
        expect(find.text('Flor Camden'), findsOneWidget);
      });

      testWidgets('setup flow asks for phone then name', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final archive = await _readyArchive();
        final profile = await _readyProfile();
        final bridge = await _readyBridge(archive);
        final locale = await _readyLocale();
        final shell = await _readyShell();
        final theme = await _readyTheme();
        await tester.pumpWidget(
          _wrap(
            WAMemoryApp(
              archive: archive,
              profile: profile,
              bridge: bridge,
              shell: shell,
              localeController: locale,
              themeController: theme,
              showOnboarding: false,
            ),
          ),
        );
        await _pumpFrames(tester, 12);
        expect(find.text('Your WhatsApp number'), findsOneWidget);
        await tester.enterText(find.byType(TextField), '998901234567');
        await tester.tap(find.text('Next'));
        await _pumpFrames(tester, 12);
        expect(find.text('Profile name'), findsOneWidget);
      });
    });

    group('phone + API errors', () {
      test('PhoneUtils validates country-code digits', () {
        expect(PhoneUtils.isValid('998901234567'), isTrue);
        expect(PhoneUtils.isValid('+998 90 123-45-67'), isTrue);
        expect(PhoneUtils.isValid('123'), isFalse);
        expect(PhoneUtils.validationError(''), isNotNull);
        expect(PhoneUtils.normalize('+998-90'), '99890');
      });

      test('WaBridgeService.parseApiError reads Nest message', () {
        expect(
          WaBridgeService.parseApiError(
            400,
            '{"statusCode":400,"message":"Invalid phone — use country code + number (e.g. 998901234567)","error":"Bad Request"}',
          ),
          contains('Invalid phone'),
        );
        expect(
          WaBridgeService.parseApiError(
            400,
            '{"message":["phone must be a string","too short"],"error":"Bad Request","statusCode":400}',
          ),
          contains('phone must be a string'),
        );
      });
    });
  }

  group('crash-hardening', () {
    test('Chat.fromMap tolerates missing peer_phone', () {
      final chat = Chat.fromMap({
        'id': 'c1',
        'title': 'Test',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'unread_count': 0,
        'is_group': 0,
      });
      expect(chat.title, 'Test');
      expect(chat.peerPhone, isNull);
    });

    testWidgets('bad native notification does not crash archive', (tester) async {
      final archive = await _readyArchive();
      // Simulate malformed payloads the way MethodChannel would deliver.
      await archive.init();
      // Direct ingest with empty title/body must no-op.
      await archive.simulateIncoming(title: '', body: '');
      expect(archive.chats, isNotEmpty); // demo seed still present
    });

    test('WaContact nickname filter matches pushName', () {
      final bridge = WaBridgeService();
      bridge.contacts = [
        WaContact(
          id: '1',
          displayName: 'Amir Dev',
          pushName: 'amirxon',
          phone: '998901112233',
        ),
        WaContact(
          id: '2',
          displayName: 'Flor',
          pushName: 'flor',
          phone: '998909998877',
        ),
      ];
      expect(bridge.filterContacts('amir').length, 1);
      expect(bridge.filterContacts('99890').length, 2);
      expect(bridge.filterContacts('zzz'), isEmpty);
    });

    testWidgets('locale switch EN→RU does not crash shell', (tester) async {
      final archive = await _readyArchive();
      final profile = await _readyProfile();
      final bridge = await _readyBridge();
      final locale = await _readyLocale();
      final shell = await _readyShell();
      final theme = await _readyTheme();
      await tester.pumpWidget(
        _wrap(
          _homeWithProviders(archive, profile, bridge, locale, shell, theme),
        ),
      );
      await _pumpFrames(tester, 10);
      await locale.setLocale(const Locale('ru'));
      await _pumpFrames(tester, 10);
      expect(find.text('Чаты'), findsWidgets);
      await locale.setLocale(const Locale('en'));
      await _pumpFrames(tester, 10);
      expect(find.text('Chats'), findsWidgets);
    });
  });

  group('QA settings + locale MaterialLocalizations', () {
    Future<void> _openSettings(WidgetTester tester) async {
      await tester.tap(find.byType(IconButton).at(2));
      await _pumpFrames(tester, 12);
      expect(find.byType(SettingsScreen), findsOneWidget);
    }

    Future<void> _navPop(WidgetTester tester) async {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pop();
      await _pumpFrames(tester, 10);
    }

    for (var round = 1; round <= 5; round++) {
      testWidgets('round $round settings RU/EN + AppBar ok', (tester) async {
        final archive = await _readyArchive();
        final profile = await _readyProfile();
        final bridge = await _readyBridge();
        final locale = await _readyLocale();
        final shell = await _readyShell();
        final theme = await _readyTheme();
        await tester.pumpWidget(
          _wrap(
            _homeWithProviders(archive, profile, bridge, locale, shell, theme),
          ),
        );
        await _pumpFrames(tester, 10);
        await _openSettings(tester);
        expect(tester.takeException(), isNull);

        for (var i = 0; i < 2; i++) {
          await locale.setLocale(const Locale('ru'));
          await _pumpFrames(tester, 10);
          expect(tester.takeException(), isNull);
          expect(find.text('Настройки'), findsWidgets);

          await locale.setLocale(const Locale('en'));
          await _pumpFrames(tester, 10);
          expect(tester.takeException(), isNull);
          expect(find.text('Settings'), findsWidgets);
        }

        // Push guide directly (avoids scroll flakiness).
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        nav.push(MaterialPageRoute<void>(builder: (_) => const SetupGuideScreen()));
        await _pumpFrames(tester, 12);
        expect(find.byType(SetupGuideScreen), findsOneWidget);
        expect(find.textContaining('Notification Access'), findsOneWidget);

        await locale.setLocale(const Locale('ru'));
        await _pumpFrames(tester, 12);
        expect(tester.takeException(), isNull);
        expect(find.text('Инструкция'), findsWidgets);

        await _navPop(tester);
        await _navPop(tester);
        expect(find.text('Чаты'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('theme toggle repaints all tabs (not only Settings)',
        (tester) async {
      final archive = await _readyArchive();
      final profile = await _readyProfile();
      final bridge = await _readyBridge();
      final locale = await _readyLocale();
      final shell = await _readyShell();
      final theme = await _readyTheme();
      await tester.pumpWidget(
        _wrap(
          _homeWithProviders(archive, profile, bridge, locale, shell, theme),
        ),
      );
      await _pumpFrames(tester, 8);

      Color scaffoldBg() =>
          tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor!;

      for (var i = 0; i < 5; i++) {
        await theme.setMode(ThemeMode.light);
        await _pumpFrames(tester, 8);
        expect(tester.takeException(), isNull);
        expect(scaffoldBg(), const Color(0xFFFFFFFF),
            reason: 'Chats scaffold must turn white in light mode');

        await theme.setMode(ThemeMode.dark);
        await _pumpFrames(tester, 8);
        expect(tester.takeException(), isNull);
        expect(scaffoldBg(), const Color(0xFF0B141A),
            reason: 'Chats scaffold must return to WA dark');
      }

      // Switch tabs under light and verify each tab background.
      await theme.setMode(ThemeMode.light);
      await _pumpFrames(tester, 8);
      for (final tab in ['Updates', 'Communities', 'Calls', 'Chats']) {
        await tester.tap(find.text(tab).last);
        await _pumpFrames(tester, 8);
        expect(tester.takeException(), isNull);
        final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
        for (final s in scaffolds) {
          final bg = s.backgroundColor;
          if (bg == null || bg == Colors.transparent) continue;
          expect(bg, isNot(const Color(0xFF0B141A)),
              reason: '$tab still dark in light mode');
        }
      }
    });

    testWidgets('theme light/dark ×5 with settings open', (tester) async {
      final archive = await _readyArchive();
      final profile = await _readyProfile();
      final bridge = await _readyBridge();
      final locale = await _readyLocale();
      final shell = await _readyShell();
      final theme = await _readyTheme();
      await tester.pumpWidget(
        _wrap(
          _homeWithProviders(archive, profile, bridge, locale, shell, theme),
        ),
      );
      await _pumpFrames(tester, 8);
      await _openSettings(tester);
      for (var i = 0; i < 5; i++) {
        await theme.setMode(ThemeMode.light);
        AppColors.apply(Brightness.light);
        await _pumpFrames(tester, 6);
        expect(tester.takeException(), isNull);
        await theme.setMode(ThemeMode.dark);
        AppColors.apply(Brightness.dark);
        await _pumpFrames(tester, 6);
        expect(tester.takeException(), isNull);
      }
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
