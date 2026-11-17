import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wamemory/core/db/memory_store.dart';
import 'package:wamemory/core/services/archive_service.dart';
import 'package:wamemory/core/services/profile_store.dart';
import 'package:wamemory/core/services/wa_bridge_service.dart';
import 'package:wamemory/core/theme/app_theme.dart';
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

Widget _homeWithProviders(
  ArchiveService archive,
  ProfileStore profile,
  WaBridgeService bridge,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: archive),
      ChangeNotifierProvider.value(value: profile),
      ChangeNotifierProvider.value(value: bridge),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const HomeShell(),
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

      testWidgets('home shell chats + deleted + settings', (tester) async {
        final archive = await _readyArchive();
        final profile = await _readyProfile();
        final bridge = await _readyBridge();
        await tester.pumpWidget(
          _wrap(_homeWithProviders(archive, profile, bridge)),
        );
        await _pumpFrames(tester, 12);

        expect(find.text('WAMemory'), findsOneWidget);
        expect(find.text('Flor Camden'), findsWidgets);
        expect(find.text('Joanna'), findsWidgets);
        expect(find.text('Alex Rivera'), findsWidgets);

        await tester.tap(find.text('Contacts'));
        await _pumpFrames(tester, 12);
        expect(find.text('Contacts'), findsWidgets);
        expect(find.text('Flor Camden'), findsWidgets);

        await tester.tap(find.text('Deleted'));
        await _pumpFrames(tester, 12);
        expect(find.text('Deleted messages'), findsOneWidget);

        await tester.tap(find.text('Settings'));
        await _pumpFrames(tester, 12);
        expect(find.text('Settings'), findsWidgets);
        expect(find.text('You'), findsOneWidget);
        expect(find.text('Connect WhatsApp'), findsOneWidget);
        expect(find.text('WAMemory Premium'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Notification access'),
          120,
          scrollable: find.byType(Scrollable).last,
        );
        await _pumpFrames(tester, 4);
        expect(find.text('Notification access'), findsOneWidget);
      });

      testWidgets('open chat thread shows bubbles + deleted badge', (tester) async {
        final archive = await _readyArchive();
        final profile = await _readyProfile();
        final bridge = await _readyBridge();
        await tester.pumpWidget(
          _wrap(_homeWithProviders(archive, profile, bridge)),
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
        await tester.pumpWidget(
          _wrap(
            WAMemoryApp(
              archive: archive,
              profile: profile,
              bridge: bridge,
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
        await tester.pumpWidget(
          _wrap(
            WAMemoryApp(
              archive: archive,
              profile: profile,
              bridge: bridge,
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
  }
}
