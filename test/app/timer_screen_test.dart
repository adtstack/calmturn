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

    await tester.tap(find.bySemanticsLabel(RegExp('A.*말하는 중')));
    await tester.pump();

    expect(find.bySemanticsLabel(RegExp('B.*말하는 중')), findsOneWidget);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('fullscreen clock fills the surface beyond safe area padding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    tester.view.padding = const FakeViewPadding(
      left: 34,
      top: 18,
      right: 26,
      bottom: 12,
    );
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetPadding();
    });

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    expect(tester.getTopLeft(leftZone).dy, 0);
    expect(tester.getSize(leftZone).height, closeTo(390, 1));

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

    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 800));

    expect(tester.getSize(leftZone).width, closeTo(250, 2));
    expect(tester.getSize(rightZone).width, closeTo(750, 2));
    expect(tester.getSize(leftZone).width, lessThan(initialLeftWidth));
    expect(tester.getSize(rightZone).width, greaterThan(initialRightWidth));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('clock boundary follows current turn screen progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    final initialLeftWidth = tester.getSize(leftZone).width;

    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 200));

    final easingLeftWidth = tester.getSize(leftZone).width;

    await tester.pump(const Duration(milliseconds: 800));

    final settledLeftWidth = tester.getSize(leftZone).width;
    expect(easingLeftWidth, lessThan(initialLeftWidth));
    expect(easingLeftWidth, greaterThan(settledLeftWidth + 40));
    expect(settledLeftWidth, closeTo(250, 2));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('clock background moves while the readout stays anchored', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    final leftReadout = find.bySemanticsLabel(RegExp('A.*말하는 중'));
    final initialZoneWidth = tester.getSize(leftZone).width;
    final initialReadoutWidth = tester.getSize(leftReadout).width;

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 800));

    final tickedZoneWidth = tester.getSize(leftZone).width;
    final tickedReadoutWidth = tester.getSize(leftReadout).width;
    expect(initialZoneWidth - tickedZoneWidth, greaterThan(7));
    expect(tickedReadoutWidth, closeTo(initialReadoutWidth, 1));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('next speaker starts the background boundary from center', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));

    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.getSize(leftZone).width, closeTo(250, 2));

    await tester.tap(find.bySemanticsLabel(RegExp('A.*말하는 중')));
    await tester.pump();

    expect(find.bySemanticsLabel(RegExp('B.*말하는 중')), findsOneWidget);
    expect(tester.getSize(leftZone).width, closeTo(500, 1));

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 800));

    expect(tester.getSize(leftZone).width, greaterThan(507));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('active speaker zone shrinks away when total time reaches zero', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config(aTotalSeconds: 1, bTotalSeconds: 300));

    expect(find.byKey(const ValueKey('clock-left-zone')), findsOneWidget);
    expect(find.byKey(const ValueKey('clock-right-zone')), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byKey(const ValueKey('clock-left-zone')), findsNothing);
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));
    expect(rightZone, findsOneWidget);
    expect(tester.getSize(rightZone).width, greaterThan(950));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('feedback banner overlays without moving the clock readout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    await tester.pump(const Duration(seconds: 49));
    await tester.pump(const Duration(milliseconds: 800));

    final nameFinder = find.text('A');
    final nameTopBeforeWarning = tester.getTopLeft(nameFinder).dy;
    expect(find.text('10초 남았습니다.'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('10초 남았습니다.'), findsOneWidget);
    expect(tester.getTopLeft(nameFinder).dy, closeTo(nameTopBeforeWarning, 1));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('clock readouts do not scale down with shrinking zones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    expect(
      find.descendant(
        of: find.byType(TimerHomePage),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 48));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('0:12'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TimerHomePage),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('turn danger flash starts at twenty percent and intensifies', (
    tester,
  ) async {
    await _pumpTimer(tester, _config());

    await tester.pump(const Duration(seconds: 47));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('turn-danger-flash-overlay')),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final weakOpacity = _dangerFlashOpacity(tester);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    final strongOpacity = _dangerFlashOpacity(tester);

    expect(weakOpacity, greaterThan(0));
    expect(strongOpacity, greaterThan(weakOpacity));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('turn danger flash can be disabled independently', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(alertConfig: const AlertConfig(turnDangerFlashEnabled: false)),
    );

    await tester.pump(const Duration(seconds: 54));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('turn-danger-flash-overlay')),
      findsNothing,
    );

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('timer keeps the display awake and landscape while active', (
    tester,
  ) async {
    final screenAwakeCalls = <MethodCall>[];
    final platformCalls = <MethodCall>[];
    const screenAwakeChannel = MethodChannel('calmturn/screen_awake');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      screenAwakeChannel,
      (call) async {
        screenAwakeCalls.add(call);
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

    expect(_enabledCalls(screenAwakeCalls, 'setSensorLandscape'), [true]);
    expect(_enabledCalls(screenAwakeCalls, 'setKeepScreenOn'), [true]);
    expect(_orientationArguments(platformCalls).first, [
      'DeviceOrientation.landscapeLeft',
    ]);
    expect(
      _systemUiModeArguments(platformCalls).first,
      'SystemUiMode.immersiveSticky',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(_enabledCalls(screenAwakeCalls, 'setSensorLandscape'), [
      true,
      false,
    ]);
    expect(_enabledCalls(screenAwakeCalls, 'setKeepScreenOn'), [true, false]);
    expect(_orientationArguments(platformCalls).last, isEmpty);
    expect(
      _systemUiModeArguments(platformCalls).last,
      'SystemUiMode.edgeToEdge',
    );
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
    expect(find.text('대화를 마쳤어요.'), findsOneWidget);

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

List<List<Object?>> _orientationArguments(List<MethodCall> calls) {
  return calls
      .where((call) => call.method == 'SystemChrome.setPreferredOrientations')
      .map((call) => List<Object?>.from(call.arguments as List))
      .toList(growable: false);
}

List<Object?> _systemUiModeArguments(List<MethodCall> calls) {
  return calls
      .where((call) => call.method == 'SystemChrome.setEnabledSystemUIMode')
      .map((call) => call.arguments)
      .toList(growable: false);
}

List<bool> _enabledCalls(List<MethodCall> calls, String method) {
  return calls
      .where((call) => call.method == method)
      .map((call) {
        final arguments = Map<Object?, Object?>.from(call.arguments as Map);
        return arguments['enabled']! as bool;
      })
      .toList(growable: false);
}

double _dangerFlashOpacity(WidgetTester tester) {
  final overlay = tester.widget<Opacity>(
    find.byKey(const ValueKey('turn-danger-flash-overlay')),
  );
  return overlay.opacity;
}

SessionConfig _config({
  int aTotalSeconds = 300,
  int bTotalSeconds = 300,
  PenaltyConfig penaltyConfig = const PenaltyConfig(),
  AlertConfig alertConfig = const AlertConfig(),
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
    alertConfig: alertConfig,
  );
}
