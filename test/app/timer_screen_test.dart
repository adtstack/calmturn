import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('timer screen uses horizontal v4 zones as large touch targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));
    expect(leftZone, findsOneWidget);
    expect(rightZone, findsOneWidget);
    expect(tester.getSize(leftZone).width, greaterThan(300));
    expect(tester.getSize(rightZone).width, greaterThan(300));
    expect(tester.getSize(leftZone).height, greaterThan(320));
    expect(find.text('차례 넘기기'), findsNothing);
    expect(find.text('일시정지'), findsOneWidget);
    expect(find.text('종료'), findsOneWidget);

    await tester.tap(leftZone);
    await tester.pump();

    expect(find.bySemanticsLabel(RegExp('B.*말하는 중')), findsOneWidget);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('active speaker remaining time pulls the boundary inward', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));
    final initialLeftWidth = tester.getSize(leftZone).width;
    final initialRightWidth = tester.getSize(rightZone).width;
    expect(initialLeftWidth, closeTo(initialRightWidth, 1));

    await tester.pump(const Duration(seconds: 60));
    await tester.pump();

    expect(tester.getSize(leftZone).width, lessThan(initialLeftWidth));
    expect(tester.getSize(rightZone).width, greaterThan(initialRightWidth));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pause resumes in place and finish requires confirmation', (
    tester,
  ) async {
    await _pumpTimer(tester, _config());

    await _tapText(tester, '일시정지');
    expect(find.text('재개'), findsOneWidget);
    expect(find.text('잠깐 멈춤'), findsWidgets);

    await _tapText(tester, '재개');
    expect(find.text('일시정지'), findsOneWidget);

    await _tapText(tester, '종료');
    expect(find.text('종료할까요?'), findsOneWidget);
    await _tapText(tester, '취소');
    expect(find.text('종료할까요?'), findsNothing);

    await _finishThroughDialog(tester);
    expect(find.text('대화가 끝났어요'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('penalty marks stay hidden while overtime remains visible', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(penaltyConfig: const PenaltyConfig(thresholdSeconds: 5)),
    );

    await tester.pump(const Duration(seconds: 65));
    await tester.pump();

    expect(find.text('오버타임 +0:05'), findsOneWidget);
    expect(find.textContaining('주의 표시'), findsNothing);
    expect(find.textContaining('패널티'), findsNothing);
    expect(tester.takeException(), isNull);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pumpTimer(WidgetTester tester, SessionConfig config) async {
  await tester.pumpWidget(
    CupertinoApp(
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF111111),
        scaffoldBackgroundColor: Color(0xFFF7F7F4),
      ),
      home: TimerHomePage(config: config),
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
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

SessionConfig _config({PenaltyConfig penaltyConfig = const PenaltyConfig()}) {
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
    penaltyConfig: penaltyConfig,
    alertConfig: const AlertConfig(),
  );
}
