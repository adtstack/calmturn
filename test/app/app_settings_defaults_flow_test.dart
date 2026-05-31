import 'package:calmturn/features/settings/app_settings.dart';
import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first launch without saved settings shows setup', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();

    expect(find.text('Session Settings'), findsOneWidget);
    expect(find.text('Participants'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings load failure falls back to setup', (tester) async {
    final store = _FailingAppSettingsStore(failLoad: true);

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();

    expect(find.text('Session Settings'), findsOneWidget);
    expect(find.text('Participants'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('app settings defaults are applied to the next session setup', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();

    await _tapText(tester, 'App settings');
    expect(find.text('App Settings'), findsOneWidget);

    await _tapText(tester, '10 min each');
    await _tapText(tester, 'Turn 90 sec');
    await _tapText(tester, 'Sound');
    await _tapText(tester, 'Save settings');

    expect(find.text('Settings saved for the next session.'), findsOneWidget);
    await _tapText(tester, 'Back to setup');

    await _tapText(tester, 'Review rules');

    expect(find.text('Speaker A total: 10:00'), findsOneWidget);
    expect(find.text('Speaker B total: 10:00'), findsOneWidget);
    expect(find.text('Turn limit: 1:30'), findsOneWidget);
    expect(find.text('Alerts: Screen + Sound + Vibration'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('saved settings start directly on the face timer', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());
    await store.saveSessionConfig(_config());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    expect(find.text('Session Settings'), findsNothing);
    expect(find.byKey(const ValueKey('face-timer-top-zone')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('face-timer-bottom-zone')),
      findsOneWidget,
    );
    expect(find.text('A is speaking'), findsOneWidget);

    await _tapText(tester, 'End session');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('accepted setup is saved for the next app launch', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();

    await tester.enterText(find.byType(CupertinoTextField).at(0), 'A');
    await tester.enterText(find.byType(CupertinoTextField).at(1), 'B');
    await _tapText(tester, 'Review rules');
    await _tapText(tester, 'A agrees');
    await _tapText(tester, 'B agrees');
    await _tapText(tester, 'Start Timer', settle: false);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('face-timer-bottom-zone')),
      findsOneWidget,
    );
    expect(find.text('A is speaking'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    expect(find.text('Session Settings'), findsNothing);
    expect(find.text('A is speaking'), findsOneWidget);

    await _tapText(tester, 'End session');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('save failure still starts the accepted session', (tester) async {
    final store = _FailingAppSettingsStore(failSave: true);

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();

    await tester.enterText(find.byType(CupertinoTextField).at(0), 'A');
    await tester.enterText(find.byType(CupertinoTextField).at(1), 'B');
    await _tapText(tester, 'Review rules');
    await _tapText(tester, 'A agrees');
    await _tapText(tester, 'B agrees');
    await _tapText(tester, 'Start Timer', settle: false);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('face-timer-bottom-zone')),
      findsOneWidget,
    );
    expect(find.text('A is speaking'), findsOneWidget);

    await _tapText(tester, 'End session');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

final class _FailingAppSettingsStore implements AppSettingsStore {
  final bool failLoad;
  final bool failSave;

  const _FailingAppSettingsStore({
    this.failLoad = false,
    this.failSave = false,
  });

  @override
  Future<SessionConfig?> loadSessionConfig() async {
    if (failLoad) {
      throw StateError('load failed');
    }
    return null;
  }

  @override
  Future<void> saveSessionConfig(SessionConfig config) async {
    if (failSave) {
      throw StateError('save failed');
    }
  }

  @override
  Future<void> clear() async {}
}

Future<void> _tapText(
  WidgetTester tester,
  String text, {
  bool settle = true,
}) async {
  final textFinder = find.text(text);
  if (textFinder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      textFinder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final finder = textFinder.last;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

SessionConfig _config() {
  return const SessionConfig(
    participantA: ParticipantConfig(
      id: 'a',
      name: 'A',
      totalAllocatedSeconds: 300,
    ),
    participantB: ParticipantConfig(
      id: 'b',
      name: 'B',
      totalAllocatedSeconds: 300,
    ),
    turnLimitSeconds: 60,
    firstSpeakerId: 'a',
    overtimeConfig: OvertimeConfig(),
    penaltyConfig: PenaltyConfig(),
    alertConfig: AlertConfig(),
  );
}
