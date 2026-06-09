import 'package:calmturn/features/settings/app_settings.dart';
import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first launch without saved settings shows v4 setup', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    expect(find.text('시계'), findsOneWidget);
    expect(find.text('참가자'), findsOneWidget);
    expect(find.byKey(const ValueKey('clock-left-zone')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings load failure falls back to setup', (tester) async {
    final store = _FailingAppSettingsStore(failLoad: true);

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    expect(find.text('시계'), findsOneWidget);
    expect(find.text('참가자'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('saved settings prefill setup instead of auto-starting timer', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());
    await store.saveSessionConfig(_config());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    expect(find.text('시계'), findsOneWidget);
    expect(find.byKey(const ValueKey('clock-left-zone')), findsNothing);
    expect(_textFieldValue(tester, 0), 'A');
    expect(_textFieldValue(tester, 1), 'B');

    await _tapText(tester, '시작');

    expect(find.byKey(const ValueKey('clock-left-zone')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('B.*말하는 중')), findsOneWidget);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('advanced settings auto-save valid defaults on back', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('advanced-settings-button')));
    await tester.pumpAndSettle();
    await _tapText(tester, '30분');
    await _tapText(tester, '5분');
    await _tapText(tester, '시계로');

    await _tapText(tester, '시작');

    expect(find.text('30:00'), findsWidgets);
    expect(find.text('5:00'), findsOneWidget);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

final class _FailingAppSettingsStore implements AppSettingsStore {
  final bool failLoad;

  const _FailingAppSettingsStore({this.failLoad = false});

  @override
  Future<AppSettingsDraft> loadSettings() async {
    if (failLoad) {
      throw StateError('load failed');
    }
    return AppSettingsDraft.defaults();
  }

  @override
  Future<void> saveSettings(AppSettingsDraft settings) async {}

  @override
  Future<SessionConfig?> loadSessionConfig() async {
    if (failLoad) {
      throw StateError('load failed');
    }
    return null;
  }

  @override
  Future<void> saveSessionConfig(SessionConfig config) async {}

  @override
  Future<void> clear() async {}
}

Future<void> _finishThroughDialog(WidgetTester tester) async {
  await _showControls(tester);
  await tester.tap(find.byKey(const ValueKey('finish-session-button')));
  await tester.pumpAndSettle();
  expect(find.text('종료할까요?'), findsOneWidget);
  await _tapText(tester, '종료');
}

Future<void> _showControls(WidgetTester tester) async {
  if (find
      .byKey(const ValueKey('finish-session-button'))
      .evaluate()
      .isNotEmpty) {
    return;
  }
  await tester.tap(find.byKey(const ValueKey('clock-controls-reveal-zone')));
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final textFinder = find.text(text);
  if (textFinder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      textFinder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final finder = textFinder.last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _textFieldValue(WidgetTester tester, int index) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: find.byType(CupertinoTextField).at(index),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}

SessionConfig _config() {
  return const SessionConfig(
    participantA: ParticipantConfig(
      id: 'a',
      name: 'A',
      totalAllocatedSeconds: 1800,
    ),
    participantB: ParticipantConfig(
      id: 'b',
      name: 'B',
      totalAllocatedSeconds: 1800,
    ),
    turnLimitSeconds: 300,
    firstSpeakerId: 'b',
    overtimeConfig: OvertimeConfig(),
    penaltyConfig: PenaltyConfig(),
    alertConfig: AlertConfig(),
  );
}
