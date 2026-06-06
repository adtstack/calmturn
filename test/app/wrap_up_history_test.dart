import 'package:calmturn/features/history/session_record.dart';
import 'package:calmturn/features/history/session_record_store.dart';
import 'package:calmturn/features/history/history_screen.dart';
import 'package:calmturn/features/timer/domain/timer_engine.dart';
import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wrap-up saves outcome fields and history drills down by date', (
    tester,
  ) async {
    final recordStore = JsonSessionRecordStore(
      storage: InMemorySessionRecordStorage(),
    );
    await _pumpTimer(tester, _config(), recordStore);

    await tester.pump(const Duration(seconds: 42));
    await _finishThroughDialog(tester);

    expect(find.text('대화가 끝났어요'), findsOneWidget);
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

    await _tapText(tester, '기록 보기');
    expect(find.text('기록 달력'), findsWidgets);
    expect(find.text('X'), findsOneWidget);

    await _tapText(tester, _todayLabel());
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

    expect(find.text('X O X'), findsOneWidget);
    expect(find.text('O X O'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('finish without saving removes an auto-saved draft record', (
    tester,
  ) async {
    final recordStore = JsonSessionRecordStore(
      storage: InMemorySessionRecordStorage(),
    );
    await _pumpTimer(tester, _config(), recordStore, autoSaveRecords: true);

    await tester.pump(const Duration(seconds: 12));
    await _finishThroughDialog(tester);

    expect((await recordStore.load()).single.outcome, isNull);

    await _tapText(tester, '저장하지 않고 마치기');

    expect(await recordStore.load(), isEmpty);
    expect(find.text('기록하지 않고 마쳤어요.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pumpTimer(
  WidgetTester tester,
  SessionConfig config,
  SessionRecordStore recordStore, {
  bool autoSaveRecords = false,
}) async {
  await tester.pumpWidget(
    CupertinoApp(
      home: TimerHomePage(
        config: config,
        recordStore: recordStore,
        autoSaveRecords: autoSaveRecords,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _finishThroughDialog(WidgetTester tester) async {
  await _tapText(tester, '종료');
  expect(find.text('종료할까요?'), findsOneWidget);
  await _tapText(tester, '종료');
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

String _todayLabel() {
  final now = DateTime.now();
  return '${now.month}/${now.day}';
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
