import 'package:calmturn/features/history/session_record.dart';
import 'package:calmturn/features/history/session_record_store.dart';
import 'package:calmturn/features/history/history_screen.dart';
import 'package:calmturn/features/history/wrap_up_page.dart';
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

    expect(find.text('대화를 마쳤어요.'), findsOneWidget);
    expect(find.text('오늘 나눈 마음을 정리해요.'), findsOneWidget);
    expect(find.text('모든 대화는 관계가 나아지는 연습이 될 수 있어요.'), findsOneWidget);
    expect(find.text('흰칸'), findsOneWidget);
    expect(find.text('검은칸'), findsOneWidget);
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
    expect(records.single.participantResults.first.name, '');
    expect(records.single.participantResults.last.name, '');
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
    await _ensureTextVisible(tester, '흰칸');
    expect(find.text('검은칸'), findsOneWidget);
    await _ensureTextVisible(tester, '사용한 시간');
    expect(find.text('오버타임 합계'), findsNothing);
    expect(find.text('배정 시간'), findsNothing);
    expect(find.text('남은 시간'), findsNothing);
    expect(find.text('차례 수'), findsNothing);

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

  testWidgets('history detail asks before deleting a record', (tester) async {
    final store = JsonSessionRecordStore(
      storage: InMemorySessionRecordStorage(),
    );
    await store.save(
      _record('delete-me', DateTime.now(), ConversationOutcome.resolved),
    );

    await tester.pumpWidget(
      CupertinoApp(home: HistoryScreen(recordStore: store)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('history-day-${_todayIsoDate()}')));
    await tester.pumpAndSettle();
    await _tapText(tester, '기록 delete-me');

    await _tapText(tester, '기록 삭제');
    expect(find.text('기록을 삭제할까요?'), findsOneWidget);
    expect((await store.load()).single.id, 'delete-me');

    await _tapText(tester, '취소');
    expect(find.text('기록을 삭제할까요?'), findsNothing);
    expect((await store.load()).single.id, 'delete-me');

    await _tapText(tester, '기록 삭제');
    await _tapText(tester, '삭제');

    expect(await store.load(), isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('advanced settings asks before deleting all records', (
    tester,
  ) async {
    final settingsStore = JsonAppSettingsStore(
      storage: InMemoryAppSettingsStorage(),
    );
    final recordStore = JsonSessionRecordStore(
      storage: InMemorySessionRecordStorage(),
    );
    await recordStore.save(
      _record('first', DateTime(2026, 6, 6, 9), ConversationOutcome.resolved),
    );

    await _pumpApp(tester, settingsStore, recordStore);
    await tester.tap(find.byKey(const ValueKey('advanced-settings-button')));
    await tester.pumpAndSettle();

    await _tapText(tester, '모든 기록 삭제');
    expect(find.text('모든 기록을 삭제할까요?'), findsOneWidget);
    expect((await recordStore.load()).single.id, 'first');

    await _tapText(tester, '취소');
    expect(find.text('모든 기록을 삭제할까요?'), findsNothing);
    expect((await recordStore.load()).single.id, 'first');

    await _tapText(tester, '모든 기록 삭제');
    await _tapText(tester, '삭제');

    expect(await recordStore.load(), isEmpty);
    expect(find.text('모든 기록을 삭제했어요.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('wrap-up keeps records simple and commits tags from words', (
    tester,
  ) async {
    final store = JsonSessionRecordStore(
      storage: InMemorySessionRecordStorage(),
    );
    await store.save(
      _record(
        'previous',
        DateTime(2026, 6, 6, 8),
        ConversationOutcome.resolved,
        tagsText: '#예산 #말끊김',
      ),
    );
    var startedAnotherSession = false;

    await tester.pumpWidget(
      CupertinoApp(
        home: WrapUpPage(
          draftRecord: _record(
            'draft',
            DateTime(2026, 6, 6, 9),
            ConversationOutcome.resolved,
            tagsText: null,
          ),
          recordStore: store,
          onStartAnotherSession: () {
            startedAnotherSession = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('종료'), findsNothing);
    expect(find.text('알림'), findsNothing);
    expect(find.text('오버타임 합계'), findsNothing);
    expect(find.text('배정 시간'), findsNothing);
    expect(find.text('남은 시간'), findsNothing);
    expect(find.text('차례 수'), findsNothing);
    expect(find.text('사용한 시간'), findsNWidgets(2));

    final previousTag = find.byKey(const ValueKey('recent-tag-#예산'));
    await _ensureFinderVisible(tester, previousTag);
    await tester.tap(previousTag);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('selected-tag-#예산')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('tags-text-field')),
      '감정 ',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('selected-tag-#감정')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('tags-text-field')),
      '생활비',
    );
    await _tapText(tester, '기록 저장');

    final records = await store.load();
    final savedDraft = records.singleWhere((record) => record.id == 'draft');
    expect(savedDraft.tagsText, '#예산 #감정 #생활비');
    expect(startedAnotherSession, isTrue);

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
  await _ensureFinderVisible(tester, textFinder);
}

Future<void> _ensureFinderVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder.last);
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
    turnLimitSeconds: 30,
    firstSpeakerId: 'a',
    overtimeConfig: OvertimeConfig(),
    penaltyConfig: PenaltyConfig(),
    alertConfig: AlertConfig(),
  );
}

SessionRecord _record(
  String id,
  DateTime startedAt,
  ConversationOutcome outcome, {
  String? tagsText = '#test',
}) {
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
    tagsText: tagsText,
    outcome: outcome,
  );
}
