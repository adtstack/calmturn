import 'package:calmturn/features/history/session_record_store.dart';
import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wrap-up shows neutral conversation record and saved history', (
    tester,
  ) async {
    final store = JsonSessionRecordStore(
      storage: InMemorySessionRecordStorage(),
    );
    await _pumpTimer(tester, _config(), store);

    await tester.pump(const Duration(seconds: 65));
    await tester.pump();
    await _tapText(tester, 'Take break');
    await _tapText(tester, 'Resume');
    await _tapText(tester, 'End session');

    expect(find.text('오늘의 대화를 정리해요'), findsOneWidget);
    expect(find.text('오늘의 대화 기록'), findsOneWidget);
    expect(find.text('승패가 아니라, 다음 대화를 위한 기록입니다.'), findsOneWidget);
    expect(find.text('Ended by user'), findsOneWidget);
    expect(find.text('Breaks'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Overtime total'), findsWidgets);
    expect(find.text('Marks'), findsWidgets);
    expect(find.textContaining('winner'), findsNothing);
    expect(find.textContaining('loser'), findsNothing);

    await tester.scrollUntilVisible(find.text('Agreed together'), 220);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(CupertinoTextField).at(0),
      'Use shorter examples.',
    );
    await tester.enterText(
      find.byType(CupertinoTextField).at(1),
      'Budget follow-up.',
    );
    await _tapText(tester, 'Save record');

    expect(find.text('Record saved on this device.'), findsOneWidget);
    expect(find.text('Saved records'), findsOneWidget);
    expect(find.text('A / B'), findsOneWidget);
    expect(find.text('Use shorter examples.'), findsWidgets);
    expect(find.text('Budget follow-up.'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Delete record').last,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await _tapText(tester, 'Delete record');
    expect(find.text('No saved records yet.'), findsOneWidget);
    expect(await store.load(), isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pumpTimer(
  WidgetTester tester,
  SessionConfig config,
  SessionRecordStore store,
) async {
  await tester.pumpWidget(
    CupertinoApp(
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF2D6A64),
        scaffoldBackgroundColor: Color(0xFFF6F4EF),
      ),
      home: TimerHomePage(config: config, recordStore: store),
    ),
  );
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 180);
    await tester.pump();
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

SessionConfig _config() {
  return SessionConfig(
    participantA: const ParticipantConfig(
      id: 'a',
      name: 'A',
      totalAllocatedSeconds: 300,
    ),
    participantB: const ParticipantConfig(
      id: 'b',
      name: 'B',
      totalAllocatedSeconds: 300,
    ),
    turnLimitSeconds: 60,
    firstSpeakerId: 'a',
    overtimeConfig: const OvertimeConfig(),
    penaltyConfig: const PenaltyConfig(thresholdSeconds: 5),
    alertConfig: const AlertConfig(),
  );
}
