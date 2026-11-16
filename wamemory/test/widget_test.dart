import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wamemory/core/db/memory_store.dart';
import 'package:wamemory/core/services/archive_service.dart';
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
        await tester.pumpWidget(
          _wrap(
            ChangeNotifierProvider.value(
              value: archive,
              child: MaterialApp(
                theme: AppTheme.dark,
                home: const HomeShell(),
              ),
            ),
          ),
        );
        await _pumpFrames(tester, 12);

        expect(find.text('WAMemory'), findsOneWidget);
        expect(find.text('Flor Camden'), findsWidgets);
        expect(find.text('Joanna'), findsWidgets);
        expect(find.text('Alex Rivera'), findsWidgets);

        await tester.tap(find.text('Deleted'));
        await _pumpFrames(tester, 12);
        expect(find.text('Deleted messages'), findsOneWidget);

        await tester.tap(find.text('Settings'));
        await _pumpFrames(tester, 12);
        expect(find.text('Settings'), findsWidgets);
      });

      testWidgets('open chat thread shows bubbles + deleted badge', (tester) async {
        final archive = await _readyArchive();
        await tester.pumpWidget(
          _wrap(
            ChangeNotifierProvider.value(
              value: archive,
              child: MaterialApp(
                theme: AppTheme.dark,
                home: const HomeShell(),
              ),
            ),
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
        SharedPreferences.setMockInitialValues({'onboarding_done': true});
        final archive = await _readyArchive();
        await tester.pumpWidget(
          _wrap(WAMemoryApp(archive: archive, showOnboarding: false)),
        );
        await _pumpFrames(tester, 12);
        expect(find.text('WAMemory'), findsOneWidget);
        expect(find.text('Flor Camden'), findsOneWidget);
      });
    });
  }
}
