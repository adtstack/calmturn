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
    await _tapText(tester, '잠깐 쉬기');
    await _tapText(tester, '이어서 하기');
    await _tapText(tester, '오늘은 여기까지');

    expect(find.text('오늘의 대화를 정리해요'), findsOneWidget);
    expect(find.text('승패가 아니라, 다음 대화를 위한 기록입니다.'), findsOneWidget);
    expect(find.text('직접 종료'), findsOneWidget);
    expect(find.text('휴식'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('오버타임 합계'), findsWidgets);
    expect(find.text('주의 표시'), findsWidgets);
    expect(find.textContaining('winner'), findsNothing);
    expect(find.textContaining('loser'), findsNothing);

    expect(find.text('저장된 기록'), findsNothing);

    await tester.scrollUntilVisible(find.text('합의한 것'), 220);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(CupertinoTextField).at(0),
      '예시는 짧게 말하기.',
    );
    await tester.enterText(
      find.byType(CupertinoTextField).at(1),
      '예산 이야기는 다음에 이어가기.',
    );
    await _tapText(tester, '기록 저장');

    expect(find.text('이 기기에 기록을 저장했어요.'), findsOneWidget);
    expect(find.text('저장된 기록'), findsNothing);
    await _tapText(tester, '저장된 기록 보기');
    expect(find.text('저장된 기록'), findsOneWidget);
    expect(find.text('A / B'), findsOneWidget);
    expect(find.text('예시는 짧게 말하기.'), findsWidgets);
    expect(find.text('예산 이야기는 다음에 이어가기.'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('기록 삭제').last,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await _tapText(tester, '기록 삭제');
    expect(find.text('저장된 기록이 아직 없어요.'), findsOneWidget);
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
