import 'package:calmturn/features/history/session_record.dart';
import 'package:calmturn/features/history/session_record_store.dart';
import 'package:calmturn/features/history/history_screen.dart';
import 'package:calmturn/features/settings/app_settings.dart';
import 'package:calmturn/features/timer/domain/timer_engine.dart';
import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wrap-up saves outcome fields and history drills down by date', (
    tester,
  ) async {
    final settingsStore = JsonAppSettingsStore(
      storage: InMemoryAppSettingsStorage(),
    );
    final recordStore = JsonSessionRecordStore(
      storage: InMemorySessionRecordStorage(),
    );

    await _pumpApp(tester, settingsStore, recordStore);
    await _tapText(tester, '시작');

    await tester.pump(const Duration(seconds: 42));
    await _finishThroughDialog(tester);

    expect(find.text('대화가 끝났어요'), findsOneWidget);
    await _ensureTextVisible(tester, '잘 마무리됨');
    expect(find.text('잘 마무리됨'), findsOneWidget);
    expect(find.text('아직 남음'), findsOneWidget);
    expect(find.textContaining('주의 표시'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('summary-text-field')),
      '서로 말이 겹치는 구간을 줄였다.',
    );
    await tester.enterText(
      find.byKey(const ValueKey('tags-text-field')),
      '#말끊김 #예산',
    );
    await _tapText(tester, '아직 남음');
    await _tapText(tester, '기록 저장');

    final records = await recordStore.load();
    expect(records.single.summaryText, '서로 말이 겹치는 구간을 줄였다.');
    expect(records.single.tagsText, '#말끊김 #예산');
    expect(records.single.outcome, ConversationOutcome.unresolved);
    expect(find.text('시계'), findsOneWidget);
    expect(find.byKey(const ValueKey('clock-left-zone')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('history-button')));
    await tester.pumpAndSettle();
    expect(find.text('기록 달력'), findsWidgets);
    expect(find.byKey(const ValueKey('history-calendar-grid')), findsOneWidget);
    expect(find.text('일'), findsOneWidget);
    expect(find.text('토'), findsOneWidget);
    expect(find.text('❌'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('history-day-${_todayIsoDate()}')));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 기록'), findsWidgets);
    expect(find.text('서로 말이 겹치는 구간을 줄였다.'), findsOneWidget);

    await _tapText(tester, '서로 말이 겹치는 구간을 줄였다.');
    expect(find.text('기록 자세히'), findsOneWidget);
    expect(find.text('#말끊김 #예산'), findsOneWidget);
    expect(find.text('아직 남음'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('history calendar shows up to three outcome marks per day', (
    tester,
  ) async {
    final store = JsonSessionRecordStore(
      storage: InMemorySessionRecordStorage(),
    );
    final date = DateTime(2026, 6, 6, 9);
    await store.save(_record('1', date, ConversationOutcome.resolved));
    await store.save(
      _record(
        '2',
        date.add(const Duration(hours: 1)),
        ConversationOutcome.unresolved,
      ),
    );
    await store.save(
      _record(
        '3',
        date.add(const Duration(hours: 2)),
        ConversationOutcome.resolved,
      ),
    );
    await store.save(
      _record(
        '4',
        date.add(const Duration(hours: 3)),
        ConversationOutcome.unresolved,
      ),
    );

    await tester.pumpWidget(
      CupertinoApp(home: HistoryScreen(recordStore: store)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('history-calendar-grid')), findsOneWidget);
    expect(find.text('일'), findsOneWidget);
    expect(find.text('월'), findsOneWidget);
    expect(find.text('토'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('history-day-2026-06-06')),
      findsOneWidget,
    );
    expect(find.text('❌✅❌'), findsOneWidget);
    expect(find.text('✅❌✅'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('finish without saving removes an auto-saved draft record', (
    tester,
  ) async {
    final settingsStore = JsonAppSettingsStore(
      storage: InMemoryAppSettingsStorage(),
    );
    await settingsStore.saveSettings(
      AppSettingsDraft.defaults().copyWith(autoSaveRecords: true),
    );
    final recordStore = JsonSessionRecordStore(
      storage: InMemorySessionRecordStorage(),
    );
    await _pumpApp(tester, settingsStore, recordStore);
    await _tapText(tester, '시작');

    await tester.pump(const Duration(seconds: 12));
    await _finishThroughDialog(tester);

    expect((await recordStore.load()).single.outcome, isNull);

    await _tapText(tester, '저장하지 않고 마치기');

    expect(await recordStore.load(), isEmpty);
    expect(find.text('시계'), findsOneWidget);
    expect(find.text('기록하지 않고 마쳤어요.'), findsNothing);
    expect(find.byKey(const ValueKey('clock-left-zone')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  AppSettingsStore settingsStore,
  SessionRecordStore recordStore,
) async {
  await tester.pumpWidget(
    CalmTurnApp(settingsStore: settingsStore, recordStore: recordStore),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _ensureTextVisible(WidgetTester tester, String text) async {
  final textFinder = find.text(text);
  if (textFinder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      textFinder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(textFinder.last);
  await tester.pumpAndSettle();
}

Future<void> _finishThroughDialog(WidgetTester tester) async {
  await _showControls(tester);
  await tester.tap(find.byKey(const ValueKey('finish-session-button')));
  await tester.pumpAndSettle();
  expect(find.text('종료할까요?'), findsOneWidget);
  await _tapText(tester, '종료');
}

Future<void> _showControls(WidgetTester tester) async {
  final controlsAreVisible =
      find
          .byKey(const ValueKey('pause-session-button'))
          .evaluate()
          .isNotEmpty ||
      find
          .byKey(const ValueKey('resume-session-button'))
          .evaluate()
          .isNotEmpty ||
      find.byKey(const ValueKey('finish-session-button')).evaluate().isNotEmpty;
  if (controlsAreVisible) {
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

String _todayIsoDate() {
  final now = DateTime.now();
  return '${now.year}-${_two(now.month)}-${_two(now.day)}';
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}

SessionConfig _config() {
  return const SessionConfig(
    participantA: ParticipantConfig(
      id: 'a',
      name: '남편',
      totalAllocatedSeconds: 600,
    ),
    participantB: ParticipantConfig(
      id: 'b',
      name: '와이프',
      totalAllocatedSeconds: 600,
    ),
    turnLimitSeconds: 180,
    firstSpeakerId: 'a',
    overtimeConfig: OvertimeConfig(),
    penaltyConfig: PenaltyConfig(),
    alertConfig: AlertConfig(),
  );
}

SessionRecord _record(
  String id,
  DateTime startedAt,
  ConversationOutcome outcome,
) {
  final config = _config();
  return SessionRecord.fromTimerSnapshot(
    id: id,
    config: config,
    snapshot: TimerEngine.start(config).snapshot(),
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 5)),
    endReason: SessionEndReason.endedByUser,
    breakCount: 0,
    summaryText: '기록 $id',
    tagsText: '#test',
    outcome: outcome,
  );
}
