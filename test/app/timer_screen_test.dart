import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('timer screen starts ready for a live conversation', (
    tester,
  ) async {
    await _pumpTimer(tester, _config());

    expect(find.text('지금 말하는 중'), findsOneWidget);
    expect(find.text('A님 차례'), findsOneWidget);
    expect(find.text('이번 차례'), findsOneWidget);
    expect(find.text('전체 남은 시간'), findsWidgets);
    expect(find.text('사용한 시간'), findsNothing);
    expect(find.text('차례 넘기기'), findsOneWidget);
    expect(find.text('잠깐 쉬기'), findsOneWidget);
    expect(find.text('오늘은 여기까지'), findsOneWidget);

    await _tapText(tester, '오늘은 여기까지');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pass turn, break, resume, and end controls update the session', (
    tester,
  ) async {
    await _pumpTimer(tester, _config());

    await _tapText(tester, '차례 넘기기');
    expect(find.text('B님 차례'), findsOneWidget);

    await _tapText(tester, '잠깐 쉬기');
    expect(find.text('잠깐 쉬는 중'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('5:00'), findsWidgets);

    await _tapText(tester, '이어서 하기');
    expect(find.text('B님 차례'), findsOneWidget);

    await _tapText(tester, '오늘은 여기까지');
    expect(find.text('대화가 끝났어요'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('face timer uses mirrored zones as large touch targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final topZone = find.byKey(const ValueKey('face-timer-top-zone'));
    final bottomZone = find.byKey(const ValueKey('face-timer-bottom-zone'));
    expect(topZone, findsOneWidget);
    expect(bottomZone, findsOneWidget);
    expect(tester.getSize(topZone).height, greaterThan(300));
    expect(tester.getSize(bottomZone).height, greaterThan(300));

    final topRotation = tester.widget<Transform>(
      find.byKey(const ValueKey('face-timer-top-rotation')),
    );
    expect(topRotation.transform.storage[0], closeTo(-1, 0.001));
    expect(topRotation.transform.storage[5], closeTo(-1, 0.001));

    await tester.tap(find.text('A님 차례'));
    await tester.pump();

    expect(find.text('B님 차례'), findsOneWidget);

    await _tapText(tester, '오늘은 여기까지');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('center controls keep labels readable on colored buttons', (
    tester,
  ) async {
    await _pumpTimer(tester, _config());

    expect(
      tester.widget<Text>(find.text('차례 넘기기')).style?.color,
      CupertinoColors.white,
    );
    expect(
      tester.widget<Text>(find.text('잠깐 쉬기')).style?.color,
      CupertinoColors.white,
    );
    expect(
      tester.widget<Text>(find.text('오늘은 여기까지')).style?.color,
      CupertinoColors.white,
    );

    await _tapText(tester, '오늘은 여기까지');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('warning feedback uses visual alerts and screen fallback', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(
        alertConfig: const AlertConfig(
          warningBeforeSeconds: 10,
          visualEnabled: true,
          soundEnabled: false,
          hapticEnabled: false,
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 50));
    await tester.pump();

    expect(find.text('10초 남았습니다.'), findsOneWidget);

    await _tapText(tester, '오늘은 여기까지');
    await _pumpTimer(
      tester,
      _config(
        alertConfig: const AlertConfig(
          warningBeforeSeconds: 10,
          visualEnabled: false,
          soundEnabled: true,
          hapticEnabled: false,
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 50));
    await tester.pump();

    expect(find.text('10초 남았습니다.'), findsOneWidget);

    await _tapText(tester, '오늘은 여기까지');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('visible overtime shows counters and penalty marks', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(penaltyConfig: const PenaltyConfig(thresholdSeconds: 5)),
    );

    await tester.pump(const Duration(seconds: 65));
    await tester.pump();

    expect(find.text('+0:05'), findsOneWidget);
    expect(find.text('오버타임 +0:05'), findsOneWidget);
    expect(find.text('오버타임 합계'), findsNothing);
    expect(find.textContaining('주의 표시 1회 기록'), findsOneWidget);

    await _tapText(tester, '오늘은 여기까지');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('active timer semantics expose overtime and penalty state', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(penaltyConfig: const PenaltyConfig(thresholdSeconds: 5)),
    );

    await tester.pump(const Duration(seconds: 65));
    await tester.pump();

    expect(
      find.bySemanticsLabel(RegExp('A 타이머 영역.*말하는 중.*오버타임 0:05.*주의 표시 1회')),
      findsOneWidget,
    );

    await _tapText(tester, '오늘은 여기까지');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('small screen with large text keeps core timer state visible', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(
      tester,
      _config(penaltyConfig: const PenaltyConfig(thresholdSeconds: 5)),
      textScaleFactor: 2,
    );
    await tester.pump(const Duration(seconds: 65));
    await tester.pump();

    expect(find.text('A님 차례'), findsOneWidget);
    expect(find.text('+0:05'), findsOneWidget);
    expect(find.text('오버타임 +0:05'), findsOneWidget);
    expect(find.textContaining('주의 표시 1회 기록'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tapText(tester, '오늘은 여기까지');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hidden overtime setting suppresses explicit overtime counters', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(
        overtimeConfig: const OvertimeConfig(showOvertime: false),
        penaltyConfig: const PenaltyConfig(thresholdSeconds: 5),
      ),
    );

    await tester.pump(const Duration(seconds: 65));
    await tester.pump();

    expect(find.text('차례 시간이 끝났어요'), findsOneWidget);
    expect(find.text('+0:05'), findsNothing);
    expect(find.text('오버타임 +0:05'), findsNothing);
    expect(find.text('오버타임 합계'), findsNothing);
    expect(find.textContaining('오버타임'), findsNothing);

    await _tapText(tester, '오늘은 여기까지');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('auto pause directs the user to pass turn instead of resume', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(
        overtimeConfig: const OvertimeConfig(
          enabled: false,
          showOvertime: false,
          behavior: TurnLimitBehavior.autoPause,
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 60));
    await tester.pump();

    expect(find.text('차례가 끝났어요'), findsOneWidget);
    expect(find.text('차례를 넘기면 이어집니다.'), findsOneWidget);
    expect(find.text('차례 끝'), findsOneWidget);
    expect(find.text('이어서 하기'), findsNothing);

    await _tapText(tester, '차례 넘기기');
    expect(find.text('B님 차례'), findsOneWidget);

    await _tapText(tester, '오늘은 여기까지');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pumpTimer(
  WidgetTester tester,
  SessionConfig config, {
  double textScaleFactor = 1,
}) async {
  await tester.pumpWidget(
    CupertinoApp(
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF2D6A64),
        scaffoldBackgroundColor: Color(0xFFF6F4EF),
      ),
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
            child: TimerHomePage(config: config),
          );
        },
      ),
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
  await tester.tap(finder);
  await tester.pump();
}

SessionConfig _config({
  AlertConfig alertConfig = const AlertConfig(),
  OvertimeConfig overtimeConfig = const OvertimeConfig(),
  PenaltyConfig penaltyConfig = const PenaltyConfig(),
}) {
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
    overtimeConfig: overtimeConfig,
    penaltyConfig: penaltyConfig,
    alertConfig: alertConfig,
  );
}
