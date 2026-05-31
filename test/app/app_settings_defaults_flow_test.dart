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

    expect(find.text('대화 규칙'), findsOneWidget);
    expect(find.text('참가자'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings load failure falls back to setup', (tester) async {
    final store = _FailingAppSettingsStore(failLoad: true);

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();

    expect(find.text('대화 규칙'), findsOneWidget);
    expect(find.text('참가자'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('app settings defaults are applied to the next session setup', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();

    await _tapText(tester, '앱 설정');
    expect(find.text('앱 설정'), findsOneWidget);

    await _tapText(tester, '각자 10분');
    await _tapText(tester, '턴 1분 30초');
    await _tapText(tester, '소리');
    await _tapText(tester, '설정 저장');

    expect(find.text('다음 대화에 사용할 설정을 저장했어요.'), findsOneWidget);
    await _tapText(tester, '대화 규칙으로');

    await _tapText(tester, '규칙 확인');

    expect(find.text('말하는 사람 A 전체 시간: 10:00'), findsOneWidget);
    expect(find.text('말하는 사람 B 전체 시간: 10:00'), findsOneWidget);
    expect(find.text('턴 제한: 1:30'), findsOneWidget);
    expect(find.text('알림: 화면 + 소리 + 진동'), findsOneWidget);

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

    expect(find.text('대화 규칙'), findsNothing);
    expect(find.byKey(const ValueKey('face-timer-top-zone')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('face-timer-bottom-zone')),
      findsOneWidget,
    );
    expect(find.text('A님 차례'), findsOneWidget);

    await _tapText(tester, '오늘은 여기까지');
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
    await _tapText(tester, '규칙 확인');
    await _tapText(tester, 'A 동의');
    await _tapText(tester, 'B 동의');
    await _tapText(tester, '타이머 시작', settle: false);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('face-timer-bottom-zone')),
      findsOneWidget,
    );
    expect(find.text('A님 차례'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    expect(find.text('대화 규칙'), findsNothing);
    expect(find.text('A님 차례'), findsOneWidget);

    await _tapText(tester, '오늘은 여기까지');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('save failure still starts the accepted session', (tester) async {
    final store = _FailingAppSettingsStore(failSave: true);

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();

    await tester.enterText(find.byType(CupertinoTextField).at(0), 'A');
    await tester.enterText(find.byType(CupertinoTextField).at(1), 'B');
    await _tapText(tester, '규칙 확인');
    await _tapText(tester, 'A 동의');
    await _tapText(tester, 'B 동의');
    await _tapText(tester, '타이머 시작', settle: false);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('face-timer-bottom-zone')),
      findsOneWidget,
    );
    expect(find.text('A님 차례'), findsOneWidget);

    await _tapText(tester, '오늘은 여기까지');
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
