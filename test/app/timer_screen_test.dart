import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
    expect(find.text('일시정지'), findsNothing);
    expect(find.text('종료'), findsNothing);
    expect(find.byKey(const ValueKey('pause-session-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('finish-session-button')), findsOneWidget);

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

  testWidgets('active speaker zone disappears when total time reaches zero', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config(aTotalSeconds: 1, bTotalSeconds: 300));

    expect(find.byKey(const ValueKey('clock-left-zone')), findsOneWidget);
    expect(find.byKey(const ValueKey('clock-right-zone')), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byKey(const ValueKey('clock-left-zone')), findsNothing);
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));
    expect(rightZone, findsOneWidget);
    expect(tester.getSize(rightZone).width, greaterThan(950));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('timer keeps the display awake and landscape while active', (
    tester,
  ) async {
    final screenAwakeCalls = <bool>[];
    final platformCalls = <MethodCall>[];
    const screenAwakeChannel = MethodChannel('calmturn/screen_awake');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      screenAwakeChannel,
      (call) async {
        if (call.method == 'setKeepScreenOn') {
          final arguments = Map<Object?, Object?>.from(call.arguments as Map);
          screenAwakeCalls.add(arguments['enabled']! as bool);
        }
        return null;
      },
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        screenAwakeChannel,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await _pumpTimer(tester, _config());

    expect(screenAwakeCalls, contains(true));
    expect(
      platformCalls.where(
        (call) => call.method == 'SystemChrome.setPreferredOrientations',
      ),
      isNotEmpty,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(screenAwakeCalls.last, isFalse);
  });

  testWidgets('pause resumes in place and finish requires confirmation', (
    tester,
  ) async {
    await _pumpTimer(tester, _config());

    await tester.tap(find.byKey(const ValueKey('pause-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('resume-session-button')), findsOneWidget);
    expect(find.text('잠깐 멈춤'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('resume-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pause-session-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('finish-session-button')));
    await tester.pumpAndSettle();
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
  await tester.tap(find.byKey(const ValueKey('finish-session-button')));
  await tester.pumpAndSettle();
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

SessionConfig _config({
  int aTotalSeconds = 300,
  int bTotalSeconds = 300,
  PenaltyConfig penaltyConfig = const PenaltyConfig(),
}) {
  return SessionConfig(
    participantA: ParticipantConfig(
      id: 'a',
      name: 'A',
      totalAllocatedSeconds: aTotalSeconds,
    ),
    participantB: ParticipantConfig(
      id: 'b',
      name: 'B',
      totalAllocatedSeconds: bTotalSeconds,
    ),
    turnLimitSeconds: 60,
    firstSpeakerId: 'a',
    overtimeConfig: const OvertimeConfig(),
    penaltyConfig: penaltyConfig,
    alertConfig: const AlertConfig(),
  );
}
